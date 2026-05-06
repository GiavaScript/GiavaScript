module GiavaScript
  class ExpressionParser
    @tokenizer : Tokenizer
    @current : Tokenizer::Token

    def initialize(@source : String)
      @tokenizer = Tokenizer.new(@source)
      @current = @tokenizer.next_token
    end

    def parse : Expr
      value = parse_expression
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Eof
      value
    end

    private def parse_expression : Expr
      parse_logical_or
    end

    private def parse_logical_or : Expr
      left = parse_logical_and

      loop do
        break unless @current.kind == Tokenizer::TokenKind::OrOr

        advance_token
        right = parse_logical_and
        left = BinaryExpr.new(left, Tokenizer::TokenKind::OrOr, right)
      end

      left
    end

    private def parse_logical_and : Expr
      left = parse_equality

      loop do
        break unless @current.kind == Tokenizer::TokenKind::AndAnd

        advance_token
        right = parse_equality
        left = BinaryExpr.new(left, Tokenizer::TokenKind::AndAnd, right)
      end

      left
    end

    private def parse_equality : Expr
      left = parse_comparison

      loop do
        operator = @current.kind
        break unless equality_operator?(operator)

        advance_token
        right = parse_comparison
        left = BinaryExpr.new(left, operator, right)
      end

      left
    end

    private def parse_comparison : Expr
      left = parse_addition

      loop do
        operator = @current.kind
        break unless comparison_operator?(operator)

        advance_token
        right = parse_addition
        left = BinaryExpr.new(left, operator, right)
      end

      left
    end

    private def parse_addition : Expr
      left = parse_term

      loop do
        operator = @current.kind
        break unless operator == Tokenizer::TokenKind::Plus || operator == Tokenizer::TokenKind::Minus

        advance_token
        right = parse_term
        left = BinaryExpr.new(left, operator, right)
      end

      left
    end

    private def parse_term : Expr
      left = parse_power

      loop do
        operator = @current.kind
        break unless operator == Tokenizer::TokenKind::Star || operator == Tokenizer::TokenKind::Slash || operator == Tokenizer::TokenKind::Percent

        advance_token
        right = parse_power
        left = BinaryExpr.new(left, operator, right)
      end

      left
    end

    private def parse_power : Expr
      left = parse_factor

      if @current.kind == Tokenizer::TokenKind::Caret
        advance_token
        right = parse_power
        return BinaryExpr.new(left, Tokenizer::TokenKind::Caret, right)
      end

      left
    end

    private def parse_factor : Expr
      if @current.kind == Tokenizer::TokenKind::Plus
        advance_token
        return parse_factor
      end

      if @current.kind == Tokenizer::TokenKind::Minus
        advance_token
        value = parse_factor
        return UnaryExpr.new(Tokenizer::TokenKind::Minus, value)
      end

      if @current.kind == Tokenizer::TokenKind::Bang
        advance_token
        value = parse_factor
        return UnaryExpr.new(Tokenizer::TokenKind::Bang, value)
      end

      parse_postfix
    end

    private def parse_postfix : Expr
      value = parse_primary

      loop do
        if @current.kind == Tokenizer::TokenKind::LParen
          args = parse_call_arguments
          value = FunctionCallExpr.new(value, args)
          next
        end

        if @current.kind == Tokenizer::TokenKind::LBracket
          advance_token
          index = parse_expression
          raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RBracket
          advance_token
          value = IndexExpr.new(value, index)
          next
        end

        if @current.kind == Tokenizer::TokenKind::Dot
          advance_token
          raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Identifier
          property = @current.lexeme
          advance_token
          value = PropertyAccessExpr.new(value, property)
          next
        end

        break
      end

      value
    end

    private def parse_primary : Expr
      case @current.kind
      when Tokenizer::TokenKind::LParen
        advance_token
        value = parse_expression
        raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RParen
        advance_token
        value
      when Tokenizer::TokenKind::LBracket
        parse_array_literal
      when Tokenizer::TokenKind::LBrace
        parse_object_literal
      when Tokenizer::TokenKind::String
        string_value = @current.lexeme
        advance_token
        LiteralExpr.new(string_value)
      when Tokenizer::TokenKind::True
        advance_token
        LiteralExpr.new(true)
      when Tokenizer::TokenKind::False
        advance_token
        LiteralExpr.new(false)
      when Tokenizer::TokenKind::Number
        number_lexeme = @current.lexeme
        advance_token
        LiteralExpr.new(parse_number_value(number_lexeme))
      when Tokenizer::TokenKind::Identifier
        parse_identifier_expression
      else
        raise invalid_rhs_error
      end
    end

    private def parse_array_literal : Expr
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LBracket
      advance_token

      elements = [] of Expr

      unless @current.kind == Tokenizer::TokenKind::RBracket
        loop do
          elements << parse_expression

          if @current.kind == Tokenizer::TokenKind::Comma
            advance_token
            next
          end

          break
        end
      end

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RBracket
      advance_token

      ArrayLiteral.new(elements)
    end

    private def parse_object_literal : Expr
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LBrace
      advance_token

      properties = [] of ObjectProperty

      unless @current.kind == Tokenizer::TokenKind::RBrace
        loop do
          key = parse_object_key
          raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Colon
          advance_token

          value = parse_expression
          properties << ObjectProperty.new(key, value)

          if @current.kind == Tokenizer::TokenKind::Comma
            advance_token
            next
          end

          break
        end
      end

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RBrace
      advance_token

      ObjectLiteral.new(properties)
    end

    private def parse_object_key : String
      case @current.kind
      when Tokenizer::TokenKind::Identifier,
           Tokenizer::TokenKind::String
        key = @current.lexeme
        advance_token
        key
      when Tokenizer::TokenKind::Number
        number_lexeme = @current.lexeme
        advance_token
        parse_number_value(number_lexeme).to_s
      else
        raise invalid_rhs_error
      end
    end

    private def parse_identifier_expression : Expr
      identifier = @current.lexeme
      advance_token

      if identifier == "null"
        return LiteralExpr.new(nil)
      end

      if identifier == "undefined"
        return LiteralExpr.new(UNDEFINED)
      end

      VariableExpr.new(identifier)
    end

    private def parse_call_arguments : Array(Expr)
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LParen
      advance_token

      args = [] of Expr

      unless @current.kind == Tokenizer::TokenKind::RParen
        loop do
          args << parse_expression

          if @current.kind == Tokenizer::TokenKind::Comma
            advance_token
            next
          end

          break
        end
      end

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RParen
      advance_token

      args
    end

    private def parse_number_value(number_lexeme : String) : Number
      return number_lexeme.to_f64 if number_lexeme.includes?('.')
      number_lexeme.to_i32
    rescue
      raise invalid_rhs_error
    end

    private def comparison_operator?(kind : Tokenizer::TokenKind) : Bool
      kind == Tokenizer::TokenKind::Less ||
        kind == Tokenizer::TokenKind::Greater ||
        kind == Tokenizer::TokenKind::LessEqual ||
        kind == Tokenizer::TokenKind::GreaterEqual
    end

    private def equality_operator?(kind : Tokenizer::TokenKind) : Bool
      kind == Tokenizer::TokenKind::EqualEqual || kind == Tokenizer::TokenKind::BangEqual
    end

    private def advance_token
      @current = @tokenizer.next_token
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
