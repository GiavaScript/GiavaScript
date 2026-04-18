module Ls
  VERSION = "0.1.0"

  struct VoidValue
    def to_s(io : IO)
      io << "void"
    end
  end

  VOID = VoidValue.new

  alias Number = Int32 | Float64
  alias Value = Number | String | Nil | VoidValue
end

require "./ls/string_literal_parser"
require "./ls/expression_parser"
require "./ls/statement_splitter"
require "./ls/function_runtime"
require "./ls/interpreter"
