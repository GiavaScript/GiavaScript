module Ls
  abstract class Expr
  end

  class LiteralExpr < Expr
    getter value : Value

    def initialize(@value : Value)
    end
  end

  class VariableExpr < Expr
    getter name : String

    def initialize(@name : String)
    end
  end

  class UnaryExpr < Expr
    getter operator : Tokenizer::TokenKind
    getter operand : Expr

    def initialize(@operator : Tokenizer::TokenKind, @operand : Expr)
    end
  end

  class BinaryExpr < Expr
    getter left : Expr
    getter operator : Tokenizer::TokenKind
    getter right : Expr

    def initialize(@left : Expr, @operator : Tokenizer::TokenKind, @right : Expr)
    end
  end

  class FunctionCallExpr < Expr
    getter callee : Expr
    getter args : Array(Expr)

    def initialize(@callee : Expr, @args : Array(Expr))
    end
  end

  class ArrayLiteral < Expr
    getter elements : Array(Expr)

    def initialize(@elements : Array(Expr))
    end
  end

  record ObjectProperty, key : String, value : Expr

  class ObjectLiteral < Expr
    getter properties : Array(ObjectProperty)

    def initialize(@properties : Array(ObjectProperty))
    end
  end

  class IndexExpr < Expr
    getter target : Expr
    getter index : Expr

    def initialize(@target : Expr, @index : Expr)
    end
  end

  class PropertyAccessExpr < Expr
    getter target : Expr
    getter property : String

    def initialize(@target : Expr, @property : String)
    end
  end
end
