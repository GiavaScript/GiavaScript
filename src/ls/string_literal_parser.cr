module Ls
  class StringLiteralParser
    @source : String
    @index : Int32
    @env : Hash(String, Value)
    @call_function : Proc(String, Array(Value), Value)?

    def initialize(@source : String, @index : Int32, @env : Hash(String, Value), @call_function : Proc(String, Array(Value), Value)?)
    end

    getter index

    def parse : String
      raise invalid_rhs_error unless current_char == '"'

      advance
      value = String::Builder.new

      loop do
        char = current_char
        raise invalid_rhs_error unless char

        if char == '"'
          advance
          break
        end

        if char == '\\'
          advance
          escaped = current_char
          raise invalid_rhs_error unless escaped

          case escaped
          when '"', '\\'
            value << escaped
          when '$'
            value << '$'
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

        if char == '$'
          value << parse_interpolated_variable
          next
        end

        value << char
        advance
      end

      value.to_s
    end

    private def parse_interpolated_variable : String
      start = @index
      advance

      if current_char == '{'
        return parse_braced_interpolation
      end

      unless identifier_start?(current_char)
        @index = start
        return "$"
      end

      var_start = @index
      advance
      while identifier_continue?(current_char)
        advance
      end

      var_name = @source[var_start...@index]
      if @env.has_key?(var_name)
        return value_to_string(@env[var_name])
      end

      raise ExpressionError.new("Error: variable '#{var_name}' does not exist")
    end

    private def parse_braced_interpolation : String
      advance
      content_start = @index
      in_string = false
      escaping = false
      nested_braces = 0

      loop do
        char = current_char
        raise invalid_rhs_error unless char

        if in_string
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == '"'
            in_string = false
          end

          advance
          next
        end

        case char
        when '"'
          in_string = true
          advance
        when '{'
          nested_braces += 1
          advance
        when '}'
          if nested_braces == 0
            content = @source[content_start...@index].strip
            advance
            return evaluate_interpolation_content(content)
          end

          nested_braces -= 1
          advance
        else
          advance
        end
      end
    end

    private def evaluate_interpolation_content(content : String) : String
      raise invalid_rhs_error if content.empty?

      if content.matches?(/^[A-Za-z_][A-Za-z0-9_]*$/)
        var_name = content
        if @env.has_key?(var_name)
          return value_to_string(@env[var_name])
        end

        raise ExpressionError.new("Error: variable '#{var_name}' does not exist")
      end

      value = ExpressionParser.new(content, @env, @call_function).parse
      value_to_string(value)
    end

    private def value_to_string(value : Value) : String
      if value.nil?
        return "null"
      end

      if value.is_a?(String)
        value
      else
        value.to_s
      end
    end

    private def current_char : Char?
      @source[@index]?
    end

    private def advance
      @index += 1
    end

    private def identifier_start?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char == '_'
    end

    private def identifier_continue?(char : Char?) : Bool
      return false unless char
      char.ascii_letter? || char.ascii_number? || char == '_'
    end

    private def invalid_rhs_error : ExpressionError
      ExpressionError.new("Error: invalid right-hand side '#{@source}'")
    end
  end
end
