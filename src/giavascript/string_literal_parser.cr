module GiavaScript
  class StringLiteralParser
    @source : String
    @index : Int32

    def initialize(@source : String, @index : Int32, @delimiter : Char)
    end

    getter index

    def parse : String
      raise invalid_rhs_error unless current_char == @delimiter

      advance
      value = String::Builder.new

      loop do
        char = current_char
        raise invalid_rhs_error unless char

        if char == @delimiter
          advance
          break
        end

        if char == '\\'
          advance
          escaped = current_char
          raise invalid_rhs_error unless escaped

          case escaped
          when '"', '\'', '\\'
            value << escaped
          when 'n'
            value << '\n'
          when 't'
            value << '\t'
          else
            raise invalid_rhs_error
          end

          advance
          next
        end

        value << char
        advance
      end

      value.to_s
    end

    private def current_char : Char?
      @source[@index]?
    end

    private def advance
      @index += 1
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
