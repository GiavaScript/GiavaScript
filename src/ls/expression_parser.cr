module Ls
  class ExpressionParser
    @env : Hash(String, Value)
    @call_function : Proc(String, Array(Value), Value)?
    @tokenizer : Tokenizer
    @current : Tokenizer::Token

    def initialize(@source : String, @env : Hash(String, Value), @call_function : Proc(String, Array(Value), Value)? = nil)
      @tokenizer = Tokenizer.new(@source)
      @current = @tokenizer.next_token
    end

    def parse : Value
      value = parse_expression
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Eof
      value
    end

    private def parse_expression : Value
      parse_equality
    end

    private def parse_equality : Value
      left = parse_comparison

      loop do
        operator = @current.kind
        break unless equality_operator?(operator)

        advance_token
        right = parse_comparison
        left = apply_binary_operator(left, right, operator)
      end

      left
    end

    private def parse_comparison : Value
      left = parse_addition

      loop do
        operator = @current.kind
        break unless comparison_operator?(operator)

        advance_token
        right = parse_addition
        left = apply_binary_operator(left, right, operator)
      end

      left
    end

    private def parse_addition : Value
      left = parse_term

      loop do
        operator = @current.kind
        break unless operator == Tokenizer::TokenKind::Plus || operator == Tokenizer::TokenKind::Minus

        advance_token
        right = parse_term
        left = apply_binary_operator(left, right, operator)
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
        left = apply_binary_operator(left, right, operator)
      end

      left
    end

    private def parse_power : Value
      left = parse_factor

      if @current.kind == Tokenizer::TokenKind::Caret
        advance_token
        right = parse_power
        return apply_binary_operator(left, right, Tokenizer::TokenKind::Caret)
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
      when Tokenizer::TokenKind::True
        advance_token
        true
      when Tokenizer::TokenKind::False
        advance_token
        false
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

      if identifier == "undefined"
        return UNDEFINED
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

    private def apply_binary_operator(left : Value, right : Value, operator : Tokenizer::TokenKind) : Value
      operator_lexeme = operator_lexeme(operator)

      case operator
      when Tokenizer::TokenKind::Plus
        if left.is_a?(String) || right.is_a?(String)
          return value_to_string(left) + value_to_string(right)
        end

        left_number = number_operand(left, operator_lexeme)
        right_number = number_operand(right, operator_lexeme)

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number + right_number
        else
          left_number.to_f64 + right_number.to_f64
        end
      when Tokenizer::TokenKind::Minus
        left_number = number_operand(left, operator_lexeme)
        right_number = number_operand(right, operator_lexeme)

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number - right_number
        else
          left_number.to_f64 - right_number.to_f64
        end
      when Tokenizer::TokenKind::Star
        left_number = number_operand(left, operator_lexeme)
        right_number = number_operand(right, operator_lexeme)

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number * right_number
        else
          left_number.to_f64 * right_number.to_f64
        end
      when Tokenizer::TokenKind::Slash
        left_number = number_operand(left, operator_lexeme)
        right_number = number_operand(right, operator_lexeme)

        if right_number.to_f64 == 0.0
          raise ExpressionError.new("Error: division by zero")
        end

        left_number.to_f64 / right_number.to_f64
      when Tokenizer::TokenKind::Percent
        left_number = number_operand(left, operator_lexeme)
        right_number = number_operand(right, operator_lexeme)

        if right_number.to_f64 == 0.0
          raise ExpressionError.new("Error: modulo by zero")
        end

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number % right_number
        else
          left_number.to_f64 % right_number.to_f64
        end
      when Tokenizer::TokenKind::Caret
        left_number = number_operand(left, operator_lexeme)
        right_number = number_operand(right, operator_lexeme)

        if left_number.is_a?(Int32) && right_number.is_a?(Int32) && right_number >= 0
          pow_int(left_number, right_number)
        else
          left_number.to_f64 ** right_number.to_f64
        end
      when Tokenizer::TokenKind::Less,
           Tokenizer::TokenKind::Greater,
           Tokenizer::TokenKind::LessEqual,
           Tokenizer::TokenKind::GreaterEqual
        comparison_result(left, right, operator)
      when Tokenizer::TokenKind::EqualEqual,
           Tokenizer::TokenKind::BangEqual
        equality_result(left, right, operator)
      else
        raise invalid_rhs_error
      end
    end

    private def comparison_result(left : Value, right : Value, operator : Tokenizer::TokenKind) : Bool
      operator_lexeme = operator_lexeme(operator)
      if left.is_a?(String)
        if right.is_a?(String)
          return compare_strings(left, right, operator)
        end

        if right.is_a?(Int32) || right.is_a?(Float64)
          left_number = parse_numeric_string(left)
          return false unless left_number

          return compare_numbers(left_number, right.to_f64, operator)
        end
      elsif left.is_a?(Int32) || left.is_a?(Float64)
        if right.is_a?(Int32) || right.is_a?(Float64)
          return compare_numbers(left.to_f64, right.to_f64, operator)
        end

        if right.is_a?(String)
          right_number = parse_numeric_string(right)
          return false unless right_number

          return compare_numbers(left.to_f64, right_number, operator)
        end
      end

      raise ExpressionError.new("Error: operator '#{operator_lexeme}' requires numeric operands")
    end

    private def equality_result(left : Value, right : Value, operator : Tokenizer::TokenKind) : Bool
      result = if left.is_a?(Int32) || left.is_a?(Float64)
                 if right.is_a?(Int32) || right.is_a?(Float64)
                   left.to_f64 == right.to_f64
                 else
                   operator_lexeme = operator_lexeme(operator)
                   raise ExpressionError.new("Error: operator '#{operator_lexeme}' requires both operands to be numbers or both operands to be booleans")
                 end
               elsif left.is_a?(Bool) && right.is_a?(Bool)
                 left == right
               else
                 operator_lexeme = operator_lexeme(operator)
                 raise ExpressionError.new("Error: operator '#{operator_lexeme}' requires both operands to be numbers or both operands to be booleans")
               end

      operator == Tokenizer::TokenKind::EqualEqual ? result : !result
    end

    private def number_operand(value : Value, operator : String) : Number
      if value.is_a?(Int32)
        return value
      end

      if value.is_a?(Float64)
        return value
      end

      raise ExpressionError.new("Error: operator '#{operator}' requires numeric operands")
    end

    private def parse_numeric_string(value : String) : Float64?
      value.strip.to_f64?
    end

    private def compare_numbers(left : Float64, right : Float64, operator : Tokenizer::TokenKind) : Bool
      case operator
      when Tokenizer::TokenKind::Less
        left < right
      when Tokenizer::TokenKind::Greater
        left > right
      when Tokenizer::TokenKind::LessEqual
        left <= right
      when Tokenizer::TokenKind::GreaterEqual
        left >= right
      else
        raise invalid_rhs_error
      end
    end

    private def compare_strings(left : String, right : String, operator : Tokenizer::TokenKind) : Bool
      case operator
      when Tokenizer::TokenKind::Less
        left < right
      when Tokenizer::TokenKind::Greater
        left > right
      when Tokenizer::TokenKind::LessEqual
        left <= right
      when Tokenizer::TokenKind::GreaterEqual
        left >= right
      else
        raise invalid_rhs_error
      end
    end

    private def value_to_string(value : Value) : String
      if value.nil?
        return "null"
      end

      if value.is_a?(UndefinedValue)
        return "undefined"
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
      number = number_operand(value, "-")

      if number.is_a?(Int32)
        -number
      else
        -number.to_f64
      end
    end

    private def comparison_operator?(kind : Tokenizer::TokenKind) : Bool
      kind == Tokenizer::TokenKind::Less ||
        kind == Tokenizer::TokenKind::Greater ||
        kind == Tokenizer::TokenKind::LessEqual ||
        kind == Tokenizer::TokenKind::GreaterEqual
    end

    private def equality_operator?(kind : Tokenizer::TokenKind) : Bool
      kind == Tokenizer::TokenKind::EqualEqual || kind == Tokenizer::TokenKind::BangEqual
    end

    private def operator_lexeme(kind : Tokenizer::TokenKind) : String
      case kind
      when Tokenizer::TokenKind::Plus
        "+"
      when Tokenizer::TokenKind::Minus
        "-"
      when Tokenizer::TokenKind::Star
        "*"
      when Tokenizer::TokenKind::Slash
        "/"
      when Tokenizer::TokenKind::Percent
        "%"
      when Tokenizer::TokenKind::Caret
        "^"
      when Tokenizer::TokenKind::Less
        "<"
      when Tokenizer::TokenKind::Greater
        ">"
      when Tokenizer::TokenKind::LessEqual
        "<="
      when Tokenizer::TokenKind::GreaterEqual
        ">="
      when Tokenizer::TokenKind::EqualEqual
        "=="
      when Tokenizer::TokenKind::BangEqual
        "!="
      else
        "?"
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
