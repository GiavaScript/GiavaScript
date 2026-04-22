module Ls
  class IfStatementParser
    INVALID_IF_ERROR = "Error: invalid if statement"
    INVALID_FUNCTION_ERROR = "Error: invalid function definition"

    record ParsedIf, condition : String, consequent : String, alternate : String?, end_index : Int32

    def initialize(@source : String)
    end

    def parse_from(start_index : Int32 = 0) : ParsedIf
      current = skip_whitespace(start_index)
      raise invalid_if_error unless starts_with_keyword?(current, "if")

      current += "if".size
      current = skip_whitespace(current)
      raise invalid_if_error unless @source[current]? == '('

      condition_start = current + 1
      condition_end = find_matching_paren_end_index(current)
      condition = @source[condition_start...condition_end].strip
      raise invalid_if_error if condition.empty?

      current = skip_whitespace(condition_end + 1)

      consequent_start = current
      consequent_end = find_statement_end_index(current, true)
      consequent = @source[consequent_start...consequent_end].strip
      raise invalid_if_error if consequent.empty?

      alternate = nil.as(String?)
      current = skip_whitespace(advance_past_statement_delimiter(consequent_end))

      if starts_with_keyword?(current, "else")
        current += "else".size
        current = skip_whitespace(current)

        alternate_start = current
        alternate_end = find_statement_end_index(current, false)
        alternate = @source[alternate_start...alternate_end].strip
        raise invalid_if_error if alternate.empty?

        current = alternate_end
      end

      ParsedIf.new(condition, consequent, alternate, current)
    end

    private def find_statement_end_index(index : Int32, stop_before_else : Bool) : Int32
      current = skip_whitespace(index)
      raise invalid_if_error if current >= @source.size

      if starts_with_keyword?(current, "if")
        return parse_from(current).end_index
      end

      if starts_with_keyword?(current, "function")
        return find_function_end_index(current)
      end

      if @source[current]? == '{'
        return find_matching_brace_end_index(current) + 1
      end

      find_simple_statement_end_index(current, stop_before_else)
    end

    private def find_simple_statement_end_index(index : Int32, stop_before_else : Bool) : Int32
      current = index
      string_delimiter = nil.as(Char?)
      escaping = false
      paren_depth = 0

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

        if stop_before_else && paren_depth == 0 && starts_with_keyword?(current, "else")
          return current
        end

        case char
        when '"', '\''
          string_delimiter = char
        when '('
          paren_depth += 1
        when ')'
          paren_depth -= 1 if paren_depth > 0
        when ';'
          return current if paren_depth == 0
        when '\n', '\r'
          return current if paren_depth == 0
        when '}'
          return current if paren_depth == 0
        end

        current += 1
      end

      current
    end

    private def find_function_end_index(index : Int32) : Int32
      header_end_index = find_function_header_end_index(index)
      raise ExpressionError.new(INVALID_FUNCTION_ERROR) unless @source[header_end_index]? == '{'

      find_matching_brace_end_index(header_end_index, INVALID_FUNCTION_ERROR) + 1
    end

    private def find_function_header_end_index(index : Int32) : Int32
      current = index + "function".size
      current = skip_whitespace(current)

      unless identifier_start?(@source[current]?)
        raise ExpressionError.new(INVALID_FUNCTION_ERROR)
      end

      current += 1
      while current < @source.size && identifier_continue?(@source[current])
        current += 1
      end

      current = skip_whitespace(current)
      raise ExpressionError.new(INVALID_FUNCTION_ERROR) unless @source[current]? == '('

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

      raise ExpressionError.new(INVALID_FUNCTION_ERROR)
    end

    private def find_matching_paren_end_index(index : Int32) : Int32
      current = index
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
          return current if paren_depth == 0
        end

        current += 1
      end

      raise invalid_if_error
    end

    private def find_matching_brace_end_index(index : Int32, error_message : String = INVALID_IF_ERROR) : Int32
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

      raise ExpressionError.new(error_message)
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

    private def advance_past_statement_delimiter(index : Int32) : Int32
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

    private def invalid_if_error : ExpressionError
      ExpressionError.new(INVALID_IF_ERROR)
    end
  end
end
