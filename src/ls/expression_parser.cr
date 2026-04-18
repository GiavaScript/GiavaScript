module Ls
  class ExpressionParser
    @source : String
    @index : Int32
    @env : Hash(String, Value)
    @call_function : Proc(String, Array(Value), Value)?

    def initialize(@source : String, @env : Hash(String, Value), @call_function : Proc(String, Array(Value), Value)? = nil)
      @index = 0
    end

    def parse : Value
      value = parse_expression
      skip_whitespace
      raise invalid_rhs_error unless end_of_input?
      value
    end

    private def parse_expression : Value
      left = parse_term

      loop do
        skip_whitespace
        operator = current_char
        break unless operator == '+' || operator == '-'

        advance
        right = parse_term
        left = apply_operator(left, right, operator.not_nil!)
      end

      left
    end

    private def parse_term : Value
      left = parse_power

      loop do
        skip_whitespace
        operator = current_char
        break unless operator == '*' || operator == '/' || operator == '%'

        advance
        right = parse_power
        left = apply_operator(left, right, operator.not_nil!)
      end

      left
    end

    private def parse_power : Value
      left = parse_factor

      skip_whitespace
      if current_char == '^'
        advance
        right = parse_power
        return apply_operator(left, right, '^')
      end

      left
    end

    private def parse_factor : Value
      skip_whitespace
      raise invalid_rhs_error if end_of_input?

      char = current_char
      raise invalid_rhs_error unless char

      case char
      when '('
        advance
        value = parse_expression
        skip_whitespace
        raise invalid_rhs_error unless current_char == ')'
        advance
        value
      when '+'
        advance
        parse_factor
      when '-'
        advance
        value = parse_factor
        negate(value)
      when '$'
        parse_variable
      when '"'
        parse_string
      else
        if identifier_start?(char)
          parse_function_call
        else
          parse_number
        end
      end
    end

    private def parse_function_call : Value
      name_start = @index
      advance
      while identifier_continue?(current_char)
        advance
      end

      function_name = @source[name_start...@index]
      skip_whitespace
      raise invalid_rhs_error unless current_char == '('
      advance

      args = [] of Value
      skip_whitespace

      unless current_char == ')'
        loop do
          args << parse_expression
          skip_whitespace

          if current_char == ','
            advance
            skip_whitespace
            next
          end

          break
        end
      end

      raise invalid_rhs_error unless current_char == ')'
      advance

      unless call_function = @call_function
        raise ExpressionError.new("Error: function '#{function_name}' does not exist")
      end

      call_function.call(function_name, args)
    end

    private def parse_string : String
      parser = StringLiteralParser.new(@source, @index, @env, @call_function)
      value = parser.parse
      @index = parser.index
      value
    end

    private def parse_number : Number
      start = @index
      has_digits_before_dot = false

      while digit?(current_char)
        has_digits_before_dot = true
        advance
      end

      is_float = false
      if current_char == '.'
        is_float = true
        advance

        digits_after_dot = false
        while digit?(current_char)
          digits_after_dot = true
          advance
        end

        unless has_digits_before_dot || digits_after_dot
          raise invalid_rhs_error
        end
      end

      token = @source[start...@index]

      return token.to_f64 if is_float
      return token.to_i32 if has_digits_before_dot

      raise invalid_rhs_error
    end

    private def parse_variable : Value
      start = @index
      advance
      raise invalid_rhs_error unless identifier_start?(current_char)

      advance
      while identifier_continue?(current_char)
        advance
      end

      var_name = @source[start...@index]
      if value = @env[var_name]?
        return value
      end

      raise ExpressionError.new("Error: variable '#{var_name}' does not exist")
    end

    private def apply_operator(left : Value, right : Value, operator : Char) : Value
      case operator
      when '+'
        if left.is_a?(String) || right.is_a?(String)
          return value_to_string(left) + value_to_string(right)
        end

        left_number = number_operand(left, operator)
        right_number = number_operand(right, operator)

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number + right_number
        else
          left_number.to_f64 + right_number.to_f64
        end
      when '-'
        left_number = number_operand(left, operator)
        right_number = number_operand(right, operator)

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number - right_number
        else
          left_number.to_f64 - right_number.to_f64
        end
      when '*'
        left_number = number_operand(left, operator)
        right_number = number_operand(right, operator)

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number * right_number
        else
          left_number.to_f64 * right_number.to_f64
        end
      when '/'
        left_number = number_operand(left, operator)
        right_number = number_operand(right, operator)

        if right_number.to_f64 == 0.0
          raise ExpressionError.new("Error: division by zero")
        end

        left_number.to_f64 / right_number.to_f64
      when '%'
        left_number = number_operand(left, operator)
        right_number = number_operand(right, operator)

        if right_number.to_f64 == 0.0
          raise ExpressionError.new("Error: modulo by zero")
        end

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number % right_number
        else
          left_number.to_f64 % right_number.to_f64
        end
      when '^'
        left_number = number_operand(left, operator)
        right_number = number_operand(right, operator)

        if left_number.is_a?(Int32) && right_number.is_a?(Int32) && right_number >= 0
          pow_int(left_number, right_number)
        else
          left_number.to_f64 ** right_number.to_f64
        end
      else
        raise invalid_rhs_error
      end
    end

    private def number_operand(value : Value, operator : Char) : Number
      if value.is_a?(String)
        raise ExpressionError.new("Error: operator '#{operator}' requires numeric operands")
      end

      if value.nil?
        raise ExpressionError.new("Error: void value cannot be used in expressions")
      end

      value
    end

    private def value_to_string(value : Value) : String
      if value.nil?
        raise ExpressionError.new("Error: void value cannot be used in expressions")
      end

      if value.is_a?(String)
        value
      else
        value.to_s
      end
    end

    private def pow_int(base : Int32, exponent : Int32) : Int32
      result = 1
      exponent.times do
        result *= base
      end
      result
    end

    private def negate(value : Value) : Number
      if value.is_a?(String)
        raise ExpressionError.new("Error: operator '-' requires numeric operands")
      end

      if value.nil?
        raise ExpressionError.new("Error: void value cannot be used in expressions")
      end

      if value.is_a?(Int32)
        -value
      else
        -value.to_f64
      end
    end

    private def skip_whitespace
      while whitespace?(current_char)
        advance
      end
    end

    private def current_char : Char?
      @source[@index]?
    end

    private def advance
      @index += 1
    end

    private def end_of_input? : Bool
      @index >= @source.size
    end

    private def digit?(char : Char?) : Bool
      return false unless char
      char.ascii_number?
    end

    private def whitespace?(char : Char?) : Bool
      char == ' ' || char == '\t'
    end

    private def identifier_start?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char == '_'
    end

    private def identifier_continue?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char.ascii_number? || char == '_'
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end

  class ExpressionError < Exception
  end
end
