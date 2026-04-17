module Ls
  class Interpreter
    VAR_REGEX = /^\$[A-Za-z_][A-Za-z0-9_]*$/

    def initialize
      @env = Hash(String, Value).new
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
      statements = input.split(';').map(&.strip).reject(&.empty?)
      statements.each do |stmt|
        message = eval_statement(stmt)
        messages << message if message
      end
      messages
    end

    private def eval_statement(stmt : String) : String?
      if match = stmt.match(/^(\$[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$/)
        var_name = match[1]
        rhs = match[2].strip

        begin
          value = eval_rhs(rhs)
          @env[var_name] = value
          return nil
        rescue ex : ExpressionError
          return ex.message || "Error: invalid right-hand side '#{rhs}'"
        end
      end

      if stmt.matches?(VAR_REGEX)
        if val = @env[stmt]?
          return "#{stmt} = #{value_to_s(val)}"
        end
        return "Error: variable '#{stmt}' does not exist"
      end

      begin
        value = eval_rhs(stmt)
        value_to_s(value)
      rescue ex : ExpressionError
        ex.message || "Error: invalid right-hand side '#{stmt}'"
      end
    end

    private def eval_rhs(rhs : String) : Value
      ExpressionParser.new(rhs, @env).parse
    end

    private def value_to_s(value : Value) : String
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
