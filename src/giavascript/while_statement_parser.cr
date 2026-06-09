module GiavaScript
  class WhileStatementParser
    include StatementParserShared

    INVALID_WHILE_ERROR    = "Error: invalid while statement"
    INVALID_DO_WHILE_ERROR = "Error: invalid do...while statement"
    INVALID_FUNCTION_ERROR = "Error: invalid function definition"

    record ParsedLoop, statement : Statement, end_index : Int32
    record ParsedStatement, statement : Statement, end_index : Int32

    def initialize(@source : String)
    end

    def parse_from(start_index : Int32 = 0) : ParsedLoop
      parse_loop_statement(skip_whitespace(start_index))
    end

    private def parse_loop_statement(index : Int32) : ParsedLoop
      current = skip_whitespace(index)
      if starts_with_keyword?(current, "while")
        return parse_while_statement(current)
      end

      if starts_with_keyword?(current, "do")
        return parse_do_while_statement(current)
      end

      raise invalid_while_error
    end

    private def parse_while_statement(index : Int32) : ParsedLoop
      current = index + "while".size
      current = skip_whitespace(current)
      raise invalid_while_error unless @source[current]? == '('

      condition_start = current + 1
      condition_end = find_matching_paren_end_index(current, INVALID_WHILE_ERROR)
      condition_source = @source[condition_start...condition_end].strip
      raise invalid_while_error if condition_source.empty?

      condition = begin
        ExpressionParser.new(condition_source).parse
      rescue ExpressionError
        raise invalid_while_error
      end

      current = skip_whitespace(condition_end + 1)
      body = parse_statement(current)

      ParsedLoop.new(WhileStatement.new(condition, body.statement), body.end_index)
    end

    private def parse_do_while_statement(index : Int32) : ParsedLoop
      current = skip_whitespace(index + "do".size)
      body = begin
        parse_statement(current)
      rescue ex : ExpressionError
        raise invalid_do_while_error
      end

      current = skip_whitespace(advance_past_statement_delimiter(body.end_index))
      raise invalid_do_while_error unless starts_with_keyword?(current, "while")

      current += "while".size
      current = skip_whitespace(current)
      raise invalid_do_while_error unless @source[current]? == '('

      condition_start = current + 1
      condition_end = find_matching_paren_end_index(current, INVALID_DO_WHILE_ERROR)
      condition_source = @source[condition_start...condition_end].strip
      raise invalid_do_while_error if condition_source.empty?

      condition = begin
        ExpressionParser.new(condition_source).parse
      rescue ExpressionError
        raise invalid_do_while_error
      end

      ParsedLoop.new(DoWhileStatement.new(body.statement, condition), condition_end + 1)
    end

    private def parse_statement(index : Int32) : ParsedStatement
      current = skip_whitespace(index)
      raise invalid_while_error if current >= @source.size

      if starts_with_keyword?(current, "if")
        parsed_if = IfStatementParser.new(@source).parse_from(current)
        return ParsedStatement.new(parsed_if.statement, parsed_if.end_index)
      end

      if starts_with_keyword?(current, "for")
        parsed_for = ForStatementParser.new(@source).parse_from(current)
        return ParsedStatement.new(parsed_for.statement, parsed_for.end_index)
      end

      if starts_with_keyword?(current, "while") || starts_with_keyword?(current, "do")
        parsed_loop = parse_loop_statement(current)
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
        raise invalid_while_error if source.empty?

        return ParsedStatement.new(RawStatement.new(source), function_end_index)
      end

      if @source[current]? == '{'
        block_end_index = find_matching_brace_end_index(current, INVALID_WHILE_ERROR) + 1
        block_body = @source[current + 1...block_end_index - 1]
        statements = parse_block_statements(block_body)

        return ParsedStatement.new(BlockStatement.new(statements), block_end_index)
      end

      simple_end_index = find_simple_statement_end_index(current)
      source = @source[current...simple_end_index].strip
      raise invalid_while_error if source.empty?

      ParsedStatement.new(parse_statement_source(source), simple_end_index)
    end

    private def invalid_while_error : ExpressionError
      ExpressionError.new(INVALID_WHILE_ERROR)
    end

    private def invalid_do_while_error : ExpressionError
      ExpressionError.new(INVALID_DO_WHILE_ERROR)
    end
  end
end
