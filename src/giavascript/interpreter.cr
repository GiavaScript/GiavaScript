module GiavaScript
  class Interpreter
    IDENTIFIER_REGEX         = /^[A-Za-z_][A-Za-z0-9_]*$/
    MAX_JSON_STRINGIFY_DEPTH = 1000
    MAX_EXPRESSION_CACHE_SIZE = 8_192
    MAX_RAW_STATEMENT_CACHE_SIZE = 8_192
    MAX_EVALUATOR_CACHE_SIZE = 1_024

    class BreakSignal < Exception
      def initialize
        super("break")
      end
    end

    class ContinueSignal < Exception
      def initialize
        super("continue")
      end
    end

    @env : Environment
    @function_runtime : FunctionRuntime
    @expression_cache : Hash(String, Expr)
    @raw_statement_cache : Hash(String, CompiledRawStatement)
    @expression_evaluator_cache : Hash(UInt64, ExpressionEvaluator)

    abstract class CompiledRawStatement
    end

    class FallbackRawStatement < CompiledRawStatement
      getter source : String

      def initialize(@source : String)
      end
    end

    class IncrementRawStatement < CompiledRawStatement
      getter target : Expr
      getter operator : String

      def initialize(@target : Expr, @operator : String)
      end
    end

    class VarRawStatement < CompiledRawStatement
      getter name : String
      getter initializer : Expr?
      getter initializer_source : String?

      def initialize(@name : String, @initializer : Expr?, @initializer_source : String?)
      end
    end

    class AssignmentRawStatement < CompiledRawStatement
      getter target : Expr
      getter rhs : Expr
      getter operator : String

      def initialize(@target : Expr, @rhs : Expr, @operator : String)
      end
    end

    class IdentifierRawStatement < CompiledRawStatement
      getter name : String

      def initialize(@name : String)
      end
    end

    class ExpressionRawStatement < CompiledRawStatement
      getter expr : Expr
      getter source : String

      def initialize(@expr : Expr, @source : String)
      end
    end

    def initialize(@console_output : IO = STDOUT)
      @env = build_global_env
      @function_runtime = FunctionRuntime.new
      @expression_cache = Hash(String, Expr).new
      @raw_statement_cache = Hash(String, CompiledRawStatement).new
      @expression_evaluator_cache = Hash(UInt64, ExpressionEvaluator).new
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
        message = eval_statement(stmt, @env, false, false, false)
        messages << message if message
      end
      messages
    end

    private def eval_statement(stmt : String, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      if stmt.starts_with?("function ")
        begin
          @function_runtime.define_function(stmt)
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid function definition"
        end
      end

      if starts_with_keyword?(stmt, "if")
        return eval_if_statement(stmt, env, inside_function, inside_loop, inside_switch)
      end

      if starts_with_keyword?(stmt, "for")
        return eval_for_statement(stmt, env, inside_function, inside_loop, inside_switch)
      end

      if starts_with_keyword?(stmt, "while") || starts_with_keyword?(stmt, "do")
        return eval_while_statement(stmt, env, inside_function, inside_loop, inside_switch)
      end

      if starts_with_keyword?(stmt, "switch")
        return eval_switch_statement(stmt, env, inside_function, inside_loop, inside_switch)
      end

      if stmt == "break"
        return "Error: break can only be used inside loops or switch statements" unless inside_loop || inside_switch
        raise BreakSignal.new
      end

      if stmt == "continue"
        return "Error: continue can only be used inside loops" unless inside_loop
        raise ContinueSignal.new
      end

      if match = stmt.match(/^return(?:\s+(.+))?$/m)
        if inside_function
          return_value_expr = match[1]?
          value = return_value_expr ? eval_rhs(return_value_expr.strip, env) : UNDEFINED
          raise FunctionRuntime::ReturnSignal.new(value)
        end

        return "Error: return can only be used inside functions"
      end

      if match = stmt.match(/^(.+?)\s*(\+\+|--)$/)
        target_source = match[1].strip
        operator = match[2]

        begin
          target_expr = parse_assignment_target(target_source)
          current_value = evaluate_expression(target_expr, env)
          next_value = incremented_value(current_value, operator)
          assign_to_target(target_expr, next_value, env)
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid increment expression"
        end
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
        operator = assignment[:operator]

        begin
          assignment_target = parse_assignment_target(lhs)
          value = if operator == "="
                    eval_rhs(rhs, env)
                  else
                    current_value = evaluate_expression(assignment_target, env)
                    rhs_value = eval_rhs(rhs, env)
                    apply_compound_assignment_operator(current_value, rhs_value, operator)
                  end
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

    private def eval_rhs(rhs : String, env : Environment) : Value
      ast = parsed_expression(rhs)
      evaluate_expression(ast, env)
    end

    private def evaluate_expression(expr : Expr, env : Environment) : Value
      evaluator_for(env).evaluate(expr)
    end

    private def evaluator_for(env : Environment) : ExpressionEvaluator
      key = env.object_id
      evaluator = @expression_evaluator_cache[key]?
      return evaluator if evaluator

      @expression_evaluator_cache.clear if @expression_evaluator_cache.size >= MAX_EVALUATOR_CACHE_SIZE

      created = ExpressionEvaluator.new(
        env,
        ->(name : String, args : Array(Value)) { call_function(name, args, env).as(Value) },
        ->(name : String) { resolve_function_reference(name, env) }
      )
      @expression_evaluator_cache[key] = created
      created
    end

    private def resolve_function_reference(name : String, env : Environment) : BuiltinFunction?
      return nil unless @function_runtime.function_defined?(name)

      BuiltinFunction.new(name, ->(_receiver : Value, args : Array(Value)) { call_function(name, args, env).as(Value) })
    end

    private def parse_assignment_target(lhs : String) : Expr
      parsed_expression(lhs)
    rescue ex : ExpressionError
      raise ExpressionError.new("Error: invalid assignment target '#{lhs}'")
    end

    private def parsed_expression(source : String) : Expr
      key = source.strip
      cached = @expression_cache[key]?
      return cached if cached

      @expression_cache.clear if @expression_cache.size >= MAX_EXPRESSION_CACHE_SIZE

      parsed = ExpressionParser.new(key).parse
      @expression_cache[key] = parsed
      parsed
    end

    private def assign_to_target(target_expr : Expr, value : Value, env : Environment)
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

    private def assign_to_variable(target_expr : VariableExpr, value : Value, env : Environment)
      unless env.has_key?(target_expr.name)
        raise ExpressionError.new("Error: variable '#{target_expr.name}' does not exist")
      end

      env[target_expr.name] = value
    end

    private def assign_to_index(target_expr : IndexExpr, value : Value, env : Environment)
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

    private def assign_to_property(target_expr : PropertyAccessExpr, value : Value, env : Environment)
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

    private def split_assignment_statement(stmt : String) : NamedTuple(lhs: String, rhs: String, operator: String)?
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
        when '"', '\'', '`'
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
          previous_previous_char = current > 1 ? stmt[current - 2] : nil
          next_char = stmt[current + 1]?

          if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0 &&
             previous_char != '!' && previous_char != '<' && previous_char != '>' && previous_char != '=' &&
             next_char != '='
            operator = "="
            lhs_end = current

            if previous_char == '+' || previous_char == '-' || previous_char == '*' || previous_char == '/'
              operator = "#{previous_char}="
              lhs_end = current - 1

              if previous_previous_char == previous_char
                current += 1
                next
              end
            end

            lhs = stmt[0...lhs_end].strip
            rhs = stmt[current + 1...stmt.size].strip
            return nil if lhs.empty? || rhs.empty?

            return {lhs: lhs, rhs: rhs, operator: operator}
          end
        end

        current += 1
      end

      nil
    end

    private def eval_if_statement(stmt : String, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      parsed_if = begin
        IfStatementParser.new(stmt).parse_from
      rescue ex : ExpressionError
        return ex.message || "Error: invalid if statement"
      end

      eval_if_ast(parsed_if.statement, env, inside_function, inside_loop, inside_switch)
    end

    private def eval_if_ast(if_statement : IfStatement, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      begin
        condition_value = evaluate_expression(if_statement.condition, env)
        branch = truthy?(condition_value) ? if_statement.then_branch : if_statement.else_branch
        return nil unless branch

        eval_statement_node(branch, env, inside_function, inside_loop, inside_switch)
      rescue ex : ExpressionError
        ex.message || "Error: invalid if statement"
      end
    end

    private def eval_for_statement(stmt : String, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      parsed_for = begin
        ForStatementParser.new(stmt).parse_from
      rescue ex : ExpressionError
        return ex.message || "Error: invalid for statement"
      end

      eval_for_ast(parsed_for.statement, env, inside_function, inside_loop, inside_switch)
    end

    private def eval_for_ast(for_statement : ForStatement, env : Environment, inside_function : Bool, _inside_loop : Bool, inside_switch : Bool = false) : String?
      begin
        if init = for_statement.init
          init_message = eval_precompiled_raw_statement(init.source, env, inside_function, true, inside_switch)
          if init_message && init_message.starts_with?("Error:")
            return init_message
          end
        end

        loop do
          if condition = for_statement.condition
            condition_value = evaluate_expression(condition, env)
            break unless truthy?(condition_value)
          end

          begin
            body_message = eval_statement_node(for_statement.body, env, inside_function, true, inside_switch)
            if body_message && body_message.starts_with?("Error:")
              return body_message
            end
          rescue ContinueSignal
          rescue BreakSignal
            break
          end

          if update = for_statement.update
            update_message = eval_precompiled_raw_statement(update.source, env, inside_function, true, inside_switch)
            if update_message && update_message.starts_with?("Error:")
              return update_message
            end
          end
        end

        nil
      rescue ex : ExpressionError
        ex.message || "Error: invalid for statement"
      end
    end

    private def eval_while_statement(stmt : String, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      parsed_loop = begin
        WhileStatementParser.new(stmt).parse_from
      rescue ex : ExpressionError
        message = ex.message || ""
        return ex.message || "Error: invalid while statement" if message.starts_with?("Error: invalid while statement")
        return ex.message || "Error: invalid do...while statement" if message.starts_with?("Error: invalid do...while statement")
        return ex.message || "Error: invalid while statement"
      end

      case statement = parsed_loop.statement
      when WhileStatement
        eval_while_ast(statement, env, inside_function, inside_loop, inside_switch)
      when DoWhileStatement
        eval_do_while_ast(statement, env, inside_function, inside_loop, inside_switch)
      else
        "Error: invalid while statement"
      end
    end

    private def eval_while_ast(while_statement : WhileStatement, env : Environment, inside_function : Bool, _inside_loop : Bool, inside_switch : Bool = false) : String?
      begin
        loop do
          condition_value = evaluate_expression(while_statement.condition, env)
          break unless truthy?(condition_value)

          begin
            body_message = eval_statement_node(while_statement.body, env, inside_function, true, inside_switch)
            if body_message && body_message.starts_with?("Error:")
              return body_message
            end
          rescue ContinueSignal
          rescue BreakSignal
            break
          end
        end

        nil
      rescue ex : ExpressionError
        ex.message || "Error: invalid while statement"
      end
    end

    private def eval_do_while_ast(do_while_statement : DoWhileStatement, env : Environment, inside_function : Bool, _inside_loop : Bool, inside_switch : Bool = false) : String?
      begin
        loop do
          begin
            body_message = eval_statement_node(do_while_statement.body, env, inside_function, true, inside_switch)
            if body_message && body_message.starts_with?("Error:")
              return body_message
            end
          rescue ContinueSignal
          rescue BreakSignal
            break
          end

          condition_value = evaluate_expression(do_while_statement.condition, env)
          break unless truthy?(condition_value)
        end

        nil
      rescue ex : ExpressionError
        ex.message || "Error: invalid do...while statement"
      end
    end

    private def eval_switch_statement(stmt : String, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      parsed_switch = begin
        SwitchStatementParser.new(stmt).parse_from
      rescue ex : ExpressionError
        return ex.message || "Error: invalid switch statement"
      end

      eval_switch_ast(parsed_switch.statement, env, inside_function, inside_loop, inside_switch)
    end

    private def eval_switch_ast(switch_statement : SwitchStatement, env : Environment, inside_function : Bool, inside_loop : Bool, _inside_switch : Bool = false) : String?
      begin
        discriminant_value = evaluate_expression(switch_statement.discriminant, env)
        start_index = nil.as(Int32?)
        default_index = nil.as(Int32?)

        switch_statement.clauses.each_with_index do |clause, index|
          if clause.test.nil?
            default_index = index
            next
          end

          next unless start_index.nil?

          test_value = evaluate_expression(clause.test.not_nil!, env)
          if strict_equals_values?(discriminant_value, test_value)
            start_index = index
          end
        end

        execute_from = start_index || default_index
        return nil unless execute_from

        index = execute_from
        while index < switch_statement.clauses.size
          clause = switch_statement.clauses[index]

          clause.statements.each do |inner_statement|
            begin
              message = eval_statement_node(inner_statement, env, inside_function, inside_loop, true)
              if message && message.starts_with?("Error:")
                return message
              end
            rescue BreakSignal
              return nil
            end
          end

          index += 1
        end

        nil
      rescue ex : ExpressionError
        ex.message || "Error: invalid switch statement"
      end
    end

    private def eval_statement_node(statement : Statement, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      case statement
      when RawStatement
        eval_precompiled_raw_statement(statement.source, env, inside_function, inside_loop, inside_switch)
      when BlockStatement
        block_message = nil.as(String?)
        statement.statements.each do |inner_statement|
          message = eval_statement_node(inner_statement, env, inside_function, inside_loop, inside_switch)
          if message && message.starts_with?("Error:")
            return message
          end
          block_message = message if message
        end
        block_message
      when IfStatement
        eval_if_ast(statement, env, inside_function, inside_loop, inside_switch)
      when ForStatement
        eval_for_ast(statement, env, inside_function, inside_loop, inside_switch)
      when WhileStatement
        eval_while_ast(statement, env, inside_function, inside_loop, inside_switch)
      when DoWhileStatement
        eval_do_while_ast(statement, env, inside_function, inside_loop, inside_switch)
      when SwitchStatement
        eval_switch_ast(statement, env, inside_function, inside_loop, inside_switch)
      when BreakStatement
        return "Error: break can only be used inside loops or switch statements" unless inside_loop || inside_switch
        raise BreakSignal.new
      when ContinueStatement
        return "Error: continue can only be used inside loops" unless inside_loop
        raise ContinueSignal.new
      else
        raise ExpressionError.new("Error: invalid statement")
      end
    end

    private def eval_precompiled_raw_statement(source : String, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      compiled = compiled_raw_statement(source)

      case compiled
      when FallbackRawStatement
        eval_statement(compiled.source, env, inside_function, inside_loop, inside_switch)
      when IncrementRawStatement
        begin
          current_value = evaluate_expression(compiled.target, env)
          next_value = incremented_value(current_value, compiled.operator)
          assign_to_target(compiled.target, next_value, env)
          nil
        rescue ex : ExpressionError
          ex.message || "Error: invalid increment expression"
        end
      when VarRawStatement
        if env.has_key?(compiled.name)
          return "Error: variable '#{compiled.name}' already exists"
        end

        begin
          value = compiled.initializer ? evaluate_expression(compiled.initializer.not_nil!, env) : UNDEFINED
          env[compiled.name] = value
          nil
        rescue ex : ExpressionError
          rhs = compiled.initializer_source || ""
          ex.message || "Error: invalid right-hand side '#{rhs}'"
        end
      when AssignmentRawStatement
        begin
          value = if compiled.operator == "="
                    evaluate_expression(compiled.rhs, env)
                  else
                    current_value = evaluate_expression(compiled.target, env)
                    rhs_value = evaluate_expression(compiled.rhs, env)
                    apply_compound_assignment_operator(current_value, rhs_value, compiled.operator)
                  end
          assign_to_target(compiled.target, value, env)
          nil
        rescue ex : ExpressionError
          ex.message || "Error: invalid assignment"
        end
      when IdentifierRawStatement
        if env.has_key?(compiled.name)
          return value_to_s(env[compiled.name])
        end
        "Error: variable '#{compiled.name}' does not exist"
      when ExpressionRawStatement
        begin
          value = evaluate_expression(compiled.expr, env)
          value_to_s(value)
        rescue ex : ExpressionError
          ex.message || "Error: invalid right-hand side '#{compiled.source}'"
        end
      end
    end

    private def compiled_raw_statement(source : String) : CompiledRawStatement
      key = source.strip
      cached = @raw_statement_cache[key]?
      return cached if cached

      compiled = if key.starts_with?("function ") || starts_with_keyword?(key, "if") || starts_with_keyword?(key, "for") ||
                    starts_with_keyword?(key, "while") || starts_with_keyword?(key, "do") ||
                    key == "break" || key == "continue" || key.starts_with?("return")
                   FallbackRawStatement.new(source)
                 elsif match = key.match(/^(.+?)\s*(\+\+|--)$/)
                   target_source = match[1].strip
                   begin
                     target_expr = parse_assignment_target(target_source)
                     IncrementRawStatement.new(target_expr, match[2])
                   rescue
                     FallbackRawStatement.new(source)
                   end
                 elsif match = key.match(/^var\s+([A-Za-z_][A-Za-z0-9_]*)$/)
                   VarRawStatement.new(match[1], nil, nil)
                 elsif match = key.match(/^var\s+([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*(.+)$/)
                   name = match[1]
                   rhs_source = match[2].strip
                   begin
                     rhs = parsed_expression(rhs_source)
                     VarRawStatement.new(name, rhs, rhs_source)
                   rescue
                     FallbackRawStatement.new(source)
                   end
                 elsif assignment = split_assignment_statement(key)
                   begin
                     target = parse_assignment_target(assignment[:lhs])
                     rhs = parsed_expression(assignment[:rhs])
                     AssignmentRawStatement.new(target, rhs, assignment[:operator])
                   rescue
                     FallbackRawStatement.new(source)
                   end
                 elsif key.matches?(IDENTIFIER_REGEX)
                   IdentifierRawStatement.new(key)
                 else
                   begin
                     ExpressionRawStatement.new(parsed_expression(key), key)
                   rescue
                     FallbackRawStatement.new(source)
                   end
                 end

      unless compiled.is_a?(FallbackRawStatement)
        @raw_statement_cache.clear if @raw_statement_cache.size >= MAX_RAW_STATEMENT_CACHE_SIZE
        @raw_statement_cache[key] = compiled
      end

      compiled
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

    private def strict_equals_values?(left : Value, right : Value) : Bool
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

      false
    end

    private def starts_with_keyword?(source : String, keyword : String) : Bool
      return false unless source.starts_with?(keyword)

      next_char = source[keyword.size]?
      next_char.nil? || !(next_char.ascii_letter? || next_char.ascii_number? || next_char == '_')
    end

    private def call_function(name : String, args : Array(Value), env : Environment) : Value
      @function_runtime.invoke_function(name, args, env) do |stmt, local_env, inside_function, inside_loop|
        eval_statement(stmt, local_env, inside_function, inside_loop)
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

    private def build_global_env : Environment
      env = Environment.new
      env["console"] = build_console_object
      env["JSON"] = build_json_object
      env["Math"] = build_math_object
      env["parseInt"] = build_parse_int_function
      env["parseFloat"] = build_parse_float_function
      env["isNaN"] = build_is_nan_function
      env
    end

    private def build_parse_int_function : Value
      BuiltinFunction.new("parseInt", ->(_receiver : Value, args : Array(Value)) do
        assert_builtin_arity_between(args, 1, 2, "parseInt")

        source = to_primitive_string_for_globals(args[0]).lstrip
        nan = Float64::NAN.as(Value)

        result = if source.empty?
          nan
        else
          sign = 1
          if source.starts_with?('+')
            source = source[1...source.size]
          elsif source.starts_with?('-')
            sign = -1
            source = source[1...source.size]
          end

          if source.empty?
            nan
          else
            radix = 0
            if args.size == 2
              radix_number = number_argument(args[1], "parseInt", 1)
              radix = radix_number.to_i32
            end

            if radix != 0 && (radix < 2 || radix > 36)
              nan
            else
              if radix == 0
                if source.starts_with?("0x") || source.starts_with?("0X")
                  radix = 16
                  source = source[2...source.size]
                else
                  radix = 10
                end
              elsif radix == 16 && (source.starts_with?("0x") || source.starts_with?("0X"))
                source = source[2...source.size]
              end

              value = 0.0
              parsed_any_digit = false

              source.each_char do |char|
                digit = parse_int_digit_value(char)
                break unless digit
                break if digit >= radix

                parsed_any_digit = true
                value = value * radix + digit
              end

              if parsed_any_digit
                value *= sign

                if value.finite? && value >= Int32::MIN && value <= Int32::MAX
                  value.to_i32.as(Value)
                else
                  value.as(Value)
                end
              else
                nan
              end
            end
          end
        end

        result.as(Value)
      end)
    end

    private def build_parse_float_function : Value
      BuiltinFunction.new("parseFloat", ->(_receiver : Value, args : Array(Value)) do
        assert_builtin_arity(args, 1, "parseFloat")
        source = to_primitive_string_for_globals(args[0]).lstrip
        nan = Float64::NAN.as(Value)

        result = if match = source.match(/\A[+-]?(?:Infinity|(?:(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?))/)
          token = match[0]

          if token == "Infinity" || token == "+Infinity"
            Float64::INFINITY.as(Value)
          elsif token == "-Infinity"
            (-Float64::INFINITY).as(Value)
          else
            parsed = token.to_f64?
            parsed ? parsed.as(Value) : nan
          end
        else
          nan
        end

        result.as(Value)
      end)
    end

    private def build_is_nan_function : Value
      BuiltinFunction.new("isNaN", ->(_receiver : Value, args : Array(Value)) do
        assert_builtin_arity(args, 1, "isNaN")
        number = coerce_to_number_for_globals(args[0])
        (number.is_a?(Float64) && number.nan?).as(Value)
      end)
    end

    private def build_console_object : Hash(String, Value)
      console = Hash(String, Value).new

      console["log"] = BuiltinFunction.new("console.log", ->(receiver : Value, args : Array(Value)) do
        unless receiver.is_a?(Hash(String, Value))
          raise ExpressionError.new("Error: console.log receiver must be an object")
        end

        @console_output.puts(args.map { |arg| console_value_to_s(arg) }.join(" "))
        UNDEFINED.as(Value)
      end)

      console
    end

    private def console_value_to_s(value : Value) : String
      return "null" if value.nil?
      return "undefined" if value.is_a?(UndefinedValue)
      return value if value.is_a?(String)

      if value.is_a?(Array(Value))
        return "[#{value.map { |item| console_value_to_s(item) }.join(", ")}]"
      end

      if value.is_a?(Hash(String, Value))
        properties = value.map do |key, property_value|
          "\"#{console_value_to_s(key)}\": #{console_value_to_s(property_value)}"
        end
        return "{#{properties.join(", ")}}"
      end

      value.to_s
    end

    private def build_json_object : Hash(String, Value)
      json = Hash(String, Value).new

      json["parse"] = BuiltinFunction.new("JSON.parse", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "JSON.parse")
        assert_builtin_arity(args, 1, "JSON.parse")

        source = args[0]
        unless source.is_a?(String)
          raise ExpressionError.new("Error: JSON.parse argument 1 must be a string")
        end

        begin
          json_any_to_value(::JSON.parse(source)).as(Value)
        rescue ::JSON::ParseException
          raise ExpressionError.new("Error: JSON.parse argument 1 must be valid JSON")
        end
      end)

      json["stringify"] = BuiltinFunction.new("JSON.stringify", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "JSON.stringify")
        assert_builtin_arity(args, 1, "JSON.stringify")

        value = args[0]
        if value.is_a?(UndefinedValue) || value.is_a?(BuiltinFunction)
          UNDEFINED.as(Value)
        else
          io = IO::Memory.new
          json_stringify_into(io, value, Set(UInt64).new, 0)
          io.to_s.as(Value)
        end
      end)

      json
    end

    private def build_math_object : Hash(String, Value)
      math = Hash(String, Value).new

      math["E"] = 2.718281828459045
      math["LN10"] = 2.302585092994046
      math["LN2"] = 0.6931471805599453
      math["LOG10E"] = 0.4342944819032518
      math["LOG2E"] = 1.4426950408889634
      math["PI"] = 3.141592653589793
      math["SQRT1_2"] = 0.7071067811865476
      math["SQRT2"] = 1.4142135623730951

      math["sqrt"] = BuiltinFunction.new("Math.sqrt", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.sqrt")
        Math.sqrt(unary_number_arg_f64(args, "Math.sqrt")).as(Value)
      end)

      math["acos"] = BuiltinFunction.new("Math.acos", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.acos")
        Math.acos(unary_number_arg_f64(args, "Math.acos")).as(Value)
      end)

      math["asin"] = BuiltinFunction.new("Math.asin", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.asin")
        Math.asin(unary_number_arg_f64(args, "Math.asin")).as(Value)
      end)

      math["atan"] = BuiltinFunction.new("Math.atan", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.atan")
        Math.atan(unary_number_arg_f64(args, "Math.atan")).as(Value)
      end)

      math["atan2"] = BuiltinFunction.new("Math.atan2", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.atan2")
        y, x = binary_number_args_f64(args, "Math.atan2")
        Math.atan2(y, x).as(Value)
      end)

      math["cos"] = BuiltinFunction.new("Math.cos", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.cos")
        Math.cos(unary_number_arg_f64(args, "Math.cos")).as(Value)
      end)

      math["exp"] = BuiltinFunction.new("Math.exp", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.exp")
        Math.exp(unary_number_arg_f64(args, "Math.exp")).as(Value)
      end)

      math["log"] = BuiltinFunction.new("Math.log", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.log")
        Math.log(unary_number_arg_f64(args, "Math.log")).as(Value)
      end)

      math["abs"] = BuiltinFunction.new("Math.abs", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.abs")
        assert_builtin_arity(args, 1, "Math.abs")
        value = number_argument(args[0], "Math.abs", 0)
        if value.is_a?(Int32)
          value.abs.as(Value)
        else
          value.abs.to_f64.as(Value)
        end
      end)

      math["ceil"] = BuiltinFunction.new("Math.ceil", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.ceil")
        unary_number_arg_f64(args, "Math.ceil").ceil.to_i32.as(Value)
      end)

      math["floor"] = BuiltinFunction.new("Math.floor", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.floor")
        unary_number_arg_f64(args, "Math.floor").floor.to_i32.as(Value)
      end)

      math["round"] = BuiltinFunction.new("Math.round", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.round")
        unary_number_arg_f64(args, "Math.round").round.to_i32.as(Value)
      end)

      math["trunc"] = BuiltinFunction.new("Math.trunc", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.trunc")
        unary_number_arg_f64(args, "Math.trunc").trunc.to_i32.as(Value)
      end)

      math["sign"] = BuiltinFunction.new("Math.sign", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.sign")
        assert_builtin_arity(args, 1, "Math.sign")

        value = unary_number_arg_f64(args, "Math.sign")
        if value < 0
          -1.as(Value)
        elsif value > 0
          1.as(Value)
        else
          0.as(Value)
        end
      end)

      math["pow"] = BuiltinFunction.new("Math.pow", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.pow")
        base, exponent = binary_number_args_f64(args, "Math.pow")
        (base ** exponent).as(Value)
      end)

      math["sin"] = BuiltinFunction.new("Math.sin", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.sin")
        Math.sin(unary_number_arg_f64(args, "Math.sin")).as(Value)
      end)

      math["tan"] = BuiltinFunction.new("Math.tan", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.tan")
        Math.tan(unary_number_arg_f64(args, "Math.tan")).as(Value)
      end)

      math["max"] = BuiltinFunction.new("Math.max", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.max")
        if args.empty?
          (-Float64::INFINITY).as(Value)
        else
          max_value = number_argument(args[0], "Math.max", 0).to_f64
          index = 1
          while index < args.size
            value = number_argument(args[index], "Math.max", index).to_f64
            max_value = value if value > max_value
            index += 1
          end
          max_value.as(Value)
        end
      end)

      math["min"] = BuiltinFunction.new("Math.min", ->(receiver : Value, args : Array(Value)) do
        assert_builtin_receiver_object(receiver, "Math.min")
        if args.empty?
          Float64::INFINITY.as(Value)
        else
          min_value = number_argument(args[0], "Math.min", 0).to_f64
          index = 1
          while index < args.size
            value = number_argument(args[index], "Math.min", index).to_f64
            min_value = value if value < min_value
            index += 1
          end
          min_value.as(Value)
        end
      end)

      math
    end

    private def assert_builtin_receiver_object(receiver : Value, method_name : String)
      return if receiver.is_a?(Hash(String, Value))

      raise ExpressionError.new("Error: #{method_name} receiver must be an object")
    end

    private def assert_builtin_arity(args : Array(Value), expected : Int32, method_name : String)
      return if args.size == expected

      raise ExpressionError.new("Error: #{method_name} expects #{expected} arguments but got #{args.size}")
    end

    private def assert_builtin_arity_between(args : Array(Value), min : Int32, max : Int32, method_name : String)
      return if args.size >= min && args.size <= max

      raise ExpressionError.new("Error: #{method_name} expects between #{min} and #{max} arguments but got #{args.size}")
    end

    private def number_argument(value : Value, method_name : String, index : Int32) : Number
      return value if value.is_a?(Int32)
      return value if value.is_a?(Float64)

      raise ExpressionError.new("Error: #{method_name} argument #{index + 1} must be a number")
    end

    private def unary_number_arg_f64(args : Array(Value), method_name : String) : Float64
      assert_builtin_arity(args, 1, method_name)
      number_argument(args[0], method_name, 0).to_f64
    end

    private def binary_number_args_f64(args : Array(Value), method_name : String) : Tuple(Float64, Float64)
      assert_builtin_arity(args, 2, method_name)
      {
        number_argument(args[0], method_name, 0).to_f64,
        number_argument(args[1], method_name, 1).to_f64,
      }
    end

    private def parse_int_digit_value(char : Char) : Int32?
      if char.ascii_number?
        return char.ord - '0'.ord
      end

      lower = char.downcase
      return nil unless lower >= 'a' && lower <= 'z'

      lower.ord - 'a'.ord + 10
    end

    private def coerce_to_number_for_globals(value : Value) : Number
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

      if value.is_a?(Array(Value))
        return coerce_to_number_for_globals(array_to_global_number_string(value))
      end

      Float64::NAN
    end

    private def to_primitive_string_for_globals(value : Value) : String
      return "null" if value.nil?
      return "undefined" if value.is_a?(UndefinedValue)

      if value.is_a?(Bool)
        return value ? "true" : "false"
      end

      if value.is_a?(Array(Value))
        return array_to_global_number_string(value)
      end

      if value.is_a?(Hash(String, Value))
        return "[object Object]"
      end

      if value.is_a?(BuiltinFunction)
        return "function"
      end

      value.to_s
    end

    private def array_to_global_number_string(values : Array(Value)) : String
      values.map { |item| global_array_element_to_string(item) }.join(",")
    end

    private def global_array_element_to_string(value : Value) : String
      return "" if value.nil? || value.is_a?(UndefinedValue)

      if value.is_a?(Array(Value))
        return array_to_global_number_string(value)
      end

      if value.is_a?(Hash(String, Value))
        return "[object Object]"
      end

      if value.is_a?(BuiltinFunction)
        return "function"
      end

      if value.is_a?(Bool)
        return value ? "true" : "false"
      end

      value.to_s
    end

    private def json_any_to_value(value : ::JSON::Any) : Value
      raw = value.raw

      case raw
      when Nil
        nil
      when Bool
        raw
      when String
        raw
      when Int32
        raw
      when Int64
        int64_to_js_number(raw)
      when UInt64
        uint64_to_js_number(raw)
      when Float64
        raw
      when Array(::JSON::Any)
        values = Array(Value).new(raw.size)
        raw.each do |item|
          values << json_any_to_value(item)
        end
        values
      when Hash(String, ::JSON::Any)
        object = Hash(String, Value).new
        raw.each do |key, property_value|
          object[key] = json_any_to_value(property_value)
        end
        object
      else
        raise ExpressionError.new("Error: JSON.parse produced unsupported value")
      end
    end

    private def int64_to_js_number(value : Int64) : Number
      if value <= Int32::MAX && value >= Int32::MIN
        value.to_i32
      else
        value.to_f64
      end
    end

    private def uint64_to_js_number(value : UInt64) : Number
      if value <= Int32::MAX
        value.to_i32
      else
        value.to_f64
      end
    end

    private def json_stringify_into(io : IO, value : Value, visited : Set(UInt64), depth : Int32)
      if depth > MAX_JSON_STRINGIFY_DEPTH
        raise ExpressionError.new("Error: JSON.stringify nested structure exceeds maximum depth")
      end

      case value
      when Nil
        io << "null"
      when UndefinedValue, BuiltinFunction
        io << "null"
      when Bool, Int32
        io << value.to_s
      when Float64
        io << (value.finite? ? value.to_s : "null")
      when String
        io << value.to_json
      when Array(Value)
        cycle_checked_json_stringify(value.object_id, visited, "JSON.stringify cannot serialize circular arrays") do
          io << '['
          first = true
          value.each do |item|
            io << ',' unless first
            first = false
            json_stringify_into(io, item, visited, depth + 1)
          end
          io << ']'
        end
      when Hash(String, Value)
        cycle_checked_json_stringify(value.object_id, visited, "JSON.stringify cannot serialize circular objects") do
          io << '{'
          first = true
          value.each do |key, property_value|
            next if property_value.is_a?(UndefinedValue) || property_value.is_a?(BuiltinFunction)

            io << ',' unless first
            first = false
            io << key.to_json << ':'
            json_stringify_into(io, property_value, visited, depth + 1)
          end
          io << '}'
        end
      else
        raise ExpressionError.new("Error: JSON.stringify does not support this value")
      end
    end

    private def cycle_checked_json_stringify(object_id : UInt64, visited : Set(UInt64), message : String, &)
      if visited.includes?(object_id)
        raise ExpressionError.new("Error: #{message}")
      end

      visited.add(object_id)
      begin
        yield
      ensure
        visited.delete(object_id)
      end
    end

    private def incremented_value(value : Value, operator : String) : Value
      if value.is_a?(Int32)
        return operator == "++" ? value + 1 : value - 1
      end

      if value.is_a?(Float64)
        return operator == "++" ? value + 1.0 : value - 1.0
      end

      raise ExpressionError.new("Error: operator '#{operator}' requires numeric operand")
    end

    private def apply_compound_assignment_operator(left : Value, right : Value, operator : String) : Value
      case operator
      when "+="
        if left.is_a?(String) || right.is_a?(String)
          return compound_value_to_string(left) + compound_value_to_string(right)
        end

        left_number = compound_number_operand(left, "+")
        right_number = compound_number_operand(right, "+")

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number + right_number
        else
          left_number.to_f64 + right_number.to_f64
        end
      when "-="
        left_number = compound_number_operand(left, "-")
        right_number = compound_number_operand(right, "-")

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number - right_number
        else
          left_number.to_f64 - right_number.to_f64
        end
      when "*="
        left_number = compound_number_operand(left, "*")
        right_number = compound_number_operand(right, "*")

        if left_number.is_a?(Int32) && right_number.is_a?(Int32)
          left_number * right_number
        else
          left_number.to_f64 * right_number.to_f64
        end
      when "/="
        left_number = compound_number_operand(left, "/")
        right_number = compound_number_operand(right, "/")

        if right_number.to_f64 == 0.0
          raise ExpressionError.new("Error: division by zero")
        end

        left_number.to_f64 / right_number.to_f64
      else
        raise ExpressionError.new("Error: invalid assignment operator '#{operator}'")
      end
    end

    private def compound_number_operand(value : Value, operator : String) : Number
      if value.is_a?(Int32)
        return value
      end

      if value.is_a?(Float64)
        return value
      end

      raise ExpressionError.new("Error: operator '#{operator}' requires numeric operands")
    end

    private def compound_value_to_string(value : Value) : String
      return "null" if value.nil?
      return "undefined" if value.is_a?(UndefinedValue)

      if value.is_a?(String)
        value
      elsif value.is_a?(Array)
        "[#{value.map { |item| compound_value_to_string(item) }.join(", ")}]"
      elsif value.is_a?(Hash(String, Value))
        properties = value.map do |key, property_value|
          "\"#{escape_string(key)}\": #{compound_value_to_string(property_value)}"
        end
        "{#{properties.join(", ")}}"
      else
        value.to_s
      end
    end
  end
end
