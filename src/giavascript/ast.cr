module GiavaScript
  struct Span
    getter line : Int32
    getter column : Int32
    getter length : Int32

    def initialize(@line : Int32, @column : Int32, @length : Int32)
    end
  end

  abstract class Expr
    property span : Span?
  end

  class LiteralExpr < Expr
    getter value : Value

    def initialize(@value : Value)
    end
  end

  class TemplateLiteralExpr < Expr
    getter segments : Array(String)
    getter expressions : Array(Expr)

    def initialize(@segments : Array(String), @expressions : Array(Expr))
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

  class NewExpr < Expr
    getter callee : Expr
    getter args : Array(Expr)

    def initialize(@callee : Expr, @args : Array(Expr))
    end
  end

  class FunctionExpr < Expr
    getter name : String?
    getter parameters : Array(String)
    getter rest_parameter : String?
    getter body_source : String
    getter parameter_defaults : Hash(String, String)

    def initialize(@name : String?, @parameters : Array(String), @body_source : String, @rest_parameter : String? = nil, @parameter_defaults : Hash(String, String) = {} of String => String)
    end
  end

  class ArrowFunctionExpr < Expr
    getter parameters : Array(String)
    getter rest_parameter : String?
    getter body_source : String
    getter parameter_defaults : Hash(String, String)

    def initialize(@parameters : Array(String), @body_source : String, @rest_parameter : String? = nil, @parameter_defaults : Hash(String, String) = {} of String => String)
    end
  end

  class ArrayLiteral < Expr
    getter elements : Array(Expr)

    def initialize(@elements : Array(Expr))
    end
  end

  class SpreadElement < Expr
    getter expr : Expr

    def initialize(@expr : Expr)
    end
  end

  record ObjectProperty, key : String, value : Expr, spread : Bool = false

  class ObjectLiteral < Expr
    getter properties : Array(ObjectProperty)

    def initialize(@properties : Array(ObjectProperty))
    end
  end

  class SpreadCallArg < Expr
    getter expr : Expr

    def initialize(@expr : Expr)
    end
  end

  class RegexLiteralExpr < Expr
    getter pattern : String
    getter flags : String

    def initialize(@pattern : String, @flags : String)
    end
  end

  class TernaryExpr < Expr
    getter condition : Expr
    getter consequent : Expr
    getter alternate : Expr

    def initialize(@condition : Expr, @consequent : Expr, @alternate : Expr)
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

  enum ChainLinkKind
    Property
    Index
    Call
  end

  record ChainLink, kind : ChainLinkKind, name : String = "", index : Expr? = nil, args : Array(Expr) = [] of Expr, optional : Bool = false

  class OptionalChainExpr < Expr
    getter base : Expr
    getter links : Array(ChainLink)

    def initialize(@base : Expr, @links : Array(ChainLink))
    end
  end

  abstract class Statement
    property span : Span?
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
    getter init : Statement?
    getter condition : Expr?
    getter update : Statement?
    getter body : Statement

    def initialize(@init : Statement?, @condition : Expr?, @update : Statement?, @body : Statement)
    end
  end

  class ForOfStatement < Statement
    getter var_name : String
    getter iterable : Expr
    getter body : Statement

    def initialize(@var_name : String, @iterable : Expr, @body : Statement)
    end
  end

  class ForInStatement < Statement
    getter var_name : String
    getter iterable : Expr
    getter body : Statement

    def initialize(@var_name : String, @iterable : Expr, @body : Statement)
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

  class TryStatement < Statement
    getter try_branch : Statement
    getter catch_parameter : String?
    getter catch_branch : Statement?
    getter finally_branch : Statement?

    def initialize(@try_branch : Statement, @catch_parameter : String?, @catch_branch : Statement?, @finally_branch : Statement?)
    end
  end

  class BreakStatement < Statement
  end

  class ContinueStatement < Statement
  end

  abstract class SimpleStatement < Statement
    getter source : String

    def initialize(@source : String)
    end
  end

  class ErrorStatement < SimpleStatement
    getter message : String

    def initialize(source : String, @message : String)
      super(source)
    end
  end

  class ExpressionStatement < SimpleStatement
    getter expression : Expr

    def initialize(source : String, @expression : Expr)
      super(source)
    end
  end

  class FunctionDeclarationStatement < SimpleStatement
    getter function : FunctionExpr

    def initialize(source : String, @function : FunctionExpr)
      super(source)
    end
  end

  class VariableDeclarationStatement < SimpleStatement
    getter keyword : String
    getter name : String
    getter has_initializer : Bool
    getter initializer : Expr?
    getter initializer_error : String?

    def initialize(source : String, @keyword : String, @name : String, @has_initializer : Bool, @initializer : Expr?, @initializer_error : String?)
      super(source)
    end
  end

  class DestructuringDeclarationStatement < SimpleStatement
    getter keyword : String
    getter pattern : BindingPattern
    getter initializer : Expr?
    getter initializer_error : String?

    def initialize(source : String, @keyword : String, @pattern : BindingPattern, @initializer : Expr?, @initializer_error : String?)
      super(source)
    end
  end

  class AssignmentStatement < SimpleStatement
    getter target : Expr
    getter operator : String
    getter value : Expr?
    getter value_error : String?

    def initialize(source : String, @target : Expr, @operator : String, @value : Expr?, @value_error : String?)
      super(source)
    end
  end

  class DestructuringAssignmentStatement < SimpleStatement
    getter pattern : BindingPattern
    getter value : Expr?
    getter value_error : String?

    def initialize(source : String, @pattern : BindingPattern, @value : Expr?, @value_error : String?)
      super(source)
    end
  end

  class UpdateStatement < SimpleStatement
    getter target : Expr
    getter operator : String

    def initialize(source : String, @target : Expr, @operator : String)
      super(source)
    end
  end

  class ReturnStatement < SimpleStatement
    getter value : Expr?
    getter value_error : String?

    def initialize(source : String, @value : Expr?, @value_error : String?)
      super(source)
    end
  end

  class ThrowStatement < SimpleStatement
    getter value : Expr?
    getter value_error : String?

    def initialize(source : String, @value : Expr?, @value_error : String?)
      super(source)
    end
  end

  class ImportStatement < SimpleStatement
    getter path : Expr

    def initialize(source : String, @path : Expr)
      super(source)
    end
  end
end
