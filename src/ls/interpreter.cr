module Ls
  class Interpreter
    VAR_REGEX = /^\$[A-Za-z_][A-Za-z0-9_]*$/

    def initialize
      @env = Hash(String, Value).new
      @function_runtime = FunctionRuntime.new
    end

    def repl(input : IO = STDIN, output : IO = STDOUT)
      output.puts "LennaScript REPL"
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
      if stmt.starts_with?("fun ")
        begin
          @function_runtime.define_function(stmt)
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid function definition"
        end
      end

      if match = stmt.match(/^return(?:\s+(.+))?$/m)
        if inside_function
          return_value_expr = match[1]?
          value = return_value_expr ? eval_rhs(return_value_expr.strip, env) : nil
          raise FunctionRuntime::ReturnSignal.new(value)
        end

        return "Error: return can only be used inside functions"
      end

      if match = stmt.match(/^(\$[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/)
        var_name = match[1]
        rhs = match[2].strip

        begin
          value = eval_rhs(rhs, env)
          if value.nil?
            return "Error: function used in assignment must return a value"
          end
          env[var_name] = value
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid right-hand side '#{rhs}'"
        end
      end

      if stmt.matches?(VAR_REGEX)
        if val = env[stmt]?
          return "#{stmt} = #{value_to_s(val)}"
        end
        return "Error: variable '#{stmt}' does not exist"
      end

      begin
        value = eval_rhs(stmt, env)
        return nil if value.nil?
        value_to_s(value)
      rescue ex : ExpressionError
        ex.message || "Error: invalid right-hand side '#{stmt}'"
      end
    end

    private def eval_rhs(rhs : String, env : Hash(String, Value)) : Value
      ExpressionParser.new(rhs, env, ->(name : String, args : Array(Value)) { call_function(name, args, env) }).parse
    end

    private def call_function(name : String, args : Array(Value), env : Hash(String, Value)) : Value
      @function_runtime.invoke_function(name, args, env) do |stmt, local_env, inside_function|
        eval_statement(stmt, local_env, inside_function)
      end
    end

    private def value_to_s(value : Value) : String
      return "void" if value.nil?

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
