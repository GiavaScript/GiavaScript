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
      parse_ternary
    end

    private def parse_ternary : Expr
      condition = parse_logical_or

      return condition unless @current.kind == Tokenizer::TokenKind::Question

      advance_token
      consequent = parse_ternary

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Colon
      advance_token

      alternate = parse_ternary

      TernaryExpr.new(condition, consequent, alternate)
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
        value = parse_factor
        return UnaryExpr.new(Tokenizer::TokenKind::Plus, value)
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

      if @current.kind == Tokenizer::TokenKind::Typeof
        advance_token
        value = parse_factor
        return UnaryExpr.new(Tokenizer::TokenKind::Typeof, value)
      end

      if @current.kind == Tokenizer::TokenKind::Void
        advance_token
        value = parse_factor
        return UnaryExpr.new(Tokenizer::TokenKind::Void, value)
      end

      if @current.kind == Tokenizer::TokenKind::New
        advance_token
        callee = parse_primary
        args = @current.kind == Tokenizer::TokenKind::LParen ? parse_call_arguments : [] of Expr
        return NewExpr.new(callee, args)
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
        parsed_arrow = try_parse_paren_arrow_function
        return parsed_arrow if parsed_arrow

        advance_token
        value = parse_expression
        raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RParen
        advance_token
        value
      when Tokenizer::TokenKind::LBracket
        parse_array_literal
      when Tokenizer::TokenKind::LBrace
        parse_object_literal
      when Tokenizer::TokenKind::Function
        parse_function_expression
      when Tokenizer::TokenKind::String
        string_value = @current.lexeme
        advance_token
        LiteralExpr.new(string_value)
      when Tokenizer::TokenKind::Template
        template_source = @current.lexeme
        advance_token
        parse_template_literal(template_source)
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
      when Tokenizer::TokenKind::Slash
        regex_token = @tokenizer.parse_regex_literal
        raise invalid_rhs_error unless regex_token

        lexeme = regex_token.lexeme
        last_slash = lexeme.rindex('/')
        raise invalid_rhs_error unless last_slash
        pattern = lexeme[1...last_slash]
        flags = lexeme[last_slash + 1...lexeme.size]

        begin
          RegExpValue.new(pattern, flags)
        rescue ex
          raise invalid_rhs_error
        end

        advance_token
        RegexLiteralExpr.new(pattern, flags)
      when Tokenizer::TokenKind::Identifier
        parsed_arrow = try_parse_identifier_arrow_function
        return parsed_arrow if parsed_arrow
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
          if @current.kind == Tokenizer::TokenKind::Spread
            advance_token
            elements << SpreadElement.new(parse_expression)
          else
            elements << parse_expression
          end

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
          if @current.kind == Tokenizer::TokenKind::Spread
            advance_token
            value = parse_expression
            properties << ObjectProperty.new("", value, spread: true)
          else
            key = parse_object_key
            raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Colon
            advance_token

            value = parse_expression
            properties << ObjectProperty.new(key, value)
          end

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

    private def parse_function_expression : Expr
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Function
      advance_token

      function_name = nil.as(String?)
      if @current.kind == Tokenizer::TokenKind::Identifier
        function_name = @current.lexeme
        advance_token
      end

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LParen
      advance_token

      parameters = [] of String
      rest_parameter = nil.as(String?)
      param_set = Set(String).new
      unless @current.kind == Tokenizer::TokenKind::RParen
        loop do
          if @current.kind == Tokenizer::TokenKind::Spread
            advance_token
            raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Identifier
            parameter = @current.lexeme
            raise invalid_rhs_error unless param_set.add?(parameter)
            rest_parameter = parameter
            advance_token
          else
            raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Identifier
            parameter = @current.lexeme
            raise invalid_rhs_error unless param_set.add?(parameter)
            parameters << parameter
            advance_token
          end

          if @current.kind == Tokenizer::TokenKind::Comma
            advance_token
            raise invalid_rhs_error if rest_parameter
            next
          end

          break
        end
      end

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RParen
      advance_token

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LBrace
      body_start = @tokenizer.cursor
      body_end = find_matching_brace_end_index(body_start)
      body_source = @source[body_start...body_end]

      @tokenizer.cursor = body_end + 1
      advance_token

      FunctionExpr.new(function_name, parameters, body_source, rest_parameter)
    end

    private def try_parse_paren_arrow_function : ArrowFunctionExpr?
      return nil unless @current.kind == Tokenizer::TokenKind::LParen

      saved_cursor = @tokenizer.cursor
      saved_token = @current

      advance_token

      parameters = [] of String
      rest_parameter = nil.as(String?)
      param_set = Set(String).new

      if @current.kind == Tokenizer::TokenKind::RParen
        advance_token
        if @current.kind == Tokenizer::TokenKind::Arrow
          advance_token
          return parse_arrow_body(parameters, rest_parameter)
        end
      elsif @current.kind == Tokenizer::TokenKind::Identifier || @current.kind == Tokenizer::TokenKind::Spread
        loop do
          if @current.kind == Tokenizer::TokenKind::Spread
            advance_token
            return restore_and_nil(saved_cursor, saved_token) unless @current.kind == Tokenizer::TokenKind::Identifier
            param = @current.lexeme
            return restore_and_nil(saved_cursor, saved_token) unless param_set.add?(param)
            rest_parameter = param
            advance_token
          else
            return restore_and_nil(saved_cursor, saved_token) unless @current.kind == Tokenizer::TokenKind::Identifier
            param = @current.lexeme
            return restore_and_nil(saved_cursor, saved_token) unless param_set.add?(param)
            parameters << param
            advance_token
          end

          if @current.kind == Tokenizer::TokenKind::Comma
            advance_token
            return restore_and_nil(saved_cursor, saved_token) if rest_parameter
            return restore_and_nil(saved_cursor, saved_token) unless @current.kind == Tokenizer::TokenKind::Identifier || @current.kind == Tokenizer::TokenKind::Spread
            next
          end

          break
        end

        if @current.kind == Tokenizer::TokenKind::RParen
          advance_token
          if @current.kind == Tokenizer::TokenKind::Arrow
            advance_token
            return parse_arrow_body(parameters, rest_parameter)
          end
        end
      end

      @tokenizer.cursor = saved_cursor
      @current = saved_token
      nil
    end

    private def try_parse_identifier_arrow_function : ArrowFunctionExpr?
      return nil unless @current.kind == Tokenizer::TokenKind::Identifier

      saved_cursor = @tokenizer.cursor
      saved_token = @current

      param = @current.lexeme
      advance_token

      if @current.kind == Tokenizer::TokenKind::Arrow
        advance_token
        return parse_arrow_body([param])
      end

      @tokenizer.cursor = saved_cursor
      @current = saved_token
      nil
    end

    private def restore_and_nil(saved_cursor : Int32, saved_token : Tokenizer::Token) : Nil
      @tokenizer.cursor = saved_cursor
      @current = saved_token
      nil
    end

    private def parse_arrow_body(parameters : Array(String), rest_parameter : String? = nil) : ArrowFunctionExpr
      if @current.kind == Tokenizer::TokenKind::LBrace
        body_start = @tokenizer.cursor
        body_end = find_matching_brace_end_index(body_start)
        body_source = @source[body_start...body_end]

        @tokenizer.cursor = body_end + 1
        advance_token

        return ArrowFunctionExpr.new(parameters, body_source, rest_parameter)
      end

      body_start = @tokenizer.cursor - @current.lexeme.size
      parse_expression
      body_end = @tokenizer.cursor - @current.lexeme.size
      body_source = "return " + @source[body_start...body_end].strip + ";"
      ArrowFunctionExpr.new(parameters, body_source, rest_parameter)
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

    private def parse_template_literal(template_source : String) : Expr
      segments = [] of String
      expressions = [] of Expr
      segment_start = 0
      current = 0

      while current < template_source.size
        char = template_source[current]

        if char == '\\'
          current += 1
          raise invalid_rhs_error if current >= template_source.size
          current += 1
          next
        end

        if char == '$' && template_source[current + 1]? == '{'
          segments << decode_template_segment(template_source[segment_start...current])
          interpolation = parse_template_interpolation(template_source, current + 2)
          expression_source = interpolation[:expression_source]
          expression_end = interpolation[:expression_end]

          begin
            expressions << ExpressionParser.new(expression_source).parse
          rescue ExpressionError
            raise invalid_rhs_error
          end

          current = expression_end
          segment_start = current
          next
        end

        current += 1
      end

      segments << decode_template_segment(template_source[segment_start...template_source.size])
      TemplateLiteralExpr.new(segments, expressions)
    end

    private def decode_template_segment(segment_source : String) : String
      value = String::Builder.new
      current = 0

      while current < segment_source.size
        char = segment_source[current]

        if char != '\\'
          value << char
          current += 1
          next
        end

        current += 1
        escaped = segment_source[current]?
        raise invalid_rhs_error unless escaped

        case escaped
        when '`', '\\'
          value << escaped
        when 'n'
          value << '\n'
        when 't'
          value << '\t'
        when '$'
          if segment_source[current + 1]? == '{'
            value << '$'
            value << '{'
            current += 1
          else
            value << '$'
          end
        else
          raise invalid_rhs_error
        end

        current += 1
      end

      value.to_s
    end

    private def parse_template_interpolation(template_source : String, start_index : Int32) : NamedTuple(expression_source: String, expression_end: Int32)
      current = start_index
      brace_depth = 1
      string_delimiter = nil.as(Char?)
      escaping = false

      while current < template_source.size
        char = template_source[current]

        if delimiter = string_delimiter
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end

          current += 1
          next
        end

        if char == '"' || char == '\'' || char == '`'
          string_delimiter = char
          current += 1
          next
        end

        if char == '{'
          brace_depth += 1
          current += 1
          next
        end

        if char == '}'
          brace_depth -= 1
          if brace_depth == 0
            expression_source = template_source[start_index...current].strip
            raise invalid_rhs_error if expression_source.empty?
            return {expression_source: expression_source, expression_end: current + 1}
          end

          current += 1
          next
        end

        current += 1
      end

      raise invalid_rhs_error
    end

    private def find_matching_brace_end_index(index : Int32) : Int32
      current = index
      brace_depth = 1
      string_delimiter = nil.as(Char?)
      escaping = false

      while current < @source.size
        char = @source[current]

        if delimiter = string_delimiter
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end

          current += 1
          next
        end

        case char
        when '"', '\'', '`'
          string_delimiter = char
        when '{'
          brace_depth += 1
        when '}'
          brace_depth -= 1
          return current if brace_depth == 0
        end

        current += 1
      end

      raise invalid_rhs_error
    end

    private def parse_call_arguments : Array(Expr)
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LParen
      advance_token

      args = [] of Expr

      unless @current.kind == Tokenizer::TokenKind::RParen
        loop do
          if @current.kind == Tokenizer::TokenKind::Spread
            advance_token
            args << SpreadCallArg.new(parse_expression)
          else
            args << parse_expression
          end

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
      kind == Tokenizer::TokenKind::EqualEqual ||
        kind == Tokenizer::TokenKind::BangEqual ||
        kind == Tokenizer::TokenKind::EqualEqualEqual ||
        kind == Tokenizer::TokenKind::BangEqualEqual
    end

    private def advance_token
      @current = @tokenizer.next_token
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
