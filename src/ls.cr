module Ls
  VERSION = "0.1.0"
  alias Number = Int32 | Float64
end

require "./ls/expression_parser"
require "./ls/interpreter"
