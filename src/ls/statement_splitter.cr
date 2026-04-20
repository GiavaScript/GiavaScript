module Ls
  class StatementSplitter
    def initialize(@input : String)
    end

    def split : Array(String)
      statements = [] of String
      index = 0

      while true
        index = skip_whitespace(index)
        break if index >= @input.size

        if starts_with_keyword?(index, "function")
          fun_end_index = find_function_end_index(index)
          statements << @input[index...fun_end_index].strip
          index = skip_whitespace(fun_end_index)
          index += 1 if @input[index]? == ';'
        else
          stmt_end_index = find_statement_end_index(index)
          statement = @input[index...stmt_end_index].strip
          statements << statement unless statement.empty?
          index = stmt_end_index + 1
        end
      end

      statements
    end

    private def skip_whitespace(index : Int32) : Int32
      current = index
      while current < @input.size
        char = @input[current]
        break unless char == '\n' || char == '\r' || char == ' ' || char == '\t'
        current += 1
      end
      current
    end

    private def find_statement_end_index(index : Int32) : Int32
      current = index
      in_string = false
      escaping = false
      paren_depth = 0

      while current < @input.size
        char = @input[current]

        if in_string
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == '"'
            in_string = false
          end

          current += 1
          next
        end

        case char
        when '"'
          in_string = true
        when '('
          paren_depth += 1
        when ')'
          paren_depth -= 1 if paren_depth > 0
        when ';'
          return current if paren_depth == 0
        end

        current += 1
      end

      raise ExpressionError.new("Error: missing semicolon at end of statement")
    end

    private def find_function_end_index(index : Int32) : Int32
      header_end_index = find_function_header_end_index(index)
      raise ExpressionError.new("Error: invalid function definition") unless @input[header_end_index]? == '{'

      find_matching_brace_end_index(header_end_index) + 1
    end

    private def find_function_header_end_index(index : Int32) : Int32
      current = index + "function".size
      current = skip_whitespace(current)

      unless identifier_start?(@input[current]?)
        raise ExpressionError.new("Error: invalid function definition")
      end

      current += 1
      while current < @input.size && identifier_continue?(@input[current])
        current += 1
      end

      current = skip_whitespace(current)
      unless @input[current]? == '('
        raise ExpressionError.new("Error: invalid function definition")
      end

      paren_depth = 0
      in_string = false
      escaping = false

      while current < @input.size
        char = @input[current]

        if in_string
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == '"'
            in_string = false
          end

          current += 1
          next
        end

        case char
        when '"'
          in_string = true
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
      in_string = false
      escaping = false

      while current < @input.size
        char = @input[current]

        if in_string
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == '"'
            in_string = false
          end

          current += 1
          next
        end

        case char
        when '"'
          in_string = true
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
      return false unless @input[index, keyword.size]? == keyword

      previous_char = index > 0 ? @input[index - 1] : nil
      next_char = @input[index + keyword.size]?

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
