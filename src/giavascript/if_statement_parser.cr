module GiavaScript
  class IfStatementParser
    include StatementParserShared

    INVALID_IF_ERROR = "Error: invalid if statement"

    record ParsedIf, statement : IfStatement, end_index : Int32

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

      consequent = parse_indexed_statement(current, INVALID_IF_ERROR, true, true)
      current = skip_whitespace(advance_past_statement_delimiter(consequent.end_index))

      alternate = nil.as(Statement?)
      if starts_with_keyword?(current, "else")
        current += "else".size
        current = skip_whitespace(current)

        alternate_result = parse_indexed_statement(current, INVALID_IF_ERROR, false, true)
        alternate = alternate_result.statement
        current = alternate_result.end_index
      end

      ParsedIf.new(IfStatement.new(condition, consequent.statement, alternate), current)
    end

    private def parse_indexed_if_statement(index : Int32) : ParsedIf
      parse_if_statement(index)
    end

    private def invalid_if_error : ExpressionError
      ExpressionError.new(INVALID_IF_ERROR)
    end
  end
end
