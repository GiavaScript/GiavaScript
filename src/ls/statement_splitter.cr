module Ls
  class StatementSplitter
    def initialize(@input : String)
    end

    def split : Array(String)
      statements = [] of String
      tokenizer = StatementTokenizer.new(@input)

      while statement = tokenizer.next_statement
        statements << statement
      end

      statements
    end
  end
end
