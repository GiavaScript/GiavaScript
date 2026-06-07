module GiavaScript
  class Tokenizer
    enum TokenKind
      Eof
      Identifier
      Number
      String
      Template
      True
      False
      If
      Else
      For
      Break
      Continue
      Typeof
      Void
      New
      Function
      Plus
      Minus
      Star
      Slash
      Percent
      Caret
      Less
      Greater
      LessEqual
      GreaterEqual
      EqualEqual
      BangEqual
      EqualEqualEqual
      BangEqualEqual
      Bang
      AndAnd
      OrOr
      LParen
      RParen
      LBracket
      RBracket
      LBrace
      RBrace
      Colon
      Comma
      Dot
    end

    record Token, kind : TokenKind, lexeme : String

    def initialize(@source : String)
      @index = 0
    end

    def next_token : Token
      skip_whitespace

      char = current_char
      return Token.new(TokenKind::Eof, "") unless char

      case char
      when '+'
        advance
        Token.new(TokenKind::Plus, "+")
      when '-'
        advance
        Token.new(TokenKind::Minus, "-")
      when '*'
        advance
        Token.new(TokenKind::Star, "*")
      when '/'
        advance
        Token.new(TokenKind::Slash, "/")
      when '%'
        advance
        Token.new(TokenKind::Percent, "%")
      when '^'
        advance
        Token.new(TokenKind::Caret, "^")
      when '<'
        advance

        if current_char == '='
          advance
          Token.new(TokenKind::LessEqual, "<=")
        else
          Token.new(TokenKind::Less, "<")
        end
      when '>'
        advance

        if current_char == '='
          advance
          Token.new(TokenKind::GreaterEqual, ">=")
        else
          Token.new(TokenKind::Greater, ">")
        end
      when '='
        advance
        if current_char == '='
          advance
          if current_char == '='
            advance
            Token.new(TokenKind::EqualEqualEqual, "===")
          else
            Token.new(TokenKind::EqualEqual, "==")
          end
        else
          raise invalid_rhs_error
        end
      when '!'
        advance
        if current_char == '='
          advance
          if current_char == '='
            advance
            Token.new(TokenKind::BangEqualEqual, "!==")
          else
            Token.new(TokenKind::BangEqual, "!=")
          end
        else
          Token.new(TokenKind::Bang, "!")
        end
      when '&'
        advance
        if current_char == '&'
          advance
          Token.new(TokenKind::AndAnd, "&&")
        else
          raise invalid_rhs_error
        end
      when '|'
        advance
        if current_char == '|'
          advance
          Token.new(TokenKind::OrOr, "||")
        else
          raise invalid_rhs_error
        end
      when '('
        advance
        Token.new(TokenKind::LParen, "(")
      when ')'
        advance
        Token.new(TokenKind::RParen, ")")
      when '['
        advance
        Token.new(TokenKind::LBracket, "[")
      when ']'
        advance
        Token.new(TokenKind::RBracket, "]")
      when '{'
        advance
        Token.new(TokenKind::LBrace, "{")
      when '}'
        advance
        Token.new(TokenKind::RBrace, "}")
      when ':'
        advance
        Token.new(TokenKind::Colon, ":")
      when ','
        advance
        Token.new(TokenKind::Comma, ",")
      when '.'
        if digit?(peek_char)
          parse_number_token
        else
          advance
          Token.new(TokenKind::Dot, ".")
        end
      when '"', '\''
        parse_string_token
      when '`'
        parse_template_token
      else
        if identifier_start?(char)
          parse_identifier_token
        elsif digit?(char)
          parse_number_token
        else
          raise invalid_rhs_error
        end
      end
    end

    def cursor : Int32
      @index
    end

    def cursor=(value : Int32)
      @index = value
    end

    private def parse_string_token : Token
      delimiter = current_char
      raise invalid_rhs_error unless delimiter

      parser = StringLiteralParser.new(@source, @index, delimiter)
      value = parser.parse
      @index = parser.index
      Token.new(TokenKind::String, value)
    end

    private def parse_template_token : Token
      parser = TemplateLiteralParser.new(@source, @index)
      value = parser.parse
      @index = parser.index
      Token.new(TokenKind::Template, value)
    end

    private def parse_identifier_token : Token
      start = @index
      advance
      while identifier_continue?(current_char)
        advance
      end

      lexeme = @source[start...@index]
      kind = case lexeme
             when "true"
               TokenKind::True
             when "false"
               TokenKind::False
             when "if"
               TokenKind::If
             when "else"
               TokenKind::Else
             when "for"
               TokenKind::For
             when "break"
               TokenKind::Break
             when "continue"
               TokenKind::Continue
             when "typeof"
               TokenKind::Typeof
             when "void"
               TokenKind::Void
             when "new"
               TokenKind::New
             when "function"
               TokenKind::Function
             else
               TokenKind::Identifier
             end

      Token.new(kind, lexeme)
    end

    private def parse_number_token : Token
      start = @index
      has_digits_before_dot = false

      while digit?(current_char)
        has_digits_before_dot = true
        advance
      end

      if current_char == '.'
        advance

        digits_after_dot = false
        while digit?(current_char)
          digits_after_dot = true
          advance
        end

        unless has_digits_before_dot || digits_after_dot
          raise invalid_rhs_error
        end
      end

      token = @source[start...@index]
      raise invalid_rhs_error if token.empty?

      Token.new(TokenKind::Number, token)
    end

    private def skip_whitespace
      while whitespace?(current_char)
        advance
      end
    end

    private def current_char : Char?
      @source[@index]?
    end

    private def advance
      @index += 1
    end

    private def peek_char : Char?
      @source[@index + 1]?
    end

    private def digit?(char : Char?) : Bool
      return false unless char
      char.ascii_number?
    end

    private def whitespace?(char : Char?) : Bool
      char == ' ' || char == '\t' || char == '\n' || char == '\r'
    end

    private def identifier_start?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char == '_'
    end

    private def identifier_continue?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char.ascii_number? || char == '_'
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
