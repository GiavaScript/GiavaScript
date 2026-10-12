module GiavaScript
  abstract class BindingPattern
  end

  class IdentifierBinding < BindingPattern
    getter name : String

    def initialize(@name : String)
    end
  end

  record ElementBinding, pattern : BindingPattern, default_source : String?

  class ArrayBinding < BindingPattern
    getter elements : Array(ElementBinding)
    getter rest : String?

    def initialize(@elements : Array(ElementBinding), @rest : String?)
    end
  end

  record PropertyBinding, key : String, pattern : BindingPattern, default_source : String?

  class ObjectBinding < BindingPattern
    getter properties : Array(PropertyBinding)
    getter rest : String?

    def initialize(@properties : Array(PropertyBinding), @rest : String?)
    end
  end

  class BindingPatternParser
    def initialize(@source : String)
      @index = 0
    end

    def parse : BindingPattern
      skip_whitespace
      pattern = parse_pattern
      skip_whitespace
      raise invalid_pattern unless @index >= @source.size
      pattern
    end

    private def parse_pattern : BindingPattern
      case current_char
      when '['
        parse_array
      when '{'
        parse_object
      else
        parse_identifier_binding
      end
    end

    private def parse_identifier_binding : BindingPattern
      name = parse_identifier
      raise invalid_pattern unless valid_identifier?(name)
      IdentifierBinding.new(name)
    end

    private def parse_array : BindingPattern
      expect('[')
      elements = [] of ElementBinding
      rest = nil.as(String?)

      skip_whitespace
      unless current_char == ']'
        loop do
          skip_whitespace
          if starts_with?("...")
            @index += 3
            rest = parse_identifier
            raise invalid_pattern unless valid_identifier?(rest)
            skip_whitespace
            break
          end

          pattern = parse_pattern
          default_source = parse_default
          elements << ElementBinding.new(pattern, default_source)
          skip_whitespace

          if current_char == ','
            @index += 1
            skip_whitespace
            break if current_char == ']'
            next
          end

          break
        end
      end

      expect(']')
      ArrayBinding.new(elements, rest)
    end

    private def parse_object : BindingPattern
      expect('{')
      properties = [] of PropertyBinding
      rest = nil.as(String?)

      skip_whitespace
      unless current_char == '}'
        loop do
          skip_whitespace
          if starts_with?("...")
            @index += 3
            rest = parse_identifier
            raise invalid_pattern unless valid_identifier?(rest)
            skip_whitespace
            break
          end

          key = parse_property_key
          skip_whitespace

          pattern = if current_char == ':'
                      @index += 1
                      skip_whitespace
                      parse_pattern
                    else
                      raise invalid_pattern unless valid_identifier?(key)
                      IdentifierBinding.new(key).as(BindingPattern)
                    end

          default_source = parse_default
          properties << PropertyBinding.new(key, pattern, default_source)
          skip_whitespace

          if current_char == ','
            @index += 1
            skip_whitespace
            break if current_char == '}'
            next
          end

          break
        end
      end

      expect('}')
      ObjectBinding.new(properties, rest)
    end

    private def parse_property_key : String
      char = current_char
      if char == '"' || char == '\''
        parse_string_key
      else
        key = parse_identifier
        raise invalid_pattern if key.empty?
        key
      end
    end

    private def parse_string_key : String
      delimiter = current_char
      raise invalid_pattern unless delimiter
      @index += 1

      value = String::Builder.new
      while (char = current_char)
        if char == '\\'
          @index += 1
          escaped = current_char
          raise invalid_pattern unless escaped
          value << escaped
        elsif char == delimiter
          @index += 1
          return value.to_s
        else
          value << char
        end
        @index += 1
      end

      raise invalid_pattern
    end

    private def parse_default : String?
      skip_whitespace
      return nil unless current_char == '='
      @index += 1
      start = @index
      depth = 0
      string_delimiter = nil.as(Char?)
      escaping = false

      while (char = current_char)
        if delimiter = string_delimiter
          if escaping
            escaping = false
          elsif char == '\\'
            escaping = true
          elsif char == delimiter
            string_delimiter = nil
          end
          @index += 1
          next
        end

        case char
        when '"', '\'', '`'
          string_delimiter = char
        when '(', '[', '{'
          depth += 1
        when ')', ']', '}'
          break if depth == 0
          depth -= 1
        when ','
          break if depth == 0
        end
        @index += 1
      end

      expression = @source[start...@index].strip
      raise invalid_pattern if expression.empty?
      expression
    end

    private def parse_identifier : String
      skip_whitespace
      start = @index
      while (char = current_char) && identifier_part?(char)
        @index += 1
      end
      @source[start...@index]
    end

    private def valid_identifier?(name : String) : Bool
      return false if name.empty?
      return false unless identifier_start?(name[0])
      name.each_char { |char| return false unless identifier_part?(char) }
      true
    end

    private def identifier_start?(char : Char) : Bool
      char.ascii_letter? || char == '_'
    end

    private def identifier_part?(char : Char) : Bool
      char.ascii_letter? || char.ascii_number? || char == '_'
    end

    private def starts_with?(text : String) : Bool
      @source[@index, text.size]? == text
    end

    private def expect(char : Char)
      skip_whitespace
      raise invalid_pattern unless current_char == char
      @index += 1
    end

    private def skip_whitespace
      while (char = current_char) && (char == ' ' || char == '\t' || char == '\n' || char == '\r')
        @index += 1
      end
    end

    private def current_char : Char?
      @source[@index]?
    end

    private def invalid_pattern : ExpressionError
      ExpressionError.new("Error: invalid destructuring pattern '#{@source}'")
    end
  end
end
