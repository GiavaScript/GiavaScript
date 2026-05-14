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

  alias Value = Number | Bool | String | Nil | UndefinedValue | Array(Value) | Hash(String, Value) | BuiltinFunction
end

require "./giavascript/string_literal_parser"
require "./giavascript/template_literal_parser"
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
