module GiavaScript
  class ExpressionParser
    @tokenizer : Tokenizer
    @current : Tokenizer::Token
    @previous : Tokenizer::Token

    def initialize(@source : String)
      @tokenizer = Tokenizer.new(@source)
      @current = @tokenizer.next_token
      @previous = @current
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
      start_token = @current
      condition = parse_nullish

      return condition unless @current.kind == Tokenizer::TokenKind::Question

      advance_token
      consequent = parse_ternary

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Colon
      advance_token

      alternate = parse_ternary

      node = TernaryExpr.new(condition, consequent, alternate)
      node.span = span_from(start_token)
      node
    end

    private def parse_nullish : Expr
      start_token = @current
      left = parse_logical_or

      loop do
        break unless @current.kind == Tokenizer::TokenKind::QuestionQuestion

        advance_token
        right = parse_logical_or
        node = BinaryExpr.new(left, Tokenizer::TokenKind::QuestionQuestion, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_logical_or : Expr
      start_token = @current
      left = parse_logical_and

      loop do
        break unless @current.kind == Tokenizer::TokenKind::OrOr

        advance_token
        right = parse_logical_and
        node = BinaryExpr.new(left, Tokenizer::TokenKind::OrOr, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_logical_and : Expr
      start_token = @current
      left = parse_bitwise_or

      loop do
        break unless @current.kind == Tokenizer::TokenKind::AndAnd

        advance_token
        right = parse_bitwise_or
        node = BinaryExpr.new(left, Tokenizer::TokenKind::AndAnd, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_bitwise_or : Expr
      start_token = @current
      left = parse_bitwise_xor

      loop do
        break unless @current.kind == Tokenizer::TokenKind::BitwiseOr

        advance_token
        right = parse_bitwise_xor
        node = BinaryExpr.new(left, Tokenizer::TokenKind::BitwiseOr, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_bitwise_xor : Expr
      start_token = @current
      left = parse_bitwise_and

      loop do
        break unless @current.kind == Tokenizer::TokenKind::Caret

        advance_token
        right = parse_bitwise_and
        node = BinaryExpr.new(left, Tokenizer::TokenKind::Caret, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_bitwise_and : Expr
      start_token = @current
      left = parse_equality

      loop do
        break unless @current.kind == Tokenizer::TokenKind::BitwiseAnd

        advance_token
        right = parse_equality
        node = BinaryExpr.new(left, Tokenizer::TokenKind::BitwiseAnd, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_equality : Expr
      start_token = @current
      left = parse_comparison

      loop do
        operator = @current.kind
        break unless equality_operator?(operator)

        advance_token
        right = parse_comparison
        node = BinaryExpr.new(left, operator, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_comparison : Expr
      start_token = @current
      left = parse_shift

      loop do
        operator = @current.kind
        break unless comparison_operator?(operator)

        advance_token
        right = parse_shift
        node = BinaryExpr.new(left, operator, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_shift : Expr
      start_token = @current
      left = parse_addition

      loop do
        operator = @current.kind
        break unless operator == Tokenizer::TokenKind::ShiftLeft || operator == Tokenizer::TokenKind::ShiftRight

        advance_token
        right = parse_addition
        node = BinaryExpr.new(left, operator, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_addition : Expr
      start_token = @current
      left = parse_term

      loop do
        operator = @current.kind
        break unless operator == Tokenizer::TokenKind::Plus || operator == Tokenizer::TokenKind::Minus

        advance_token
        right = parse_term
        node = BinaryExpr.new(left, operator, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_term : Expr
      start_token = @current
      left = parse_factor

      loop do
        operator = @current.kind
        break unless operator == Tokenizer::TokenKind::Star || operator == Tokenizer::TokenKind::Slash || operator == Tokenizer::TokenKind::Percent

        advance_token
        right = parse_factor
        node = BinaryExpr.new(left, operator, right)
        node.span = span_from(start_token)
        left = node
      end

      left
    end

    private def parse_factor : Expr
      start_token = @current

      if @current.kind == Tokenizer::TokenKind::Plus
        advance_token
        value = parse_factor
        node = UnaryExpr.new(Tokenizer::TokenKind::Plus, value)
        node.span = span_from(start_token)
        return node
      end

      if @current.kind == Tokenizer::TokenKind::Minus
        advance_token
        value = parse_factor
        node = UnaryExpr.new(Tokenizer::TokenKind::Minus, value)
        node.span = span_from(start_token)
        return node
      end

      if @current.kind == Tokenizer::TokenKind::Bang
        advance_token
        value = parse_factor
        node = UnaryExpr.new(Tokenizer::TokenKind::Bang, value)
        node.span = span_from(start_token)
        return node
      end

      if @current.kind == Tokenizer::TokenKind::Typeof
        advance_token
        value = parse_factor
        node = UnaryExpr.new(Tokenizer::TokenKind::Typeof, value)
        node.span = span_from(start_token)
        return node
      end

      if @current.kind == Tokenizer::TokenKind::Void
        advance_token
        value = parse_factor
        node = UnaryExpr.new(Tokenizer::TokenKind::Void, value)
        node.span = span_from(start_token)
        return node
      end

      if @current.kind == Tokenizer::TokenKind::BitwiseNot
        advance_token
        value = parse_factor
        node = UnaryExpr.new(Tokenizer::TokenKind::BitwiseNot, value)
        node.span = span_from(start_token)
        return node
      end

      if @current.kind == Tokenizer::TokenKind::New
        advance_token
        callee = parse_primary
        args = @current.kind == Tokenizer::TokenKind::LParen ? parse_call_arguments : [] of Expr
        node = NewExpr.new(callee, args)
        node.span = span_from(start_token)
        return node
      end

      parse_postfix
    end

    private def parse_postfix : Expr
      start_token = @current
      value = parse_primary
      chain_base = nil.as(Expr?)
      links = [] of ChainLink

      loop do
        case @current.kind
        when Tokenizer::TokenKind::QuestionDot
          chain_base ||= value
          advance_token

          case @current.kind
          when Tokenizer::TokenKind::Identifier
            property = @current.lexeme
            advance_token
            links << ChainLink.new(ChainLinkKind::Property, name: property, optional: true)
          when Tokenizer::TokenKind::LBracket
            advance_token
            index = parse_expression
            raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RBracket
            advance_token
            links << ChainLink.new(ChainLinkKind::Index, index: index, optional: true)
          when Tokenizer::TokenKind::LParen
            links << ChainLink.new(ChainLinkKind::Call, args: parse_call_arguments, optional: true)
          else
            raise invalid_rhs_error
          end
        when Tokenizer::TokenKind::LParen
          args = parse_call_arguments
          if chain_base
            links << ChainLink.new(ChainLinkKind::Call, args: args)
          else
            node = FunctionCallExpr.new(value, args)
            node.span = span_from(start_token)
            value = node
          end
        when Tokenizer::TokenKind::LBracket
          advance_token
          index = parse_expression
          raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RBracket
          advance_token
          if chain_base
            links << ChainLink.new(ChainLinkKind::Index, index: index)
          else
            node = IndexExpr.new(value, index)
            node.span = span_from(start_token)
            value = node
          end
        when Tokenizer::TokenKind::Dot
          advance_token
          raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Identifier
          property = @current.lexeme
          advance_token
          if chain_base
            links << ChainLink.new(ChainLinkKind::Property, name: property)
          else
            node = PropertyAccessExpr.new(value, property)
            node.span = span_from(start_token)
            value = node
          end
        else
          break
        end
      end

      if base = chain_base
        node = OptionalChainExpr.new(base, links)
        node.span = span_from(start_token)
        return node
      end

      value
    end

    private def parse_primary : Expr
      start_token = @current

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
        node = LiteralExpr.new(string_value)
        node.span = span_from(start_token)
        node
      when Tokenizer::TokenKind::Template
        template_source = @current.lexeme
        advance_token
        node = parse_template_literal(template_source)
        node.span = span_from(start_token)
        node
      when Tokenizer::TokenKind::True
        advance_token
        node = LiteralExpr.new(true)
        node.span = span_from(start_token)
        node
      when Tokenizer::TokenKind::False
        advance_token
        node = LiteralExpr.new(false)
        node.span = span_from(start_token)
        node
      when Tokenizer::TokenKind::Number
        number_lexeme = @current.lexeme
        advance_token
        node = LiteralExpr.new(parse_number_value(number_lexeme))
        node.span = span_from(start_token)
        node
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
        node = RegexLiteralExpr.new(pattern, flags)
        node.span = Span.new(regex_token.line, regex_token.column, regex_token.raw_length)
        node
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
      start_token = @current
      advance_token

      elements = [] of Expr

      unless @current.kind == Tokenizer::TokenKind::RBracket
        loop do
          if @current.kind == Tokenizer::TokenKind::Spread
            spread_token = @current
            advance_token
            spread = SpreadElement.new(parse_expression)
            spread.span = span_from(spread_token)
            elements << spread
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

      node = ArrayLiteral.new(elements)
      node.span = span_from(start_token)
      node
    end

    private def parse_object_literal : Expr
      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LBrace
      start_token = @current
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

      node = ObjectLiteral.new(properties)
      node.span = span_from(start_token)
      node
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
      start_token = @current
      advance_token

      function_name = nil.as(String?)
      if @current.kind == Tokenizer::TokenKind::Identifier
        function_name = @current.lexeme
        advance_token
      end

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LParen
      advance_token

      parsed_parameters = parse_parameter_list

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::LBrace
      body_start = @tokenizer.cursor
      body_end = find_matching_brace_end_index(body_start)
      body_source = @source[body_start...body_end]

      @tokenizer.cursor = body_end + 1
      advance_token

      node = FunctionExpr.new(
        function_name,
        parsed_parameters[:parameters],
        body_source,
        parsed_parameters[:rest_parameter],
        parsed_parameters[:defaults]
      )
      node.span = Span.new(start_token.line, start_token.column, (body_end + 1) - start_token.offset)
      node
    end

    private def try_parse_paren_arrow_function : ArrowFunctionExpr?
      return nil unless @current.kind == Tokenizer::TokenKind::LParen

      start_token = @current
      saved_cursor = @tokenizer.cursor
      saved_token = @current

      advance_token

      begin
        parsed_parameters = parse_parameter_list
        return restore_and_nil(saved_cursor, saved_token) unless @current.kind == Tokenizer::TokenKind::Arrow

        advance_token
        return parse_arrow_body(
          parsed_parameters[:parameters],
          parsed_parameters[:rest_parameter],
          parsed_parameters[:defaults],
          start_token
        )
      rescue ExpressionError
        return restore_and_nil(saved_cursor, saved_token)
      end
    end

    private def try_parse_identifier_arrow_function : ArrowFunctionExpr?
      return nil unless @current.kind == Tokenizer::TokenKind::Identifier

      start_token = @current
      saved_cursor = @tokenizer.cursor
      saved_token = @current

      param = @current.lexeme
      advance_token

      if @current.kind == Tokenizer::TokenKind::Arrow
        advance_token
        return parse_arrow_body([param], start_token: start_token)
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

    private def parse_parameter_list : NamedTuple(parameters: Array(String), rest_parameter: String?, defaults: Hash(String, String))
      parameters = [] of String
      rest_parameter = nil.as(String?)
      parameter_names = Set(String).new
      defaults = {} of String => String

      unless @current.kind == Tokenizer::TokenKind::RParen
        loop do
          is_rest = @current.kind == Tokenizer::TokenKind::Spread
          advance_token if is_rest
          raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::Identifier

          parameter = @current.lexeme
          unless parameter_names.add?(parameter)
            raise ExpressionError.new("Error: duplicate function parameters are not allowed")
          end
          advance_token

          if is_rest
            rest_parameter = parameter
          else
            parameters << parameter
            if @current.kind == Tokenizer::TokenKind::Equals
              default_start = @tokenizer.cursor
              advance_token
              default_source = extract_default_source(default_start)
              raise invalid_rhs_error if default_source.empty?
              defaults[parameter] = default_source
            end
          end

          if @current.kind == Tokenizer::TokenKind::Comma
            raise ExpressionError.new("Error: rest parameter must be last") if rest_parameter
            advance_token
            break if @current.kind == Tokenizer::TokenKind::RParen
            next
          end

          break
        end
      end

      raise invalid_rhs_error unless @current.kind == Tokenizer::TokenKind::RParen
      advance_token
      {parameters: parameters, rest_parameter: rest_parameter, defaults: defaults}
    end

    private def extract_default_source(default_start : Int32) : String
      paren_depth = 0
      bracket_depth = 0
      string_delimiter = nil.as(Char?)
      escaping = false
      current = default_start

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
        when '('
          paren_depth += 1
        when ')'
          if paren_depth > 0
            paren_depth -= 1
          else
            break
          end
        when '['
          bracket_depth += 1
        when ']'
          if bracket_depth > 0
            bracket_depth -= 1
          end
        when ','
          if paren_depth == 0 && bracket_depth == 0
            break
          end
        end

        current += 1
      end

      default_source = @source[default_start...current].strip
      @tokenizer.cursor = current
      advance_token
      default_source
    end

    private def parse_arrow_body(parameters : Array(String), rest_parameter : String? = nil, defaults : Hash(String, String) = {} of String => String, start_token : Tokenizer::Token? = nil) : ArrowFunctionExpr
      if @current.kind == Tokenizer::TokenKind::LBrace
        body_start = @tokenizer.cursor
        body_end = find_matching_brace_end_index(body_start)
        body_source = @source[body_start...body_end]

        @tokenizer.cursor = body_end + 1
        advance_token

        node = ArrowFunctionExpr.new(parameters, body_source, rest_parameter, defaults)
        node.span = Span.new(start_token.line, start_token.column, (body_end + 1) - start_token.offset) if start_token
        return node
      end

      body_start = @tokenizer.cursor - @current.lexeme.size
      parse_expression
      body_end = @tokenizer.cursor - @current.lexeme.size
      body_source = "return " + @source[body_start...body_end].strip + ";"
      node = ArrowFunctionExpr.new(parameters, body_source, rest_parameter, defaults)
      node.span = Span.new(start_token.line, start_token.column, body_end - start_token.offset) if start_token
      node
    end

    private def parse_identifier_expression : Expr
      start_token = @current
      identifier = @current.lexeme
      advance_token

      node = if identifier == "null"
               LiteralExpr.new(nil)
             elsif identifier == "undefined"
               LiteralExpr.new(UNDEFINED)
             else
               VariableExpr.new(identifier)
             end
      node.span = span_from(start_token)
      node
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
            spread_token = @current
            advance_token
            spread = SpreadCallArg.new(parse_expression)
            spread.span = span_from(spread_token)
            args << spread
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
      @previous = @current
      @current = @tokenizer.next_token
    end

    private def span_from(start_token : Tokenizer::Token) : Span
      length = (@previous.offset + @previous.raw_length) - start_token.offset
      length = 0 if length < 0
      Span.new(start_token.line, start_token.column, length)
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
