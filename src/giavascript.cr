require "json"
require "set"

module GiavaScript
  VERSION = "0.1.0"

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
    getter body_source : String
    getter closure : Environment

    def initialize(@name : String?, @parameters : Array(String), @body_source : String, @closure : Environment)
    end

    def to_s(io : IO)
      io << "function"
    end
  end

  alias Value = Number | Bool | String | Nil | UndefinedValue | Array(Value) | Hash(String, Value) | BuiltinFunction | UserFunction
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
require "./giavascript/for_statement_parser"
require "./giavascript/if_statement_parser"
require "./giavascript/switch_statement_parser"
require "./giavascript/while_statement_parser"
require "./giavascript/statement_tokenizer"
require "./giavascript/statement_splitter"
require "./giavascript/function_runtime"
require "./giavascript/interpreter"
