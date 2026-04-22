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

      if match = stmt.match(/^var\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/)
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

      if match = stmt.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/)
        var_name = match[1]
        rhs = match[2].strip

        unless env.has_key?(var_name)
          return "Error: variable '#{var_name}' does not exist"
        end

        begin
          value = eval_rhs(rhs, env)
          env[var_name] = value
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid right-hand side '#{rhs}'"
        end
      end

      if stmt.matches?(IDENTIFIER_REGEX)
        if env.has_key?(stmt)
          return "#{stmt} = #{value_to_s(env[stmt])}"
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
      ExpressionParser.new(rhs, env, ->(name : String, args : Array(Value)) { call_function(name, args, env) }).parse
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

      if value.is_a?(String)
        return !value.empty?
      end

      if value.is_a?(Int32)
        return value != 0
      end

      value != 0.0
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
