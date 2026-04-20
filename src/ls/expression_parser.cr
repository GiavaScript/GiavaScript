module Ls
  class ExpressionParser
    @env : Hash(String, Value)
    @call_function : Proc(String, Array(Value), Value)?
    @tokenizer : Tokenizer
    @current : Tokenizer::Token

    def initialize(@source : String, @env : Hash(String, Value), @call_function : Proc(String, Array(Value), Value)? = nil)
      @tokenizer = Tokenizer.new(@source, @env, @call_function)
      @current = @tokenizer.next_token
    end

    def parse : Value
      value = parse_expression
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Eof
      value
    end

    private def parse_expression : Value
      left = parse_term

      loop do
        operator = @current.kind
        break unless operator == Tokenizer::TokenKind::Plus || operator == Tokenizer::TokenKind::Minus

        advance_token
        right = parse_term
        left = apply_operator(left, right, operator == Tokenizer::TokenKind::Plus ? '+' : '-')
      end

      left
    end

    private def parse_term : Value
      left = parse_power

      loop do
        operator = @current.kind
        break unless operator == Tokenizer::TokenKind::Star || operator == Tokenizer::TokenKind::Slash || operator == Tokenizer::TokenKind::Percent

        advance_token
        right = parse_power
        left = apply_operator(left, right, term_operator_char(operator))
      end

      left
    end

    private def parse_power : Value
      left = parse_factor

      if @current.kind == Tokenizer::TokenKind::Caret
        advance_token
        right = parse_power
        return apply_operator(left, right, '^')
      end

      left
    end

    private def parse_factor : Value
      if @current.kind == Tokenizer::TokenKind::Plus
        advance_token
        return parse_factor
      end

      if @current.kind == Tokenizer::TokenKind::Minus
        advance_token
        value = parse_factor
        return negate(value)
      end

      case @current.kind
      when Tokenizer::TokenKind::LParen
        advance_token
        value = parse_expression
        raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RParen
        advance_token
        value
      when Tokenizer::TokenKind::String
        string_value = @current.lexeme
        advance_token
        string_value
      when Tokenizer::TokenKind::Number
        number_lexeme = @current.lexeme
        advance_token
        parse_number_value(number_lexeme)
      when Tokenizer::TokenKind::Identifier
        parse_identifier_expression
      else
        raise invalid_rhs_error
      end
    end

    private def parse_identifier_expression : Value
      identifier = @current.lexeme
      advance_token

      if identifier == "null"
        return nil
      end

      if @current.kind == Tokenizer::TokenKind::LParen
        return parse_function_call(identifier)
      end

      if @env.has_key?(identifier)
        return @env[identifier]
      end

      raise ExpressionError.new("Error: variable '#{identifier}' does not exist")
    end

    private def parse_function_call(function_name : String) : Value
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LParen
      advance_token

      args = [] of Value

      unless @current.kind == Tokenizer::TokenKind::RParen
        loop do
          args << parse_expression

          if @current.kind == Tokenizer::TokenKind::Comma
            advance_token
            next
          end

          break
        end
      end

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RParen
      advance_token

      unless call_function = @call_function
        raise ExpressionError.new("Error: function '#{function_name}' does not exist")
      end

      call_function.call(function_name, args)
    end

    private def parse_number_value(number_lexeme : String) : Number
      return number_lexeme.to_f64 if number_lexeme.includes?('.')
      number_lexeme.to_i32
    rescue
      raise invalid_rhs_error
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
        raise ExpressionError.new("Error: operator '#{operator}' requires numeric operands")
      end

      value
    end

    private def value_to_string(value : Value) : String
      if value.nil?
        return "null"
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
        raise ExpressionError.new("Error: operator '-' requires numeric operands")
      end

      if value.is_a?(Int32)
        -value
      else
        -value.to_f64
      end
    end

    private def term_operator_char(kind : Tokenizer::TokenKind) : Char
      case kind
      when Tokenizer::TokenKind::Star
        '*'
      when Tokenizer::TokenKind::Slash
        '/'
      else
        '%'
      end
    end

    private def advance_token
      @current = @tokenizer.next_token
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
