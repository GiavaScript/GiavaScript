module GiavaScript
  class ExpressionEvaluator
    def initialize(@env : Environment, @call_function : Proc(String, Array(Value), Value)? = nil, @resolve_function : Proc(String, BuiltinFunction?)? = nil)
    end

    def evaluate(expr : Expr) : Value
      case expr
      when LiteralExpr
        expr.value
      when VariableExpr
        if @env.has_key?(expr.name)
          @env[expr.name]
        elsif resolve_function = @resolve_function
          function_value = resolve_function.call(expr.name)
          if function_value
            function_value
          else
            raise ExpressionError.new("Error: variable '#{expr.name}' does not exist")
          end
        else
          raise ExpressionError.new("Error: variable '#{expr.name}' does not exist")
        end
      when UnaryExpr
        evaluate_unary(expr)
      when BinaryExpr
        evaluate_binary(expr)
      when FunctionCallExpr
        evaluate_function_call(expr)
      when ArrayLiteral
        values = Array(Value).new(expr.elements.size)
        expr.elements.each do |element|
          values << evaluate(element)
        end
        values
      when ObjectLiteral
        evaluate_object_literal(expr)
      when IndexExpr
        evaluate_index_expression(expr)
      when PropertyAccessExpr
        evaluate_property_access(expr)
      else
        raise ExpressionError.new("Error: invalid expression")
      end
    end

    private def evaluate_object_literal(expr : ObjectLiteral) : Value
      object = Hash(String, Value).new
      expr.properties.each do |property|
        object[property.key] = evaluate(property.value)
      end
      object
    end

    private def evaluate_unary(expr : UnaryExpr) : Value
      case expr.operator
      when Tokenizer::TokenKind::Plus
        coerce_to_number(evaluate(expr.operand))
      when Tokenizer::TokenKind::Minus
        negate(evaluate(expr.operand))
      when Tokenizer::TokenKind::Bang
        !truthy?(evaluate(expr.operand))
      else
        raise ExpressionError.new("Error: invalid expression")
      end
    end

    private def evaluate_binary(expr : BinaryExpr) : Value
      left = evaluate(expr.left)

      case expr.operator
      when Tokenizer::TokenKind::AndAnd
        return left unless truthy?(left)
        return evaluate(expr.right)
      when Tokenizer::TokenKind::OrOr
        return left if truthy?(left)
        return evaluate(expr.right)
      end

      right = evaluate(expr.right)
      apply_binary_operator(left, right, expr.operator)
    end

    private def evaluate_function_call(expr : FunctionCallExpr) : Value
      callee_with_receiver = evaluate_callee_with_receiver(expr.callee)

      args = Array(Value).new(expr.args.size)
      expr.args.each do |arg|
        args << evaluate(arg)
      end

      invoke_callable(callee_with_receiver[:callable], callee_with_receiver[:receiver], args)
    end

    private def evaluate_index_expression(expr : IndexExpr) : Value
      target = evaluate(expr.target)
      raise_undefined_null_property_error(target) if target.nil? || target.is_a?(UndefinedValue)

      if target.is_a?(Array)
        return evaluate_array_index(target, expr.index)
      end

      if target.is_a?(Hash(String, Value))
        key = normalize_object_key(evaluate(expr.index))
        return lookup_object_property(target, key)
      end

      raise ExpressionError.new("Error: indexing is only supported on arrays and objects")
    end

    private def evaluate_property_access(expr : PropertyAccessExpr) : Value
      target = evaluate(expr.target)
      resolve_property_access_value(target, expr.property)
    end

    private def evaluate_callee_with_receiver(callee_expr : Expr) : NamedTuple(callable: Value, receiver: Value)
      if callee_expr.is_a?(PropertyAccessExpr)
        target = evaluate(callee_expr.target)
        callable = resolve_property_access_value(target, callee_expr.property)
        return {callable: callable, receiver: target}
      end

      if callee_expr.is_a?(VariableExpr)
        if @env.has_key?(callee_expr.name)
          return {callable: @env[callee_expr.name], receiver: nil}
        end

        if resolve_function = @resolve_function
          function_value = resolve_function.call(callee_expr.name)
          if function_value
            return {callable: function_value, receiver: nil}
          end
        end

        raise ExpressionError.new("Error: function '#{callee_expr.name}' does not exist")
      end

      {callable: evaluate(callee_expr), receiver: nil}
    end

    private def resolve_property_access_value(target : Value, property : String) : Value
      raise_undefined_null_property_error(target, property) if target.nil? || target.is_a?(UndefinedValue)

      instance_lookup = lookup_instance_property(target, property)
      if instance_lookup[:found]
        return instance_lookup[:value]
      end

      type_lookup = RuntimeTypes.lookup_type_property(target, property)
      if type_lookup[:found]
        return type_lookup[:value]
      end

      UNDEFINED
    end

    private def evaluate_array_index(target : Array(Value), index_expr : Expr) : Value
      index_value = evaluate(index_expr)
      unless index_value.is_a?(Int32)
        raise ExpressionError.new("Error: array index must be an integer")
      end

      if index_value < 0 || index_value >= target.size
        return UNDEFINED
      end

      target[index_value]
    end

    private def normalize_object_key(key_value : Value) : String
      if key_value.is_a?(String)
        return key_value
      end

      if key_value.is_a?(Int32)
        return key_value.to_s
      end

      if key_value.is_a?(Float64)
        return key_value.to_s
      end

      raise ExpressionError.new("Error: object property key must be a string or number")
    end

    private def lookup_object_property(target : Hash(String, Value), key : String) : Value
      target.fetch(key, UNDEFINED)
    end

    private def lookup_instance_property(target : Value, property : String) : NamedTuple(found: Bool, value: Value)
      if target.is_a?(Hash(String, Value))
        value = target.fetch(property) do
          return {found: false, value: UNDEFINED}
        end

        return {found: true, value: value}
      end

      {found: false, value: UNDEFINED}
    end

    private def invoke_callable(value : Value, receiver : Value, args : Array(Value)) : Value
      if value.is_a?(BuiltinFunction)
        return value.call(receiver, args)
      end

      raise ExpressionError.new("Error: value is not callable")
    end

    private def raise_undefined_null_property_error(target : Value, property : String? = nil)
      if target.nil?
        if property
          raise ExpressionError.new("Error: cannot access property '#{property}' of null")
        end

        raise ExpressionError.new("Error: cannot access properties of null")
      end

      if target.is_a?(UndefinedValue)
        if property
          raise ExpressionError.new("Error: cannot access property '#{property}' of undefined")
        end

        raise ExpressionError.new("Error: cannot access properties of undefined")
      end
    end

    private def apply_binary_operator(left : Value, right : Value, operator : Tokenizer::TokenKind) : Value
      case operator
      when Tokenizer::TokenKind::Plus
        if left.is_a?(String) || right.is_a?(String)
          return value_to_string(left) + value_to_string(right)
        end

        left_number = number_operand(left, "+")
        right_number = number_operand(right, "+")

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number + right_number
        else
          left_number.to_f64 + right_number.to_f64
        end
      when Tokenizer::TokenKind::Minus
        left_number = number_operand(left, "-")
        right_number = number_operand(right, "-")

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number - right_number
        else
          left_number.to_f64 - right_number.to_f64
        end
      when Tokenizer::TokenKind::Star
        left_number = number_operand(left, "*")
        right_number = number_operand(right, "*")

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number * right_number
        else
          left_number.to_f64 * right_number.to_f64
        end
      when Tokenizer::TokenKind::Slash
        left_number = number_operand(left, "/")
        right_number = number_operand(right, "/")

        if right_number.to_f64 == 0.0
          raise ExpressionError.new("Error: division by zero")
        end

        left_number.to_f64 / right_number.to_f64
      when Tokenizer::TokenKind::Percent
        left_number = number_operand(left, "%")
        right_number = number_operand(right, "%")

        if right_number.to_f64 == 0.0
          raise ExpressionError.new("Error: modulo by zero")
        end

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number % right_number
        else
          left_number.to_f64 % right_number.to_f64
        end
      when Tokenizer::TokenKind::Caret
        left_number = number_operand(left, "^")
        right_number = number_operand(right, "^")

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
      parsed = value.to_f64?
      return parsed if parsed

      value.strip.to_f64?
    end

    private def truthy?(value : Value) : Bool
      return false if value.nil?
      return false if value.is_a?(UndefinedValue)

      if value.is_a?(Bool)
        return value
      end

      if value.is_a?(String)
        return !value.empty?
      end

      if value.is_a?(Int32)
        return value != 0
      end

      if value.is_a?(Float64)
        return value != 0.0
      end

      true
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
      elsif value.is_a?(Array)
        "[#{value.map { |item| value_to_string(item) }.join(", ")}]"
      elsif value.is_a?(Hash(String, Value))
        properties = value.map do |key, property_value|
          "\"#{escape_string(key)}\": #{value_to_string(property_value)}"
        end
        "{#{properties.join(", ")}}"
      else
        value.to_s
      end
    end

    private def escape_string(value : String) : String
      value.gsub('\\', "\\\\")
        .gsub('"', "\\\"")
        .gsub('\n', "\\n")
        .gsub('\t', "\\t")
    end

    private def pow_int(base : Int32, exponent : Int32) : Int32
      result = 1
      current_base = base
      current_exponent = exponent

      while current_exponent > 0
        if (current_exponent & 1) == 1
          result *= current_base
        end

        current_exponent >>= 1
        current_base *= current_base if current_exponent > 0
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

    private def coerce_to_number(value : Value) : Number
      return value if value.is_a?(Int32)
      return value if value.is_a?(Float64)
      return value ? 1 : 0 if value.is_a?(Bool)
      return 0 if value.nil?
      return Float64::NAN if value.is_a?(UndefinedValue)

      if value.is_a?(String)
        trimmed = value.strip
        return 0 if trimmed.empty?

        parsed = trimmed.to_f64?
        return parsed if parsed

        return Float64::NAN
      end

      Float64::NAN
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
      when Tokenizer::TokenKind::AndAnd
        "&&"
      when Tokenizer::TokenKind::OrOr
        "||"
      else
        "?"
      end
    end
  end
end
