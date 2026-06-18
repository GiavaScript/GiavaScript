module GiavaScript
  class Interpreter
    include InterpreterBuiltins

    IDENTIFIER_REGEX             = /^[A-Za-z_][A-Za-z0-9_]*$/
    MAX_JSON_STRINGIFY_DEPTH     = 1_000
    MAX_EXPRESSION_CACHE_SIZE    = 8_192
    MAX_RAW_STATEMENT_CACHE_SIZE = 8_192
    MAX_EVALUATOR_CACHE_SIZE     = 1_024

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

    class ThrowSignal < Exception
      getter value : Value

      def initialize(@value : Value)
        super("throw")
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

    class UnsupportedDeclarationRawStatement < CompiledRawStatement
      getter keyword : String

      def initialize(@keyword : String)
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
        StatementSplitter.new(CommentStripper.strip(input)).split
      rescue ex : ExpressionError
        return [ex.message || "Error: invalid statement"]
      end

      statements.each do |stmt|
        begin
          message = eval_statement(stmt, @env, false, false, false)
          messages << message if message
        rescue ex : ThrowSignal
          messages << "Error: uncaught #{value_to_s(ex.value)}"
        end
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

      if starts_with_keyword?(stmt, "try")
        return eval_try_statement(stmt, env, inside_function, inside_loop, inside_switch)
      end

      if match = stmt.match(/^throw(?:\s+([\s\S]+))?$/)
        throw_source = match[1]?
        value = throw_source ? eval_rhs(throw_source.strip, env) : UNDEFINED
        raise ThrowSignal.new(value)
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

      if keyword = unsupported_declaration_keyword(stmt)
        return "Error: unsupported declaration '#{keyword}'"
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

      if match = stmt.match(/^var\s+([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*([\s\S]+)$/)
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
        ->(name : String) { resolve_function_reference(name, env) },
        ->(function_value : UserFunction, args : Array(Value)) { invoke_user_function(function_value, args).as(Value) }
      )
      @expression_evaluator_cache[key] = created
      created
    end

    private def resolve_function_reference(name : String, env : Environment) : BuiltinFunction?
      return nil unless @function_runtime.function_defined?(name)

      callback_arity_resolver = -> { @function_runtime.function_parameter_count(name) }
      BuiltinFunction.new(
        name,
        ->(_receiver : Value, args : Array(Value)) { call_function(name, args, env).as(Value) },
        callback_arity_resolver
      )
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
      return nil unless stmt.includes?('=')

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

      statement = parsed_for.statement
      case statement
      when ForStatement
        eval_for_ast(statement, env, inside_function, inside_loop, inside_switch)
      when ForOfStatement
        eval_for_of_ast(statement, env, inside_function, inside_loop, inside_switch)
      else
        "Error: invalid for statement"
      end
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

    private def eval_for_of_ast(for_of : ForOfStatement, env : Environment, inside_function : Bool, _inside_loop : Bool, inside_switch : Bool = false) : String?
      begin
        iterable_value = evaluate_expression(for_of.iterable, env)

        case iterable_value
        when Array(Value)
          iterable_value.each do |element|
            env[for_of.var_name] = element

            begin
              body_message = eval_statement_node(for_of.body, env, inside_function, true, inside_switch)
              if body_message && body_message.starts_with?("Error:")
                return body_message
              end
            rescue ContinueSignal
            rescue BreakSignal
              break
            end
          end
        when String
          iterable_value.each_char do |ch|
            env[for_of.var_name] = ch.to_s

            begin
              body_message = eval_statement_node(for_of.body, env, inside_function, true, inside_switch)
              if body_message && body_message.starts_with?("Error:")
                return body_message
              end
            rescue ContinueSignal
            rescue BreakSignal
              break
            end
          end
        else
          return "Error: for...of requires an iterable (array or string)"
        end

        nil
      rescue ex : ExpressionError
        ex.message || "Error: invalid for...of statement"
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

    private def eval_try_statement(stmt : String, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      parsed_try = begin
        TryStatementParser.new(stmt).parse_from
      rescue ex : ExpressionError
        return ex.message || "Error: invalid try statement"
      end

      eval_try_ast(parsed_try.statement, env, inside_function, inside_loop, inside_switch)
    end

    private def eval_try_ast(try_statement : TryStatement, env : Environment, inside_function : Bool, inside_loop : Bool, inside_switch : Bool = false) : String?
      message = nil.as(String?)

      begin
        begin
          message = eval_statement_node(try_statement.try_branch, env, inside_function, inside_loop, inside_switch)
        rescue ex : ThrowSignal
          catch_branch = try_statement.catch_branch
          raise ex unless catch_branch

          if catch_parameter = try_statement.catch_parameter
            previous_local = env.local_lookup(catch_parameter)
            env.set_local(catch_parameter, ex.value)

            begin
              message = eval_statement_node(catch_branch, env, inside_function, inside_loop, inside_switch)
            ensure
              if previous_local[:found]
                env.set_local(catch_parameter, previous_local[:value])
              else
                env.delete_local(catch_parameter)
              end
            end
          else
            message = eval_statement_node(catch_branch, env, inside_function, inside_loop, inside_switch)
          end
        end
      ensure
        if finally_branch = try_statement.finally_branch
          final_message = eval_statement_node(finally_branch, env, inside_function, inside_loop, inside_switch)
          if final_message && final_message.starts_with?("Error:")
            message = final_message
          elsif message.nil? && final_message
            message = final_message
          end
        end
      end

      message
    rescue ex : ExpressionError
      ex.message || "Error: invalid try statement"
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
      when ForOfStatement
        eval_for_of_ast(statement, env, inside_function, inside_loop, inside_switch)
      when WhileStatement
        eval_while_ast(statement, env, inside_function, inside_loop, inside_switch)
      when DoWhileStatement
        eval_do_while_ast(statement, env, inside_function, inside_loop, inside_switch)
      when SwitchStatement
        eval_switch_ast(statement, env, inside_function, inside_loop, inside_switch)
      when TryStatement
        eval_try_ast(statement, env, inside_function, inside_loop, inside_switch)
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
      when UnsupportedDeclarationRawStatement
        "Error: unsupported declaration '#{compiled.keyword}'"
      end
    end

    private def compiled_raw_statement(source : String) : CompiledRawStatement
      key = source.strip
      cached = @raw_statement_cache[key]?
      return cached if cached

      compiled = if key.starts_with?("function ") || starts_with_keyword?(key, "if") || starts_with_keyword?(key, "for") ||
                    starts_with_keyword?(key, "while") || starts_with_keyword?(key, "do") || starts_with_keyword?(key, "switch") ||
                    starts_with_keyword?(key, "try") || starts_with_keyword?(key, "throw") ||
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
                 elsif match = key.match(/^var\s+([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)\s*([\s\S]+)$/)
                   name = match[1]
                   rhs_source = match[2].strip
                   begin
                     rhs = parsed_expression(rhs_source)
                     VarRawStatement.new(name, rhs, rhs_source)
                   rescue
                     FallbackRawStatement.new(source)
                   end
                 elsif keyword = unsupported_declaration_keyword(key)
                   UnsupportedDeclarationRawStatement.new(keyword)
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

      @raw_statement_cache.clear if @raw_statement_cache.size >= MAX_RAW_STATEMENT_CACHE_SIZE
      @raw_statement_cache[key] = compiled

      compiled
    end

    private def truthy?(value : Value) : Bool
      return false if value.nil?
      return false if value.is_a?(UndefinedValue)
      return value if value.is_a?(Bool)
      return !value.empty? if value.is_a?(String)
      return value != 0 if value.is_a?(Int32)
      return value != 0.0 if value.is_a?(Float64)

      true
    end

    private def strict_equals_values?(left : Value, right : Value) : Bool
      if left.is_a?(Int32) || left.is_a?(Float64)
        return false unless right.is_a?(Int32) || right.is_a?(Float64)
        return false if left.to_f64.nan? || right.to_f64.nan?
        return left.to_f64 == right.to_f64
      end

      return right.is_a?(String) && left == right if left.is_a?(String)
      return right.is_a?(Bool) && left == right if left.is_a?(Bool)
      return right.nil? if left.nil?
      return right.is_a?(UndefinedValue) if left.is_a?(UndefinedValue)
      return right.is_a?(Array(Value)) && left.object_id == right.object_id if left.is_a?(Array(Value))
      return right.is_a?(Hash(String, Value)) && left.object_id == right.object_id if left.is_a?(Hash(String, Value))
      return right.is_a?(BuiltinFunction) && left.object_id == right.object_id if left.is_a?(BuiltinFunction)
      return right.is_a?(UserFunction) && left.object_id == right.object_id if left.is_a?(UserFunction)
      return right.is_a?(DateValue) && left.object_id == right.object_id if left.is_a?(DateValue)
      return right.is_a?(RegExpValue) && left.object_id == right.object_id if left.is_a?(RegExpValue)
      return right.is_a?(ErrorValue) && left.object_id == right.object_id if left.is_a?(ErrorValue)

      false
    end

    private def starts_with_keyword?(source : String, keyword : String) : Bool
      return false unless source.starts_with?(keyword)

      next_char = source[keyword.size]?
      next_char.nil? || !(next_char.ascii_letter? || next_char.ascii_number? || next_char == '_')
    end

    private def unsupported_declaration_keyword(source : String) : String?
      return "let" if starts_with_keyword?(source, "let")
      return "const" if starts_with_keyword?(source, "const")

      nil
    end

    private def call_function(name : String, args : Array(Value), env : Environment) : Value
      @function_runtime.invoke_function(name, args, env) do |stmt, local_env, inside_function, inside_loop|
        eval_statement(stmt, local_env, inside_function, inside_loop)
      end
    end

    private def invoke_user_function(function_value : UserFunction, args : Array(Value)) : Value
      if args.size != function_value.parameters.size
        display_name = function_value.name || "anonymous"
        raise ExpressionError.new("Error: function '#{display_name}' expects #{function_value.parameters.size} arguments but got #{args.size}")
      end

      local_env = Environment.new(function_value.closure)
      if function_name = function_value.name
        local_env[function_name] = function_value
      end

      function_value.parameters.each_with_index do |param, index|
        local_env[param] = args[index]
      end

      statements = StatementSplitter.new(function_value.body_source).split

      begin
        statements.each do |stmt|
          eval_statement(stmt, local_env, true, false)
        end
      rescue ex : FunctionRuntime::ReturnSignal
        return ex.value
      end

      UNDEFINED
    end

    private def value_to_s(value : Value) : String
      return "null" if value.nil?
      return "undefined" if value.is_a?(UndefinedValue)

      if value.is_a?(Int32) || value.is_a?(Float64)
        return format_number_for_output(value)
      end

      if value.is_a?(String)
        "\"#{escape_string(value)}\""
      elsif value.is_a?(Array)
        String.build do |io|
          io << '['
          value.each_with_index do |item, i|
            io << ", " if i > 0
            io << value_to_s(item)
          end
          io << ']'
        end
      elsif value.is_a?(Hash(String, Value))
        String.build do |io|
          io << '{'
          first = true
          value.each do |key, property_value|
            first ? (first = false) : (io << ", ")
            io << '"' << escape_string(key) << "\": " << value_to_s(property_value)
          end
          io << '}'
        end
      elsif value.is_a?(RegExpValue)
        value.to_s
      elsif value.is_a?(ErrorValue)
        value.to_s
      else
        value.to_s
      end
    end

    private def escape_string(value : String) : String
      String.build do |io|
        value.each_char do |char|
          case char
          when '\\' then io << "\\\\"
          when '"'  then io << "\\\""
          when '\n' then io << "\\n"
          when '\t' then io << "\\t"
          else           io << char
          end
        end
      end
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
      when UndefinedValue, BuiltinFunction, UserFunction, RegExpValue, ErrorValue
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
            next if property_value.is_a?(UndefinedValue) || property_value.is_a?(BuiltinFunction) || property_value.is_a?(UserFunction) || property_value.is_a?(RegExpValue) || property_value.is_a?(ErrorValue)

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
      elsif value.is_a?(RegExpValue)
        value.to_s
      elsif value.is_a?(ErrorValue)
        value.to_s
      else
        value.to_s
      end
    end
  end
end
