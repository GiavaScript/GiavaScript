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
      Arrow
      Plus
      Minus
      Star
      Slash
      Percent
      Caret
      BitwiseAnd
      BitwiseOr
      BitwiseNot
      ShiftLeft
      ShiftRight
      Question
      QuestionQuestion
      QuestionDot
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
      Spread
      RegexLiteral
      Equals
    end

    record Token, kind : TokenKind, lexeme : String, offset : Int32 = 0, line : Int32 = 0, column : Int32 = 0, raw_length : Int32 = 0

    def initialize(@source : String)
      @index = 0
      @line = 1
      @line_start = 0
      @token_offset = 0
      @token_line = 1
      @token_column = 1
    end

    def next_token : Token
      skip_whitespace

      @token_offset = @index
      @token_line = @line
      @token_column = @index - @line_start + 1

      scanned = scan_token
      Token.new(scanned.kind, scanned.lexeme, @token_offset, @token_line, @token_column, @index - @token_offset)
    end

    private def scan_token : Token
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
      when '?'
        advance
        if current_char == '?'
          advance
          Token.new(TokenKind::QuestionQuestion, "??")
        elsif current_char == '.'
          advance
          Token.new(TokenKind::QuestionDot, "?.")
        else
          Token.new(TokenKind::Question, "?")
        end
      when '^'
        advance
        Token.new(TokenKind::Caret, "^")
      when '<'
        advance

        if current_char == '='
          advance
          Token.new(TokenKind::LessEqual, "<=")
        elsif current_char == '<'
          advance
          Token.new(TokenKind::ShiftLeft, "<<")
        else
          Token.new(TokenKind::Less, "<")
        end
      when '>'
        advance

        if current_char == '='
          advance
          Token.new(TokenKind::GreaterEqual, ">=")
        elsif current_char == '>'
          advance
          Token.new(TokenKind::ShiftRight, ">>")
        else
          Token.new(TokenKind::Greater, ">")
        end
      when '='
        advance
        if current_char == '>'
          advance
          Token.new(TokenKind::Arrow, "=>")
        elsif current_char == '='
          advance
          if current_char == '='
            advance
            Token.new(TokenKind::EqualEqualEqual, "===")
          else
            Token.new(TokenKind::EqualEqual, "==")
          end
        else
          Token.new(TokenKind::Equals, "=")
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
          Token.new(TokenKind::BitwiseAnd, "&")
        end
      when '|'
        advance
        if current_char == '|'
          advance
          Token.new(TokenKind::OrOr, "||")
        else
          Token.new(TokenKind::BitwiseOr, "|")
        end
      when '~'
        advance
        Token.new(TokenKind::BitwiseNot, "~")
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
        elsif peek_char == '.' && (@source[@index + 2]?) == '.'
          3.times { advance }
          Token.new(TokenKind::Spread, "...")
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
      recompute_position
    end

    private def recompute_position
      @line = 1
      @line_start = 0
      limit = @index < @source.size ? @index : @source.size
      index = 0
      while index < limit
        if @source[index] == '\n'
          @line += 1
          @line_start = index + 1
        end
        index += 1
      end
    end

    private def parse_string_token : Token
      delimiter = current_char
      raise invalid_rhs_error unless delimiter

      parser = StringLiteralParser.new(@source, @index, delimiter)
      value = parser.parse
      @index = parser.index
      recompute_position
      Token.new(TokenKind::String, value)
    end

    private def parse_template_token : Token
      parser = TemplateLiteralParser.new(@source, @index)
      value = parser.parse
      @index = parser.index
      recompute_position
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
      if @source[@index]? == '\n'
        @line += 1
        @line_start = @index + 1
      end
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

    def parse_regex_literal : Token?
      pattern_start = @index

      current = @index
      in_character_class = false
      escaping = false

      while current < @source.size
        char = @source[current]

        if escaping
          escaping = false
          current += 1
          next
        end

        if char == '\\'
          escaping = true
          current += 1
          next
        end

        if char == '['
          in_character_class = true
          current += 1
          next
        end

        if char == ']' && in_character_class
          in_character_class = false
          current += 1
          next
        end

        if char == '/' && !in_character_class
          flags_start = current + 1

          flags_end = flags_start
          while flags_end < @source.size
            flag_char = @source[flags_end]
            break unless flag_char == 'g' || flag_char == 'i' || flag_char == 'm' || flag_char == 's' || flag_char == 'u'
            flags_end += 1
          end

          flags = @source[flags_start...flags_end]

          flag_set = Set(Char).new
          flags.each_char do |f|
            return nil unless flag_set.add?(f)
          end

          @index = flags_end
          recompute_position
          lexeme = @source[pattern_start - 1...flags_end]
          return Token.new(TokenKind::RegexLiteral, lexeme, @token_offset, @token_line, @token_column, @index - @token_offset)
        end

        current += 1
      end

      nil
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
