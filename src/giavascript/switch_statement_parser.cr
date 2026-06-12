module GiavaScript
  class SwitchStatementParser
    include StatementParserShared

    INVALID_SWITCH_ERROR = "Error: invalid switch statement"

    record ParsedSwitch, statement : SwitchStatement, end_index : Int32

    def initialize(@source : String)
    end

    def parse_from(start_index : Int32 = 0) : ParsedSwitch
      parse_switch_statement(skip_whitespace(start_index))
    end

    private def parse_switch_statement(index : Int32) : ParsedSwitch
      current = skip_whitespace(index)
      raise invalid_switch_error unless starts_with_keyword?(current, "switch")

      current += "switch".size
      current = skip_whitespace(current)
      raise invalid_switch_error unless @source[current]? == '('

      discriminant_start = current + 1
      discriminant_end = find_matching_paren_end_index(current, INVALID_SWITCH_ERROR)
      discriminant_source = @source[discriminant_start...discriminant_end].strip
      raise invalid_switch_error if discriminant_source.empty?

      discriminant = begin
        ExpressionParser.new(discriminant_source).parse
      rescue ExpressionError
        raise invalid_switch_error
      end

      current = skip_whitespace(discriminant_end + 1)
      raise invalid_switch_error unless @source[current]? == '{'

      block_end_index = find_matching_brace_end_index(current, INVALID_SWITCH_ERROR)
      block_body = @source[current + 1...block_end_index]
      clauses = parse_switch_clauses(block_body)

      ParsedSwitch.new(SwitchStatement.new(discriminant, clauses), block_end_index + 1)
    end

    private def parse_switch_clauses(source : String) : Array(SwitchClause)
      clauses = [] of SwitchClause
      current = 0
      saw_default = false

      loop do
        current = skip_whitespace_in_source(source, current)
        break if current >= source.size

        if starts_with_keyword_in_source?(source, current, "case")
          header_start = skip_whitespace_in_source(source, current + "case".size)
          colon_index = find_case_colon_index(source, header_start)
          test_source = source[header_start...colon_index].strip
          raise invalid_switch_error if test_source.empty?

          test = begin
            ExpressionParser.new(test_source).parse
          rescue ExpressionError
            raise invalid_switch_error
          end

          body_start = colon_index + 1
          next_clause_index = find_next_clause_index(source, body_start)
          body_source = source[body_start...next_clause_index]

          clauses << SwitchClause.new(test, parse_clause_statements(body_source))
          current = next_clause_index
          next
        end

        if starts_with_keyword_in_source?(source, current, "default")
          raise invalid_switch_error if saw_default
          saw_default = true

          colon_index = skip_whitespace_in_source(source, current + "default".size)
          raise invalid_switch_error unless source[colon_index]? == ':'

          body_start = colon_index + 1
          next_clause_index = find_next_clause_index(source, body_start)
          body_source = source[body_start...next_clause_index]

          clauses << SwitchClause.new(nil, parse_clause_statements(body_source))
          current = next_clause_index
          next
        end

        raise invalid_switch_error
      end

      clauses
    end

    private def parse_clause_statements(body_source : String) : Array(Statement)
      parse_block_statements(body_source)
    end

    private def find_case_colon_index(source : String, index : Int32) : Int32
      current = index
      string_delimiter = nil.as(Char?)
      escaping = false
      paren_depth = 0
      bracket_depth = 0
      brace_depth = 0

      while current < source.size
        char = source[current]

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
        when '['
          bracket_depth += 1
        when ']'
          bracket_depth -= 1 if bracket_depth > 0
        when '{'
          brace_depth += 1
        when '}'
          brace_depth -= 1 if brace_depth > 0
        when ':'
          if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0
            return current
          end
        end

        current += 1
      end

      raise invalid_switch_error
    end

    private def find_next_clause_index(source : String, index : Int32) : Int32
      current = index
      string_delimiter = nil.as(Char?)
      escaping = false
      paren_depth = 0
      bracket_depth = 0
      brace_depth = 0

      while current < source.size
        char = source[current]

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
        when '['
          bracket_depth += 1
        when ']'
          bracket_depth -= 1 if bracket_depth > 0
        when '{'
          brace_depth += 1
        when '}'
          brace_depth -= 1 if brace_depth > 0
        end

        if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0
          if starts_with_keyword_in_source?(source, current, "case") || starts_with_keyword_in_source?(source, current, "default")
            return current
          end
        end

        current += 1
      end

      source.size
    end

    private def skip_whitespace_in_source(source : String, index : Int32) : Int32
      current = index
      while current < source.size
        char = source[current]
        break unless char == '\n' || char == '\r' || char == ' ' || char == '\t'
        current += 1
      end
      current
    end

    private def starts_with_keyword_in_source?(source : String, index : Int32, keyword : String) : Bool
      return false unless source[index, keyword.size]? == keyword

      previous_char = index > 0 ? source[index - 1] : nil
      next_char = source[index + keyword.size]?

      previous_ok = previous_char.nil? || !identifier_continue?(previous_char)
      next_ok = next_char.nil? || !identifier_continue?(next_char)

      previous_ok && next_ok
    end

    private def invalid_switch_error : ExpressionError
      ExpressionError.new(INVALID_SWITCH_ERROR)
    end
  end
end
