require "json"
require "set"
require "time"

module GiavaScript
  VERSION = "0.4.0"

  class ExpressionError < Exception
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

    def initialize(@name : String?, @parameters : Array(String), @body_source : String, @closure : Environment, @rest_parameter : String? = nil)
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

    def initialize(@message : String, @name : String = "Error", stack : String? = nil)
      @stack = stack || generate_stack
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
require "./giavascript/statement_splitter"
require "./giavascript/function_runtime"
require "./giavascript/interpreter_builtins"
require "./giavascript/interpreter"
