module Ls
  class ExpressionEvaluator
    def initialize(@env : Hash(String, Value), @call_function : Proc(String, Array(Value), Value)? = nil)
    end

    def evaluate(expr : Expr) : Value
      case expr
      when LiteralExpr
        expr.value
      when VariableExpr
        if @env.has_key?(expr.name)
          @env[expr.name]
        else
          raise ExpressionError.new("Error: variable '#{expr.name}' does not exist")
        end
      when UnaryExpr
        evaluate_unary(expr)
      when BinaryExpr
        left = evaluate(expr.left)
        right = evaluate(expr.right)
        apply_binary_operator(left, right, expr.operator)
      when FunctionCallExpr
        evaluate_function_call(expr)
      when ArrayLiteral
        values = [] of Value
        expr.elements.each do |element|
          values << evaluate(element)
        end
        values
      when IndexExpr
        evaluate_index_expression(expr)
      else
        raise ExpressionError.new("Error: invalid expression")
      end
    end

    private def evaluate_unary(expr : UnaryExpr) : Value
      case expr.operator
      when Tokenizer::TokenKind::Minus
        negate(evaluate(expr.operand))
      else
        raise ExpressionError.new("Error: invalid expression")
      end
    end

    private def evaluate_function_call(expr : FunctionCallExpr) : Value
      args = [] of Value
      expr.args.each do |arg|
        args << evaluate(arg)
      end

      unless call_function = @call_function
        raise ExpressionError.new("Error: function '#{expr.name}' does not exist")
      end

      call_function.call(expr.name, args)
    end

    private def evaluate_index_expression(expr : IndexExpr) : Value
      target = evaluate(expr.target)
      unless target.is_a?(Array)
        raise ExpressionError.new("Error: indexing is only supported on arrays")
      end

      index_value = evaluate(expr.index)
      unless index_value.is_a?(Int32)
        raise ExpressionError.new("Error: array index must be an integer")
      end

      if index_value < 0
        raise ExpressionError.new("Error: array index cannot be negative")
      end

      if index_value >= target.size
        raise ExpressionError.new("Error: array index #{index_value} is out of bounds for array of size #{target.size}")
      end

      target[index_value]
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
        raise ExpressionError.new("Error: invalid expression")
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
        raise ExpressionError.new("Error: invalid expression")
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
        raise ExpressionError.new("Error: invalid expression")
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
  end
end
