module GiavaScript
  class TryStatementParser
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

      block_end_index = find_matching_brace_end_index(current)
      block_body = @source[current + 1...block_end_index]
      statements = parse_block_statements(block_body)
      {statement: BlockStatement.new(statements).as(Statement), end_index: block_end_index + 1}
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

      if starts_with_keyword_in_source?(source, "try")
        return TryStatementParser.new(source).parse_from.statement
      end

      return BreakStatement.new if source == "break"
      return ContinueStatement.new if source == "continue"

      RawStatement.new(source)
    end

    private def find_matching_brace_end_index(index : Int32) : Int32
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

      raise invalid_try_error
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

    private def starts_with_keyword_in_source?(source : String, keyword : String) : Bool
      return false unless source.starts_with?(keyword)

      next_char = source[keyword.size]?
      next_char.nil? || !identifier_continue?(next_char)
    end

    private def identifier_start?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char == '_'
    end

    private def identifier_continue?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char.ascii_number? || char == '_'
    end

    private def invalid_try_error : ExpressionError
      ExpressionError.new(INVALID_TRY_ERROR)
    end
  end
end
