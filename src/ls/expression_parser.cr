module Ls
  class ExpressionParser
    @source : String
    @index : Int32
    @env : Hash(String, Number)

    def initialize(@source : String, @env : Hash(String, Number))
      @index = 0
    end

    def parse : Number | String
      begin
        value = parse_expression
        skip_whitespace
        return "Error: invalid right-hand side '#{@source}'" unless end_of_input?
        value
      rescue ex : ExpressionError
        ex.message || "Error: invalid right-hand side '#{@source}'"
      end
    end

    private def parse_expression : Number
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

    private def parse_term : Number
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

    private def parse_power : Number
      left = parse_factor

      skip_whitespace
      if current_char == '^'
        advance
        right = parse_power
        return apply_operator(left, right, '^')
      end

      left
    end

    private def parse_factor : Number
      skip_whitespace
      raise invalid_rhs_error if end_of_input?

      case current_char
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
      else
        parse_number
      end
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

    private def parse_variable : Number
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

    private def apply_operator(left : Number, right : Number, operator : Char) : Number
      case operator
      when '+'
        if left.is_a?(Int32) && right.is_a?(Int32)
          left + right
        else
          left.to_f64 + right.to_f64
        end
      when '-'
        if left.is_a?(Int32) && right.is_a?(Int32)
          left - right
        else
          left.to_f64 - right.to_f64
        end
      when '*'
        if left.is_a?(Int32) && right.is_a?(Int32)
          left * right
        else
          left.to_f64 * right.to_f64
        end
      when '/'
        if right.to_f64 == 0.0
          raise ExpressionError.new("Error: division by zero")
        end

        left.to_f64 / right.to_f64
      when '%'
        if right.to_f64 == 0.0
          raise ExpressionError.new("Error: modulo by zero")
        end

        if left.is_a?(Int32) && right.is_a?(Int32)
          left % right
        else
          left.to_f64 % right.to_f64
        end
      when '^'
        if left.is_a?(Int32) && right.is_a?(Int32) && right >= 0
          pow_int(left, right)
        else
          left.to_f64 ** right.to_f64
        end
      else
        raise invalid_rhs_error
      end
    end

    private def pow_int(base : Int32, exponent : Int32) : Int32
      result = 1
      exponent.times do
        result *= base
      end
      result
    end

    private def negate(value : Number) : Number
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
