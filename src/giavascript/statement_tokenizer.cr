module GiavaScript
  class StatementTokenizer
    def initialize(@source : String)
      @index = 0
    end

    def next_statement : String?
      loop do
        @index = skip_whitespace(@index)
        return nil if @index >= @source.size

        if starts_with_keyword?(@index, "function")
          function_end_index = find_function_end_index(@index)
          statement = @source[@index...function_end_index].strip
          @index = function_end_index
          @index = consume_statement_delimiter(@index)
          return statement
        end

        if starts_with_keyword?(@index, "if")
          if_end_index = IfStatementParser.new(@source).parse_from(@index).end_index
          statement = @source[@index...if_end_index].strip
          @index = if_end_index
          @index = consume_statement_delimiter(@index)
          return statement
        end

        if starts_with_keyword?(@index, "for")
          for_end_index = ForStatementParser.new(@source).parse_from(@index).end_index
          statement = @source[@index...for_end_index].strip
          @index = for_end_index
          @index = consume_statement_delimiter(@index)
          return statement
        end

        if starts_with_keyword?(@index, "while") || starts_with_keyword?(@index, "do")
          loop_end_index = WhileStatementParser.new(@source).parse_from(@index).end_index
          statement = @source[@index...loop_end_index].strip
          @index = loop_end_index
          @index = consume_statement_delimiter(@index)
          return statement
        end

        statement_end_index = find_statement_end_index(@index)
        statement = @source[@index...statement_end_index].strip
        @index = statement_end_index
        @index = consume_statement_delimiter(@index)

        return statement unless statement.empty?
      end
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

    private def consume_statement_delimiter(index : Int32) : Int32
      delimiter = @source[index]?
      return index unless delimiter

      if delimiter == ';' || delimiter == '\n'
        return index + 1
      end

      if delimiter == '\r'
        next_index = index + 1
        next_index += 1 if @source[next_index]? == '\n'
        return next_index
      end

      index
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
        when '"', '\''
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
          return current if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0
        end

        current += 1
      end

      current
    end

    private def find_function_end_index(index : Int32) : Int32
      header_end_index = find_function_header_end_index(index)
      raise ExpressionError.new("Error: invalid function definition") unless @source[header_end_index]? == '{'

      find_matching_brace_end_index(header_end_index) + 1
    end

    private def find_function_header_end_index(index : Int32) : Int32
      current = index + "function".size
      current = skip_whitespace(current)

      unless identifier_start?(@source[current]?)
        raise ExpressionError.new("Error: invalid function definition")
      end

      current += 1
      while current < @source.size && identifier_continue?(@source[current])
        current += 1
      end

      current = skip_whitespace(current)
      raise ExpressionError.new("Error: invalid function definition") unless @source[current]? == '('

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
        when '"', '\''
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

      raise ExpressionError.new("Error: invalid function definition")
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
        when '"', '\''
          string_delimiter = char
        when '{'
          brace_depth += 1
        when '}'
          brace_depth -= 1
          return current if brace_depth == 0
        end

        current += 1
      end

      raise ExpressionError.new("Error: invalid function definition")
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
  end
end
