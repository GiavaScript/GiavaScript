module GiavaScript
  class CommentStripper
    def self.strip(source : String) : String
      String.build do |io|
        index = 0
        delimiter = nil.as(Char?)
        escaping = false

        while index < source.size
          char = source[index]

          if active_delimiter = delimiter
            io << char

            if escaping
              escaping = false
            elsif char == '\\'
              escaping = true
            elsif char == active_delimiter
              delimiter = nil
            end

            index += 1
            next
          end

          if char == '"' || char == '\'' || char == '`'
            delimiter = char
            io << char
            index += 1
            next
          end

          next_char = source[index + 1]?

          if char == '/' && next_char == '/'
            io << ' '
            index += 2

            while index < source.size
              current = source[index]
              break if current == '\n' || current == '\r'
              io << ' '
              index += 1
            end

            next
          end

          if char == '/' && next_char == '*'
            io << ' '
            index += 2
            terminated = false

            while index < source.size
              current = source[index]
              after = source[index + 1]?

              if current == '*' && after == '/'
                io << ' '
                index += 2
                terminated = true
                break
              end

              io << ' '
              index += 1
            end

            raise ExpressionError.new("Error: unterminated block comment") unless terminated
            next
          end

          io << char
          index += 1
        end
      end
    end
  end
end
