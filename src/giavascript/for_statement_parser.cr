module GiavaScript
  class ForStatementParser
    INVALID_FOR_ERROR = "Error: invalid for statement"
    INVALID_FUNCTION_ERROR = "Error: invalid function definition"

    record ParsedFor, statement : ForStatement, end_index : Int32
    record ParsedStatement, statement : Statement, end_index : Int32

    def initialize(@source : String)
    end

    def parse_from(start_index : Int32 = 0) : ParsedFor
      parse_for_statement(skip_whitespace(start_index))
    end

    private def parse_for_statement(index : Int32) : ParsedFor
      current = skip_whitespace(index)
      raise invalid_for_error unless starts_with_keyword?(current, "for")

      current += "for".size
      current = skip_whitespace(current)
      raise invalid_for_error unless @source[current]? == '('

      header = parse_for_header(current)
      current = skip_whitespace(header[:end_paren_index] + 1)

      body = parse_statement(current)

      ParsedFor.new(
        ForStatement.new(
          parse_optional_init_clause(header[:init_source]),
          parse_optional_condition_clause(header[:condition_source]),
          parse_optional_update_clause(header[:update_source]),
          body.statement
        ),
        body.end_index
      )
    end

    private def parse_optional_init_clause(source : String) : RawStatement?
      clause = source.strip
      return nil if clause.empty?

      RawStatement.new(clause)
    end

    private def parse_optional_condition_clause(source : String) : Expr?
      clause = source.strip
      return nil if clause.empty?

      begin
        ExpressionParser.new(clause).parse
      rescue ExpressionError
        raise invalid_for_error
      end
    end

    private def parse_optional_update_clause(source : String) : RawStatement?
      clause = source.strip
      return nil if clause.empty?

      RawStatement.new(clause)
    end

    private def parse_for_header(index : Int32) : NamedTuple(init_source: String, condition_source: String, update_source: String, end_paren_index: Int32)
      current = index
      paren_depth = 0
      bracket_depth = 0
      brace_depth = 0
      string_delimiter = nil.as(Char?)
      escaping = false
      segment_start = index + 1
      segments = [] of String

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
          paren_depth -= 1
          if paren_depth == 0
            segments << @source[segment_start...current]
            break
          end
        when '['
          bracket_depth += 1
        when ']'
          bracket_depth -= 1 if bracket_depth > 0
        when '{'
          brace_depth += 1
        when '}'
          brace_depth -= 1 if brace_depth > 0
        when ';'
          if paren_depth == 1 && bracket_depth == 0 && brace_depth == 0
            segments << @source[segment_start...current]
            segment_start = current + 1
          end
        end

        current += 1
      end

      raise invalid_for_error unless paren_depth == 0
      raise invalid_for_error unless @source[current]? == ')'
      raise invalid_for_error unless segments.size == 3

      {
        init_source: segments[0],
        condition_source: segments[1],
        update_source: segments[2],
        end_paren_index: current,
      }
    end

    private def parse_statement(index : Int32) : ParsedStatement
      current = skip_whitespace(index)
      raise invalid_for_error if current >= @source.size

      if starts_with_keyword?(current, "if")
        parsed_if = IfStatementParser.new(@source).parse_from(current)
        return ParsedStatement.new(parsed_if.statement, parsed_if.end_index)
      end

      if starts_with_keyword?(current, "for")
        parsed_for = parse_for_statement(current)
        return ParsedStatement.new(parsed_for.statement, parsed_for.end_index)
      end

      if starts_with_keyword?(current, "while") || starts_with_keyword?(current, "do")
        parsed_loop = WhileStatementParser.new(@source).parse_from(current)
        return ParsedStatement.new(parsed_loop.statement, parsed_loop.end_index)
      end

      if starts_with_keyword?(current, "switch")
        parsed_switch = SwitchStatementParser.new(@source).parse_from(current)
        return ParsedStatement.new(parsed_switch.statement, parsed_switch.end_index)
      end

      if starts_with_keyword?(current, "function")
        function_end_index = find_function_end_index(current)
        source = @source[current...function_end_index].strip
        raise invalid_for_error if source.empty?

        return ParsedStatement.new(RawStatement.new(source), function_end_index)
      end

      if @source[current]? == '{'
        block_end_index = find_matching_brace_end_index(current) + 1
        block_body = @source[current + 1...block_end_index - 1]
        statements = parse_block_statements(block_body)

        return ParsedStatement.new(BlockStatement.new(statements), block_end_index)
      end

      simple_end_index = find_simple_statement_end_index(current)
      source = @source[current...simple_end_index].strip
      raise invalid_for_error if source.empty?

      ParsedStatement.new(parse_statement_source(source), simple_end_index)
    end

    private def parse_block_statements(block_body : String) : Array(Statement)
      statements = [] of Statement
      tokenizer = StatementTokenizer.new(block_body)

      while statement_source = tokenizer.next_statement
        statement_source = statement_source.strip
        next if statement_source.empty?

        statements << parse_statement_source(statement_source)
      end

      statements
    end

    private def parse_statement_source(source : String) : Statement
      if starts_with_keyword_in_source?(source, "if")
        return IfStatementParser.new(source).parse_from.statement
      end

      if starts_with_keyword_in_source?(source, "for")
        return ForStatementParser.new(source).parse_from.statement
      end

      if starts_with_keyword_in_source?(source, "while") || starts_with_keyword_in_source?(source, "do")
        return WhileStatementParser.new(source).parse_from.statement
      end

      if starts_with_keyword_in_source?(source, "switch")
        return SwitchStatementParser.new(source).parse_from.statement
      end

      return BreakStatement.new if source == "break"
      return ContinueStatement.new if source == "continue"

      RawStatement.new(source)
    end

    private def starts_with_keyword_in_source?(source : String, keyword : String) : Bool
      return false unless source.starts_with?(keyword)

      next_char = source[keyword.size]?
      next_char.nil? || !identifier_continue?(next_char)
    end

    private def find_simple_statement_end_index(index : Int32) : Int32
      current = index
      string_delimiter = nil.as(Char?)
      escaping = false
      paren_depth = 0

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
          paren_depth -= 1 if paren_depth > 0
        when ';'
          return current if paren_depth == 0
        when '\n', '\r'
          return current if paren_depth == 0
        when '}'
          return current if paren_depth == 0
        end

        current += 1
      end

      current
    end

    private def find_function_end_index(index : Int32) : Int32
      header_end_index = find_function_header_end_index(index)
      raise ExpressionError.new(INVALID_FUNCTION_ERROR) unless @source[header_end_index]? == '{'

      find_matching_brace_end_index(header_end_index, INVALID_FUNCTION_ERROR) + 1
    end

    private def find_function_header_end_index(index : Int32) : Int32
      current = index + "function".size
      current = skip_whitespace(current)

      unless identifier_start?(@source[current]?)
        raise ExpressionError.new(INVALID_FUNCTION_ERROR)
      end

      current += 1
      while current < @source.size && identifier_continue?(@source[current])
        current += 1
      end

      current = skip_whitespace(current)
      raise ExpressionError.new(INVALID_FUNCTION_ERROR) unless @source[current]? == '('

      paren_depth = 0
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
        when '('
          paren_depth += 1
        when ')'
          paren_depth -= 1
          if paren_depth == 0
            current += 1
            return skip_whitespace(current)
          end
        end

        current += 1
      end

      raise ExpressionError.new(INVALID_FUNCTION_ERROR)
    end

    private def find_matching_brace_end_index(index : Int32, error_message : String = INVALID_FOR_ERROR) : Int32
      current = index
      brace_depth = 0
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

      raise ExpressionError.new(error_message)
    end

    private def skip_whitespace(index : Int32) : Int32
      current = index
      while current < @source.size
        char = @source[current]
        break unless char == '\n' || char == '\r' || char == ' ' || char == '\t'
        current += 1
      end
      current
    end

    private def starts_with_keyword?(index : Int32, keyword : String) : Bool
      return false unless @source[index, keyword.size]? == keyword

      previous_char = index > 0 ? @source[index - 1] : nil
      next_char = @source[index + keyword.size]?

      previous_ok = previous_char.nil? || !identifier_continue?(previous_char)
      next_ok = next_char.nil? || !identifier_continue?(next_char)

      previous_ok && next_ok
    end

    private def identifier_start?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char == '_'
    end

    private def identifier_continue?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char.ascii_number? || char == '_'
    end

    private def invalid_for_error : ExpressionError
      ExpressionError.new(INVALID_FOR_ERROR)
    end
  end
end
