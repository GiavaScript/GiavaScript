module GiavaScript
  class StatementTokenizer
    include StatementParserShared

    def initialize(@source : String)
      @index = 0
    end

    def tokenize : Array(String)
      statements = [] of String
      while statement = next_statement
        statements << statement
      end
      statements
    end

    def next_statement : String?
      loop do
        @index = skip_whitespace(@index)
        return nil if @index >= @source.size

        if starts_with_keyword?(@index, "function")
          function_end_index = find_function_end_index(@index)
          statement = @source[@index...function_end_index].strip
          @index = function_end_index
          @index = advance_past_statement_delimiter(@index)
          return statement
        end

        if starts_with_keyword?(@index, "if")
          if_end_index = IfStatementParser.new(@source).parse_from(@index).end_index
          statement = @source[@index...if_end_index].strip
          @index = if_end_index
          @index = advance_past_statement_delimiter(@index)
          return statement
        end

        if starts_with_keyword?(@index, "for")
          for_end_index = ForStatementParser.new(@source).parse_from(@index).end_index
          statement = @source[@index...for_end_index].strip
          @index = for_end_index
          @index = advance_past_statement_delimiter(@index)
          return statement
        end

        if starts_with_keyword?(@index, "while") || starts_with_keyword?(@index, "do")
          loop_end_index = WhileStatementParser.new(@source).parse_from(@index).end_index
          statement = @source[@index...loop_end_index].strip
          @index = loop_end_index
          @index = advance_past_statement_delimiter(@index)
          return statement
        end

        if starts_with_keyword?(@index, "switch")
          switch_end_index = SwitchStatementParser.new(@source).parse_from(@index).end_index
          statement = @source[@index...switch_end_index].strip
          @index = switch_end_index
          @index = advance_past_statement_delimiter(@index)
          return statement
        end

        if starts_with_keyword?(@index, "try")
          try_end_index = TryStatementParser.new(@source).parse_from(@index).end_index
          statement = @source[@index...try_end_index].strip
          @index = try_end_index
          @index = advance_past_statement_delimiter(@index)
          return statement
        end

        statement_end_index = find_statement_end_index(@index)
        statement = @source[@index...statement_end_index].strip
        @index = statement_end_index
        @index = advance_past_statement_delimiter(@index)

        return statement unless statement.empty?
      end
    end

    private def find_statement_end_index(index : Int32) : Int32
      current = index
      string_delimiter = nil.as(Char?)
      escaping = false
      paren_depth = 0
      bracket_depth = 0
      brace_depth = 0

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
        when '['
          bracket_depth += 1
        when ']'
          bracket_depth -= 1 if bracket_depth > 0
        when '{'
          brace_depth += 1
        when '}'
          brace_depth -= 1 if brace_depth > 0
        when ';'
          return current if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0
        when '\n', '\r'
          if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0
            return current unless chained_property_continuation_after_line_break?(current)
          end
        end

        current += 1
      end

      current
    end

    private def chained_property_continuation_after_line_break?(line_break_index : Int32) : Bool
      current = line_break_index

      if @source[current] == '\r' && @source[current + 1]? == '\n'
        current += 1
      end

      current += 1
      current = skip_inline_whitespace(current)

      @source[current]? == '.'
    end

    private def skip_inline_whitespace(index : Int32) : Int32
      current = index
      while current < @source.size
        char = @source[current]
        break unless char == ' ' || char == '\t'
        current += 1
      end
      current
    end
  end
end
