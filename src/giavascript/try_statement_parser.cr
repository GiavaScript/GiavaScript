module GiavaScript
  class TryStatementParser
    include StatementParserShared

    INVALID_TRY_ERROR = "Error: invalid try statement"

    record ParsedTry, statement : TryStatement, end_index : Int32

    def initialize(@source : String)
    end

    def parse_from(start_index : Int32 = 0) : ParsedTry
      parse_try_statement(skip_whitespace(start_index))
    end

    private def parse_try_statement(index : Int32) : ParsedTry
      current = skip_whitespace(index)
      raise invalid_try_error unless starts_with_keyword?(current, "try")

      current += "try".size
      current = skip_whitespace(current)

      try_block = parse_block_statement(current)
      last_end_index = try_block[:end_index]
      current = skip_whitespace(last_end_index)

      catch_parameter = nil.as(String?)
      catch_branch = nil.as(Statement?)

      if starts_with_keyword?(current, "catch")
        current += "catch".size
        current = skip_whitespace(current)

        if @source[current]? == '('
          current += 1
          current = skip_whitespace(current)

          parameter_start = current
          raise invalid_try_error unless identifier_start?(@source[current]?)

          current += 1
          while identifier_continue?(@source[current]?)
            current += 1
          end

          catch_parameter = @source[parameter_start...current]
          current = skip_whitespace(current)
          raise invalid_try_error unless @source[current]? == ')'

          current += 1
          current = skip_whitespace(current)
        end

        catch_block = parse_block_statement(current)
        catch_branch = catch_block[:statement]
        last_end_index = catch_block[:end_index]
        current = skip_whitespace(last_end_index)
      end

      finally_branch = nil.as(Statement?)
      if starts_with_keyword?(current, "finally")
        current += "finally".size
        current = skip_whitespace(current)

        finally_block = parse_block_statement(current)
        finally_branch = finally_block[:statement]
        last_end_index = finally_block[:end_index]
      end

      raise invalid_try_error unless catch_branch || finally_branch

      ParsedTry.new(TryStatement.new(try_block[:statement], catch_parameter, catch_branch, finally_branch), last_end_index)
    end

    private def parse_block_statement(index : Int32) : NamedTuple(statement: Statement, end_index: Int32)
      current = skip_whitespace(index)
      raise invalid_try_error unless @source[current]? == '{'

      block_end_index = find_matching_brace_end_index(current, INVALID_TRY_ERROR)
      block_body = @source[current + 1...block_end_index]
      statements = parse_block_statements(block_body)
      {statement: BlockStatement.new(statements).as(Statement), end_index: block_end_index + 1}
    end

    private def invalid_try_error : ExpressionError
      ExpressionError.new(INVALID_TRY_ERROR)
    end
  end
end
