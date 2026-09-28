module GiavaScript
  class StatementTokenizer
    include StatementParserShared

    record StatementSlice, source : String, offset : Int32

    def initialize(@source : String)
      @index = 0
    end

    def tokenize : Array(String)
      tokenize_with_offsets.map(&.source)
    end

    def tokenize_with_offsets : Array(StatementSlice)
      statements = [] of StatementSlice
      while slice = next_statement_slice
        statements << slice
      end
      statements
    end

    def next_statement : String?
      next_statement_slice.try(&.source)
    end

    def next_statement_slice : StatementSlice?
      loop do
        @index = skip_whitespace(@index)
        return nil if @index >= @source.size

        start = @index
        slice = begin
          scan_statement(start)
        rescue ex : ExpressionError
          raise StatementError.new(ex.message || "Error: invalid statement", start)
        end
        return slice if slice
      end
    end

    private def scan_statement(start : Int32) : StatementSlice?
      end_index = nil.as(Int32?)

      if starts_with_keyword?(@index, "function")
        end_index = find_function_end_index(@index)
      elsif starts_with_keyword?(@index, "if")
        end_index = IfStatementParser.new(@source).parse_from(@index).end_index
      elsif starts_with_keyword?(@index, "for")
        end_index = ForStatementParser.new(@source).parse_from(@index).end_index
      elsif starts_with_keyword?(@index, "while") || starts_with_keyword?(@index, "do")
        end_index = WhileStatementParser.new(@source).parse_from(@index).end_index
      elsif starts_with_keyword?(@index, "switch")
        end_index = SwitchStatementParser.new(@source).parse_from(@index).end_index
      elsif starts_with_keyword?(@index, "try")
        end_index = TryStatementParser.new(@source).parse_from(@index).end_index
      end

      if end_index
        statement = @source[start...end_index].strip
        @index = end_index
        @index = advance_past_statement_delimiter(@index)
        return StatementSlice.new(statement, start) unless statement.empty?
        return nil
      end

      statement_end_index = find_statement_end_index(@index)
      statement = @source[@index...statement_end_index].strip
      @index = statement_end_index
      @index = advance_past_statement_delimiter(@index)

      return StatementSlice.new(statement, start) unless statement.empty?
      nil
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
