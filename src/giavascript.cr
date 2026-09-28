require "json"
require "set"
require "time"
require "http/client"

module GiavaScript
  VERSION = "0.7.0"

  class ExpressionError < Exception
  end

  class StatementError < ExpressionError
    getter offset : Int32

    def initialize(message : String, @offset : Int32)
      super(message)
    end
  end

  struct Diagnostic
    enum Severity
      Output
      Error
    end

    getter message : String
    getter severity : Severity
    getter line : Int32?
    getter column : Int32?
    getter length : Int32?

    def initialize(@message : String, @severity : Severity, @line : Int32? = nil, @column : Int32? = nil, @length : Int32? = nil)
    end

    def self.output(message : String) : Diagnostic
      new(message, Severity::Output)
    end

    def self.error(message : String, line : Int32? = nil, column : Int32? = nil, length : Int32? = nil) : Diagnostic
      new(message, Severity::Error, line, column, length)
    end

    def error? : Bool
      severity.error?
    end

    def to_display(io : IO, path : String, source : String)
      line_number = line
      column_number = column

      unless line_number && column_number
        io.puts "#{path}: #{@message}"
        return
      end

      message = @message
      message = message["Error: ".size..] if message.starts_with?("Error: ")

      source_line = (source.lines[line_number - 1]? || "").chomp
      available = source_line.size - (column_number - 1)
      caret_length = length || available
      caret_length = available if caret_length > available
      caret_length = 1 if caret_length < 1

      gutter = line_number.to_s.size
      io.puts "error: #{message}"
      io.puts " --> #{path}:#{line_number}:#{column_number}"
      io.puts "#{" " * gutter} |"
      io.puts "#{line_number} | #{source_line}"
      io.puts "#{" " * gutter} | #{" " * (column_number - 1)}#{"^" * caret_length}"
    end
  end

  struct UndefinedValue
    def to_s(io : IO)
      io << "undefined"
    end
  end

  UNDEFINED = UndefinedValue.new

  alias Number = Int32 | Float64

  class BuiltinFunction
  end

  class Environment
  end

  class UserFunction
    getter name : String?
    getter parameters : Array(String)
    getter rest_parameter : String?
    getter body_source : String
    getter closure : Environment
    getter parameter_defaults : Hash(String, String)

    def initialize(@name : String?, @parameters : Array(String), @body_source : String, @closure : Environment, @rest_parameter : String? = nil, @parameter_defaults : Hash(String, String) = {} of String => String)
    end

    def to_s(io : IO)
      io << "function"
    end
  end

  class DateValue
    getter timestamp_ms : Float64

    def initialize(@timestamp_ms : Float64)
    end

    def to_s(io : IO)
      io << Time.unix_ms(@timestamp_ms.round.to_i64).to_s("%Y-%m-%dT%H:%M:%S.%3N") << "Z"
    end
  end

  class RegExpValue
    getter pattern : String
    getter flags : String
    getter compiled_regex : Regex

    def initialize(@pattern : String, @flags : String)
      compile_options = Regex::CompileOptions::None
      compile_options |= Regex::CompileOptions::IGNORE_CASE if @flags.includes?('i')
      compile_options |= Regex::CompileOptions::MULTILINE if @flags.includes?('m')
      compile_options |= Regex::CompileOptions::DOTALL if @flags.includes?('s')

      @compiled_regex = Regex.new(@pattern, compile_options)
    end

    def global? : Bool
      @flags.includes?('g')
    end

    def ignore_case? : Bool
      @flags.includes?('i')
    end

    def multiline? : Bool
      @flags.includes?('m')
    end

    def dot_all? : Bool
      @flags.includes?('s')
    end

    def unicode? : Bool
      @flags.includes?('u')
    end

    def to_s(io : IO)
      io << "/" << @pattern << "/" << @flags
    end
  end

  class ErrorValue
    getter message : String
    getter name : String
    getter stack : String

    def initialize(@message : String, @name : String = "Error")
      @stack = generate_stack
    end

    def to_s(io : IO)
      io << @name << ": " << @message
    end

    private def generate_stack : String
      String.build do |io|
        io << @name << ": " << @message
        caller.each do |frame|
          io << '\n' << "    at " << frame
        end
      end
    end
  end

  alias Value = Number | Bool | String | Nil | UndefinedValue | Array(Value) | Hash(String, Value) | BuiltinFunction | UserFunction | DateValue | RegExpValue | ErrorValue
end

require "./giavascript/string_literal_parser"
require "./giavascript/template_literal_parser"
require "./giavascript/comment_stripper"
require "./giavascript/tokenizer"
require "./giavascript/ast"
require "./giavascript/expression_parser"
require "./giavascript/runtime_types"
require "./giavascript/environment"
require "./giavascript/expression_evaluator"
require "./giavascript/statement_parser_shared"
require "./giavascript/for_statement_parser"
require "./giavascript/if_statement_parser"
require "./giavascript/switch_statement_parser"
require "./giavascript/while_statement_parser"
require "./giavascript/try_statement_parser"
require "./giavascript/statement_tokenizer"
require "./giavascript/interpreter_builtins"
require "./giavascript/interpreter"
