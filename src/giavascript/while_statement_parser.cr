module GiavaScript
  class WhileStatementParser
    include StatementParserShared

    INVALID_WHILE_ERROR    = "Error: invalid while statement"
    INVALID_DO_WHILE_ERROR = "Error: invalid do...while statement"

    record ParsedLoop, statement : Statement, end_index : Int32

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
      body = parse_indexed_statement(current, INVALID_WHILE_ERROR)

      ParsedLoop.new(WhileStatement.new(condition, body.statement), body.end_index)
    end

    private def parse_do_while_statement(index : Int32) : ParsedLoop
      current = skip_whitespace(index + "do".size)
      body = begin
        parse_indexed_statement(current, INVALID_WHILE_ERROR)
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

    private def parse_indexed_loop_statement(index : Int32) : ParsedLoop
      parse_loop_statement(index)
    end

    private def invalid_while_error : ExpressionError
      ExpressionError.new(INVALID_WHILE_ERROR)
    end

    private def invalid_do_while_error : ExpressionError
      ExpressionError.new(INVALID_DO_WHILE_ERROR)
    end
  end
end
