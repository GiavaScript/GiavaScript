module GiavaScript
  class LineEditor
    def initialize(@input : IO = STDIN, @output : IO = STDOUT)
      @history = [] of String
    end

    def history : Array(String)
      @history
    end

    def read_line(prompt : String) : String?
      if interactive?
        read_line_interactive(prompt)
      else
        read_line_plain(prompt)
      end
    end

    private def interactive? : Bool
      @input.is_a?(IO::FileDescriptor) && @input.tty?
    end

    private def read_line_plain(prompt : String) : String?
      @output.print prompt
      @output.flush
      line = @input.gets
      return nil if line.nil?

      line = line.chomp
      record_history(line)
      line
    end

    private def record_history(line : String)
      return if line.strip.empty?
      return if !@history.empty? && @history.last == line

      @history << line
    end

    {% if flag?(:unix) %}
      private def read_line_interactive(prompt : String) : String?
        buffer = ""
        position = @history.size

        @output.print prompt
        @output.flush

        with_raw_mode do
          loop do
            byte = @input.read_byte
            return nil unless byte

            case byte
            when 13_u8, 10_u8
              @output.print "\r\n"
              @output.flush
              record_history(buffer)
              return buffer
            when 8_u8, 127_u8
              unless buffer.empty?
                buffer = buffer[0, buffer.size - 1]
                @output.print "\b \b"
                @output.flush
              end
            when 3_u8
              @output.print "\r\n"
              @output.flush
              return ""
            when 4_u8
              return nil if buffer.empty?
              @output.print "\r\n"
              @output.flush
              record_history(buffer)
              return buffer
            when 27_u8
              case read_escape_sequence
              when :up
                if position > 0
                  position -= 1
                  buffer = @history[position]
                  redraw(prompt, buffer)
                end
              when :down
                if position < @history.size
                  position += 1
                  buffer = position < @history.size ? @history[position] : ""
                  redraw(prompt, buffer)
                end
              end
            else
              if byte >= 32_u8 && byte < 127_u8
                buffer += byte.chr.to_s
                @output.print byte.chr
                @output.flush
              end
            end
          end
        end
      end

      private def read_escape_sequence : Symbol?
        first = @input.read_byte
        return nil unless first == 91_u8

        case @input.read_byte
        when 65_u8 then :up
        when 66_u8 then :down
        when 67_u8 then :right
        when 68_u8 then :left
        end
      end

      private def redraw(prompt : String, buffer : String)
        @output.print "\r\e[2K#{prompt}#{buffer}"
        @output.flush
      end

      private def with_raw_mode(&)
        fd = @input.as(IO::FileDescriptor).fd
        original = uninitialized LibC::Termios
        return yield unless LibC.tcgetattr(fd, pointerof(original)) == 0

        raw = original
        LibC.cfmakeraw(pointerof(raw))
        LibC.tcsetattr(fd, LibC::TCSANOW, pointerof(raw))

        begin
          yield
        ensure
          LibC.tcsetattr(fd, LibC::TCSANOW, pointerof(original))
        end
      end
    {% else %}
      private def read_line_interactive(prompt : String) : String?
        read_line_plain(prompt)
      end
    {% end %}
  end
end
