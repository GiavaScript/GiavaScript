require "./giavascript"

def run_file(path : String) : Int32
  source = begin
    File.read(path)
  rescue ex : File::NotFoundError
    STDERR.puts "Error: file not found '#{path}'"
    return 1
  rescue ex : File::Error
    STDERR.puts "Error: could not read file '#{path}': #{ex.message}"
    return 1
  end

  if source.strip.empty?
    STDERR.puts "Error: file '#{path}' is empty"
    return 1
  end

  interpreter = GiavaScript::Interpreter.new
  messages = interpreter.eval(source)

  messages.each do |message|
    if message.starts_with?("Error:")
      STDERR.puts "#{path}: #{message}"
    else
      puts message
    end
  end

  has_errors = messages.any? { |message| message.starts_with?("Error:") }
  has_errors ? 1 : 0
end

if ARGV.empty?
  GiavaScript::Interpreter.new.repl
elsif ARGV.size == 1
  exit run_file(ARGV[0])
else
  STDERR.puts "Usage: crystal run src/giavascript_cli.cr -- [path/to/file.js]"
  exit 1
end
