module Ls
  class Interpreter
    IDENTIFIER_REGEX = /^[A-Za-z_][A-Za-z0-9_]*$/

    def initialize
      @env = Hash(String, Value).new
      @function_runtime = FunctionRuntime.new
    end

    def repl(input : IO = STDIN, output : IO = STDOUT)
      output.puts "GiavaScript REPL"
      output.puts "Type :quit to exit"

      loop do
        output.print "> "
        line = input.gets
        break if line.nil?

        text = line.not_nil!.strip
        break if text == ":quit"
        next if text.empty?

        eval(text).each { |message| output.puts(message) }
      end
    end

    def eval(input : String) : Array(String)
      messages = [] of String
      statements = begin
        StatementSplitter.new(input).split
      rescue ex : ExpressionError
        return [ex.message || "Error: invalid statement"]
      end

      statements.each do |stmt|
        message = eval_statement(stmt, @env, false)
        messages << message if message
      end
      messages
    end

    private def eval_statement(stmt : String, env : Hash(String, Value), inside_function : Bool) : String?
      if stmt.starts_with?("function ")
        begin
          @function_runtime.define_function(stmt)
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid function definition"
        end
      end

      if starts_with_keyword?(stmt, "if")
        return eval_if_statement(stmt, env, inside_function)
      end

      if match = stmt.match(/^return(?:\s+(.+))?$/m)
        if inside_function
          return_value_expr = match[1]?
          value = return_value_expr ? eval_rhs(return_value_expr.strip, env) : UNDEFINED
          raise FunctionRuntime::ReturnSignal.new(value)
        end

        return "Error: return can only be used inside functions"
      end

      if match = stmt.match(/^var\s+([A-Za-z_][A-Za-z0-9_]*)$/)
        var_name = match[1]

        if env.has_key?(var_name)
          return "Error: variable '#{var_name}' already exists"
        end

        env[var_name] = UNDEFINED
        return nil
      end

      if match = stmt.match(/^var\s+([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*(.+)$/)
        var_name = match[1]
        rhs = match[2].strip

        if env.has_key?(var_name)
          return "Error: variable '#{var_name}' already exists"
        end

        begin
          value = eval_rhs(rhs, env)
          env[var_name] = value
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid right-hand side '#{rhs}'"
        end
      end

      if assignment = split_assignment_statement(stmt)
        lhs = assignment[:lhs]
        rhs = assignment[:rhs]

        begin
          value = eval_rhs(rhs, env)
          assignment_target = parse_assignment_target(lhs)
          assign_to_target(assignment_target, value, env)
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid assignment"
        end
      end

      if stmt.matches?(IDENTIFIER_REGEX)
        if env.has_key?(stmt)
          return value_to_s(env[stmt])
        end
        return "Error: variable '#{stmt}' does not exist"
      end

      begin
        value = eval_rhs(stmt, env)
        value_to_s(value)
      rescue ex : ExpressionError
        ex.message || "Error: invalid right-hand side '#{stmt}'"
      end
    end

    private def eval_rhs(rhs : String, env : Hash(String, Value)) : Value
      ast = ExpressionParser.new(rhs).parse
      evaluate_expression(ast, env)
    end

    private def evaluate_expression(expr : Expr, env : Hash(String, Value)) : Value
      ExpressionEvaluator.new(
        env,
        ->(name : String, args : Array(Value)) { call_function(name, args, env).as(Value) },
        ->(name : String) { resolve_function_reference(name, env) }
      ).evaluate(expr)
    end

    private def resolve_function_reference(name : String, env : Hash(String, Value)) : BuiltinFunction?
      return nil unless @function_runtime.function_defined?(name)

      BuiltinFunction.new(name, ->(_receiver : Value, args : Array(Value)) { call_function(name, args, env).as(Value) })
    end

    private def parse_assignment_target(lhs : String) : Expr
      ExpressionParser.new(lhs).parse
    rescue ex : ExpressionError
      raise ExpressionError.new("Error: invalid assignment target '#{lhs}'")
    end

    private def assign_to_target(target_expr : Expr, value : Value, env : Hash(String, Value))
      case target_expr
      when VariableExpr
        assign_to_variable(target_expr, value, env)
      when IndexExpr
        assign_to_index(target_expr, value, env)
      when PropertyAccessExpr
        assign_to_property(target_expr, value, env)
      else
        raise ExpressionError.new("Error: invalid assignment target")
      end
    end

    private def assign_to_variable(target_expr : VariableExpr, value : Value, env : Hash(String, Value))
      unless env.has_key?(target_expr.name)
        raise ExpressionError.new("Error: variable '#{target_expr.name}' does not exist")
      end

      env[target_expr.name] = value
    end

    private def assign_to_index(target_expr : IndexExpr, value : Value, env : Hash(String, Value))
      target_value = evaluate_expression(target_expr.target, env)
      index_value = evaluate_expression(target_expr.index, env)

      if target_value.is_a?(Array)
        assign_to_array_index(target_value, index_value, value)
        return
      end

      if target_value.is_a?(Hash(String, Value))
        key = normalize_object_key(index_value)
        target_value[key] = value
        return
      end

      raise ExpressionError.new("Error: indexing assignment is only supported on arrays and objects")
    end

    private def assign_to_property(target_expr : PropertyAccessExpr, value : Value, env : Hash(String, Value))
      target_value = evaluate_expression(target_expr.target, env)
      unless target_value.is_a?(Hash(String, Value))
        raise ExpressionError.new("Error: dot property assignment is only supported on objects")
      end

      target_value[target_expr.property] = value
    end

    private def assign_to_array_index(target : Array(Value), index_value : Value, value : Value)
      unless index_value.is_a?(Int32)
        raise ExpressionError.new("Error: array index must be an integer")
      end

      if index_value < 0
        raise ExpressionError.new("Error: array index must be a non-negative integer")
      end

      while target.size <= index_value
        target << UNDEFINED
      end

      target[index_value] = value
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

    private def split_assignment_statement(stmt : String) : NamedTuple(lhs: String, rhs: String)?
      current = 0
      string_delimiter = nil.as(Char?)
      escaping = false
      paren_depth = 0
      bracket_depth = 0
      brace_depth = 0

      while current < stmt.size
        char = stmt[current]

        if delimiter = string_delimiter
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end

          current += 1
          next
        end

        case char
        when '"', '\''
          string_delimiter = char
        when '('
          paren_depth += 1
        when ')'
          paren_depth -= 1 if paren_depth > 0
        when '['
          bracket_depth += 1
        when ']'
          bracket_depth -= 1 if bracket_depth > 0
        when '{'
          brace_depth += 1
        when '}'
          brace_depth -= 1 if brace_depth > 0
        when '='
          previous_char = current > 0 ? stmt[current - 1] : nil
          next_char = stmt[current + 1]?

          if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0 &&
             previous_char != '!' && previous_char != '<' && previous_char != '>' && previous_char != '=' &&
             next_char != '='
            lhs = stmt[0...current].strip
            rhs = stmt[current + 1...stmt.size].strip
            return nil if lhs.empty? || rhs.empty?

            return {lhs: lhs, rhs: rhs}
          end
        end

        current += 1
      end

      nil
    end

    private def eval_if_statement(stmt : String, env : Hash(String, Value), inside_function : Bool) : String?
      parsed_if = begin
        IfStatementParser.new(stmt).parse_from
      rescue ex : ExpressionError
        return ex.message || "Error: invalid if statement"
      end

      begin
        condition_value = eval_rhs(parsed_if.condition, env)
        branch = truthy?(condition_value) ? parsed_if.consequent : parsed_if.alternate
        return nil unless branch

        eval_if_branch(branch, env, inside_function)
      rescue ex : ExpressionError
        ex.message || "Error: invalid if statement"
      end
    end

    private def eval_if_branch(branch : String, env : Hash(String, Value), inside_function : Bool) : String?
      if block_statement?(branch)
        block_body = branch[1...branch.size - 1]
        statements = StatementSplitter.new(block_body).split
        branch_message = nil.as(String?)

        statements.each do |statement|
          message = eval_statement(statement, env, inside_function)
          branch_message = message if message
        end

        return branch_message
      end

      eval_statement(branch, env, inside_function)
    end

    private def block_statement?(stmt : String) : Bool
      stmt.starts_with?("{") && stmt.ends_with?("}")
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

    private def starts_with_keyword?(source : String, keyword : String) : Bool
      return false unless source.starts_with?(keyword)

      next_char = source[keyword.size]?
      next_char.nil? || next_char == ' ' || next_char == '\t' || next_char == '\n' || next_char == '\r' || next_char == '('
    end

    private def call_function(name : String, args : Array(Value), env : Hash(String, Value)) : Value
      @function_runtime.invoke_function(name, args, env) do |stmt, local_env, inside_function|
        eval_statement(stmt, local_env, inside_function)
      end
    end

    private def value_to_s(value : Value) : String
      return "null" if value.nil?
      return "undefined" if value.is_a?(UndefinedValue)

      if value.is_a?(String)
        "\"#{escape_string(value)}\""
      elsif value.is_a?(Array)
        "[#{value.map { |item| value_to_s(item) }.join(", ")}]"
      elsif value.is_a?(Hash(String, Value))
        properties = value.map do |key, property_value|
          "\"#{escape_string(key)}\": #{value_to_s(property_value)}"
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
  end
end
