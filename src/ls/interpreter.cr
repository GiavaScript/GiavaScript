module Ls
  class Interpreter
    VAR_REGEX = /^\$[A-Za-z_][A-Za-z0-9_]*$/

    def initialize
      @env = Hash(String, Number).new
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
        value = eval_rhs(rhs)
        return value.is_a?(String) ? value : (@env[var_name] = value; nil)
      end

      if stmt.matches?(VAR_REGEX)
        if val = @env[stmt]?
          return "#{stmt} = #{number_to_s(val)}"
        end
        return "Error: variable '#{stmt}' does not exist"
      end

      value = eval_rhs(stmt)
      value.is_a?(String) ? value : number_to_s(value)
    end

    private def eval_rhs(rhs : String) : Number | String
      ExpressionParser.new(rhs, @env).parse
    end

    private def number_to_s(number : Number) : String
      number.to_s
    end
  end
end
