module Ls
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

require "./ls/string_literal_parser"
require "./ls/tokenizer"
require "./ls/ast"
require "./ls/expression_parser"
require "./ls/runtime_types"
require "./ls/expression_evaluator"
require "./ls/for_statement_parser"
require "./ls/if_statement_parser"
require "./ls/statement_tokenizer"
require "./ls/statement_splitter"
require "./ls/function_runtime"
require "./ls/interpreter"
