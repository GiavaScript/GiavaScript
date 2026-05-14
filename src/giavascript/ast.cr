module GiavaScript
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

  abstract class Statement
  end

  class RawStatement < Statement
    getter source : String

    def initialize(@source : String)
    end
  end

  class BlockStatement < Statement
    getter statements : Array(Statement)

    def initialize(@statements : Array(Statement))
    end
  end

  class IfStatement < Statement
    getter condition : Expr
    getter then_branch : Statement
    getter else_branch : Statement?

    def initialize(@condition : Expr, @then_branch : Statement, @else_branch : Statement?)
    end
  end

  class ForStatement < Statement
    getter init : RawStatement?
    getter condition : Expr?
    getter update : RawStatement?
    getter body : Statement

    def initialize(@init : RawStatement?, @condition : Expr?, @update : RawStatement?, @body : Statement)
    end
  end

  class WhileStatement < Statement
    getter condition : Expr
    getter body : Statement

    def initialize(@condition : Expr, @body : Statement)
    end
  end

  class DoWhileStatement < Statement
    getter body : Statement
    getter condition : Expr

    def initialize(@body : Statement, @condition : Expr)
    end
  end

  record SwitchClause, test : Expr?, statements : Array(Statement)

  class SwitchStatement < Statement
    getter discriminant : Expr
    getter clauses : Array(SwitchClause)

    def initialize(@discriminant : Expr, @clauses : Array(SwitchClause))
    end
  end

  class BreakStatement < Statement
  end

  class ContinueStatement < Statement
  end
end
