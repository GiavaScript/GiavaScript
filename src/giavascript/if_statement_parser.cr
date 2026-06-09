module GiavaScript
  class IfStatementParser
    include StatementParserShared

    INVALID_IF_ERROR       = "Error: invalid if statement"
    INVALID_FUNCTION_ERROR = "Error: invalid function definition"

    record ParsedIf, statement : IfStatement, end_index : Int32
    record ParsedStatement, statement : Statement, end_index : Int32

    def initialize(@source : String)
    end

    def parse_from(start_index : Int32 = 0) : ParsedIf
      parse_if_statement(skip_whitespace(start_index))
    end

    private def parse_if_statement(index : Int32) : ParsedIf
      current = skip_whitespace(index)
      raise invalid_if_error unless starts_with_keyword?(current, "if")

      current += "if".size
      current = skip_whitespace(current)
      raise invalid_if_error unless @source[current]? == '('

      condition_start = current + 1
      condition_end = find_matching_paren_end_index(current, INVALID_IF_ERROR)
      condition_source = @source[condition_start...condition_end].strip
      raise invalid_if_error if condition_source.empty?

      condition = begin
        ExpressionParser.new(condition_source).parse
      rescue ExpressionError
        raise invalid_if_error
      end

      current = skip_whitespace(condition_end + 1)

      consequent = parse_statement(current, true)
      current = skip_whitespace(advance_past_statement_delimiter(consequent.end_index))

      alternate = nil.as(Statement?)
      if starts_with_keyword?(current, "else")
        current += "else".size
        current = skip_whitespace(current)

        alternate_result = parse_statement(current, false)
        alternate = alternate_result.statement
        current = alternate_result.end_index
      end

      ParsedIf.new(IfStatement.new(condition, consequent.statement, alternate), current)
    end

    private def parse_statement(index : Int32, stop_before_else : Bool) : ParsedStatement
      current = skip_whitespace(index)
      raise invalid_if_error if current >= @source.size

      if starts_with_keyword?(current, "if")
        parsed_if = parse_if_statement(current)
        return ParsedStatement.new(parsed_if.statement, parsed_if.end_index)
      end

      if starts_with_keyword?(current, "for")
        parsed_for = ForStatementParser.new(@source).parse_from(current)
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

      if starts_with_keyword?(current, "try")
        parsed_try = TryStatementParser.new(@source).parse_from(current)
        return ParsedStatement.new(parsed_try.statement, parsed_try.end_index)
      end

      if starts_with_keyword?(current, "function")
        function_end_index = find_function_end_index(current, INVALID_FUNCTION_ERROR)
        source = @source[current...function_end_index].strip
        raise invalid_if_error if source.empty?

        return ParsedStatement.new(RawStatement.new(source), function_end_index)
      end

      if @source[current]? == '{'
        block_end_index = find_matching_brace_end_index(current, INVALID_IF_ERROR) + 1
        block_body = @source[current + 1...block_end_index - 1]
        statements = parse_block_statements(block_body)

        return ParsedStatement.new(BlockStatement.new(statements), block_end_index)
      end

      simple_end_index = find_simple_statement_end_index(current, stop_before_else)
      source = @source[current...simple_end_index].strip
      raise invalid_if_error if source.empty?

      ParsedStatement.new(RawStatement.new(source), simple_end_index)
    end

    private def invalid_if_error : ExpressionError
      ExpressionError.new(INVALID_IF_ERROR)
    end
  end
end
