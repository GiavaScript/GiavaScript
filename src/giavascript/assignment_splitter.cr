module GiavaScript
  module AssignmentSplitter
    extend self

    def split(stmt : String) : NamedTuple(lhs: String, rhs: String, operator: String)?
      return nil unless stmt.includes?('=')

      current = 0
      string_delimiter = nil.as(Char?)
      escaping = false
      paren_depth = 0
      bracket_depth = 0
      brace_depth = 0

      while current < stmt.size
        char = stmt[current]

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
        when '='
          previous_char = current > 0 ? stmt[current - 1] : nil
          previous_previous_char = current > 1 ? stmt[current - 2] : nil
          next_char = stmt[current + 1]?

          if paren_depth == 0 && bracket_depth == 0 && brace_depth == 0
            operator = nil
            lhs_end = current

            if previous_char == '<' && previous_previous_char == '<' && next_char != '='
              operator = "<<="
              lhs_end = current - 2
            elsif previous_char == '>' && previous_previous_char == '>' && next_char != '='
              operator = ">>="
              lhs_end = current - 2
            elsif previous_char != '!' && previous_char != '<' && previous_char != '>' && previous_char != '=' &&
                  next_char != '='
              operator = "="

              if previous_char == '+' || previous_char == '-' || previous_char == '*' || previous_char == '/' ||
                 previous_char == '&' || previous_char == '|' || previous_char == '^'
                operator = "#{previous_char}="
                lhs_end = current - 1

                if previous_previous_char == previous_char
                  current += 1
                  next
                end
              end
            end

            if operator
              lhs = stmt[0...lhs_end].strip
              rhs = stmt[current + 1...stmt.size].strip
              return nil if lhs.empty? || rhs.empty?

              return {lhs: lhs, rhs: rhs, operator: operator}
            end
          end
        end

        current += 1
      end

      nil
    end
  end
end
