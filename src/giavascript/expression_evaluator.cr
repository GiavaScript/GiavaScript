module GiavaScript
  class ExpressionEvaluator
    def initialize(
      @env : Environment,
      @call_function : Proc(String, Array(Value), Value)? = nil,
      @resolve_function : Proc(String, BuiltinFunction?)? = nil,
      @invoke_user_function : Proc(UserFunction, Array(Value), Value)? = nil,
    )
    end

    def evaluate(expr : Expr) : Value
      case expr
      when LiteralExpr
        expr.value
      when TemplateLiteralExpr
        evaluate_template_literal(expr)
      when VariableExpr
        lookup = @env.lookup(expr.name)
        if lookup[:found]
          lookup[:value]
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
      when FunctionExpr
        UserFunction.new(expr.name, expr.parameters, expr.body_source, @env)
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

    private def evaluate_template_literal(expr : TemplateLiteralExpr) : Value
      value = String::Builder.new

      expr.segments.each_with_index do |segment, index|
        value << segment

        interpolation = expr.expressions[index]?
        if interpolation
          value << value_to_string(evaluate(interpolation))
        end
      end

      value.to_s
    end

    private def evaluate_unary(expr : UnaryExpr) : Value
      case expr.operator
      when Tokenizer::TokenKind::Plus
        coerce_to_number(evaluate(expr.operand))
      when Tokenizer::TokenKind::Minus
        negate(evaluate(expr.operand))
      when Tokenizer::TokenKind::Bang
        !truthy?(evaluate(expr.operand))
      when Tokenizer::TokenKind::Typeof
        evaluate_typeof(expr.operand)
      when Tokenizer::TokenKind::Void
        evaluate(expr.operand)
        UNDEFINED
      else
        raise ExpressionError.new("Error: invalid expression")
      end
    end

    private def evaluate_typeof(operand : Expr) : String
      if operand.is_a?(VariableExpr)
        lookup = @env.lookup(operand.name)
        if lookup[:found]
          return typeof_value(lookup[:value])
        end

        if resolve_function = @resolve_function
          function_value = resolve_function.call(operand.name)
          return typeof_value(function_value) if function_value
        end

        return "undefined"
      end

      typeof_value(evaluate(operand))
    end

    private def typeof_value(value : Value) : String
      return "undefined" if value.is_a?(UndefinedValue)
      return "object" if value.nil?
      return "boolean" if value.is_a?(Bool)
      return "number" if value.is_a?(Int32) || value.is_a?(Float64)
      return "string" if value.is_a?(String)
      return "function" if value.is_a?(BuiltinFunction) || value.is_a?(UserFunction)

      "object"
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

      if expr.property == "length"
        return target.size if target.is_a?(Array(Value))
        return target.size if target.is_a?(String)
      end

      resolve_property_access_value(target, expr.property)
    end

    private def evaluate_callee_with_receiver(callee_expr : Expr) : NamedTuple(callable: Value, receiver: Value)
      if callee_expr.is_a?(PropertyAccessExpr)
        target = evaluate(callee_expr.target)
        callable = resolve_property_access_value(target, callee_expr.property)
        return {callable: callable, receiver: target}
      end

      if callee_expr.is_a?(VariableExpr)
        lookup = @env.lookup(callee_expr.name)
        if lookup[:found]
          return {callable: lookup[:value], receiver: nil}
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
        callback_invoker = ->(callable : Value, callback_args : Array(Value)) do
          invoke_callable(callable, nil, callback_args).as(Value)
        end

        return RuntimeTypes.with_callback_invoker(callback_invoker) do
          value.call(receiver, args)
        end
      end

      if value.is_a?(UserFunction)
        invoke_user_function = @invoke_user_function
        if invoke_user_function
          return invoke_user_function.call(value, args)
        end
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
           Tokenizer::TokenKind::BangEqual,
           Tokenizer::TokenKind::EqualEqualEqual,
           Tokenizer::TokenKind::BangEqualEqual
        equality_result(left, right, operator)
      else
        raise ExpressionError.new("Error: invalid expression")
      end
    end

    private def comparison_result(left : Value, right : Value, operator : Tokenizer::TokenKind) : Bool
      if left.is_a?(Int32) && right.is_a?(Int32)
        return compare_numbers(left, right, operator)
      end

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

      operator_lexeme = operator_lexeme(operator)
      raise ExpressionError.new("Error: operator '#{operator_lexeme}' requires numeric operands")
    end

    private def equality_result(left : Value, right : Value, operator : Tokenizer::TokenKind) : Bool
      if operator == Tokenizer::TokenKind::EqualEqualEqual || operator == Tokenizer::TokenKind::BangEqualEqual
        result = strict_equality_result(left, right)
        return operator == Tokenizer::TokenKind::EqualEqualEqual ? result : !result
      end

      result = loose_equality_result(left, right)

      operator == Tokenizer::TokenKind::EqualEqual ? result : !result
    end

    private def loose_equality_result(left : Value, right : Value) : Bool
      return true if strict_equality_result(left, right)

      if left.nil?
        return right.is_a?(UndefinedValue)
      end

      if left.is_a?(UndefinedValue)
        return right.nil?
      end

      if (left.is_a?(Int32) || left.is_a?(Float64)) && right.is_a?(String)
        right_number = coerce_to_number(right)
        return strict_equality_result(left, right_number)
      end

      if left.is_a?(String) && (right.is_a?(Int32) || right.is_a?(Float64))
        left_number = coerce_to_number(left)
        return strict_equality_result(left_number, right)
      end

      if left.is_a?(Bool)
        return loose_equality_result(coerce_to_number(left), right)
      end

      if right.is_a?(Bool)
        return loose_equality_result(left, coerce_to_number(right))
      end

      if primitive_value_for_loose_equality?(left) && object_value_for_loose_equality?(right)
        return loose_equality_result(left, object_to_primitive_for_loose_equality(right))
      end

      if object_value_for_loose_equality?(left) && primitive_value_for_loose_equality?(right)
        return loose_equality_result(object_to_primitive_for_loose_equality(left), right)
      end

      false
    end

    private def strict_equality_result(left : Value, right : Value) : Bool
      if left.is_a?(Int32) || left.is_a?(Float64)
        return false unless right.is_a?(Int32) || right.is_a?(Float64)

        left_number = left.to_f64
        right_number = right.to_f64
        return false if left_number.nan? || right_number.nan?
        return left_number == right_number
      end

      if left.is_a?(String)
        return right.is_a?(String) && left == right
      end

      if left.is_a?(Bool)
        return right.is_a?(Bool) && left == right
      end

      if left.nil?
        return right.nil?
      end

      if left.is_a?(UndefinedValue)
        return right.is_a?(UndefinedValue)
      end

      if left.is_a?(Array(Value))
        return right.is_a?(Array(Value)) && left.object_id == right.object_id
      end

      if left.is_a?(Hash(String, Value))
        return right.is_a?(Hash(String, Value)) && left.object_id == right.object_id
      end

      if left.is_a?(BuiltinFunction)
        return right.is_a?(BuiltinFunction) && left.object_id == right.object_id
      end

      if left.is_a?(UserFunction)
        return right.is_a?(UserFunction) && left.object_id == right.object_id
      end

      false
    end

    private def primitive_value_for_loose_equality?(value : Value) : Bool
      value.is_a?(Int32) ||
        value.is_a?(Float64) ||
        value.is_a?(String) ||
        value.is_a?(Bool) ||
        value.nil? ||
        value.is_a?(UndefinedValue)
    end

    private def object_value_for_loose_equality?(value : Value) : Bool
      value.is_a?(Array(Value)) || value.is_a?(Hash(String, Value)) || value.is_a?(BuiltinFunction) || value.is_a?(UserFunction)
    end

    private def object_to_primitive_for_loose_equality(value : Value) : Value
      if value.is_a?(Array(Value))
        return array_to_js_string(value)
      end

      if value.is_a?(Hash(String, Value))
        return "[object Object]"
      end

      if value.is_a?(BuiltinFunction)
        return "function"
      end

      if value.is_a?(UserFunction)
        return "function"
      end

      value
    end

    private def array_to_js_string(values : Array(Value)) : String
      values.map { |item| js_string_element(item) }.join(",")
    end

    private def js_string_element(value : Value) : String
      return "" if value.nil? || value.is_a?(UndefinedValue)

      if value.is_a?(Array(Value))
        return array_to_js_string(value)
      end

      if value.is_a?(Hash(String, Value))
        return "[object Object]"
      end

      if value.is_a?(BuiltinFunction)
        return "function"
      end

      if value.is_a?(UserFunction)
        return "function"
      end

      if value.is_a?(Bool)
        return value ? "true" : "false"
      end

      value.to_s
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

    private def compare_numbers(left : Int32, right : Int32, operator : Tokenizer::TokenKind) : Bool
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
        return value
      end

      if value.is_a?(Bool)
        return value ? "true" : "false"
      end

      if value.is_a?(Array(Value))
        return array_to_js_string(value)
      end

      if value.is_a?(Hash(String, Value))
        return "[object Object]"
      end

      if value.is_a?(BuiltinFunction)
        return "function"
      end

      if value.is_a?(UserFunction)
        return "function"
      end

      value.to_s
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
