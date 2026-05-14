module GiavaScript
  class TemplateLiteralParser
    @source : String
    @index : Int32

    def initialize(@source : String, @index : Int32)
    end

    getter index

    def parse : String
      raise invalid_rhs_error unless current_char == '`'

      advance
      value = String::Builder.new
      escaping = false

      loop do
        char = current_char
        raise invalid_rhs_error unless char

        if escaping
          value << char
          escaping = false
          advance
          next
        end

        if char == '\\'
          value << char
          escaping = true
          advance
          next
        end

        if char == '`'
          advance
          break
        end

        if char == '$' && peek_char == '{'
          value << '$'
          value << '{'
          advance
          advance
          copy_interpolation(value)
          next
        end

        value << char
        advance
      end

      raise invalid_rhs_error if escaping

      value.to_s
    end

    private def copy_interpolation(builder : String::Builder)
      brace_depth = 1
      string_delimiter = nil.as(Char?)
      escaping = false

      while brace_depth > 0
        char = current_char
        raise invalid_rhs_error unless char

        if delimiter = string_delimiter
          builder << char

          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end

          advance
          next
        end

        if char == '"' || char == '\'' || char == '`'
          string_delimiter = char
          builder << char
          advance
          next
        end

        if char == '{'
          brace_depth += 1
          builder << char
          advance
          next
        end

        if char == '}'
          brace_depth -= 1
          builder << char
          advance
          next
        end

        builder << char
        advance
      end
    end

    private def current_char : Char?
      @source[@index]?
    end

    private def peek_char : Char?
      @source[@index + 1]?
    end

    private def advance
      @index += 1
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
