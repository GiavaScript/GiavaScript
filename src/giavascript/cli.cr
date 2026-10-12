module GiavaScript
  module CLI
    extend self

    def run(argv : Array(String), stdin : IO = STDIN, stdout : IO = STDOUT, stderr : IO = STDERR) : Int32
      if argv.empty?
        Interpreter.new(argv: argv, console_output: stdout).repl(stdin, stdout, stderr)
        return 0
      end

      first = argv[0]

      if argv.size == 1 && (first == "--version" || first == "-v")
        stdout.puts VERSION
        return 0
      end

      if argv.size >= 2 && (first == "--eval" || first == "-e")
        return run_source(argv[1], argv, stdout, stderr)
      end

      if argv.size >= 2 && first == "--check"
        return check_file(argv[1], stderr)
      end

      run_file(first, argv, stdout, stderr)
    end

    def run_file(path : String, argv : Array(String), stdout : IO = STDOUT, stderr : IO = STDERR) : Int32
      source = read_source(path, stderr)
      return 1 unless source

      interpreter = Interpreter.new(console_output: stdout, argv: argv)
      diagnostics = interpreter.eval_diagnostics(source)
      has_errors = false

      diagnostics.each do |diagnostic|
        if diagnostic.error?
          has_errors = true
          diagnostic.to_display(stderr, path, source)
        else
          stdout.puts diagnostic.message
        end
      end

      has_errors ? 1 : 0
    end

    def run_source(source : String, argv : Array(String), stdout : IO = STDOUT, stderr : IO = STDERR) : Int32
      interpreter = Interpreter.new(console_output: stdout, argv: argv)
      diagnostics = interpreter.eval_diagnostics(source)
      has_errors = false

      diagnostics.each do |diagnostic|
        if diagnostic.error?
          has_errors = true
          diagnostic.to_display(stderr, "eval", source)
        else
          stdout.puts diagnostic.message
        end
      end

      has_errors ? 1 : 0
    end

    def check_file(path : String, stderr : IO = STDERR) : Int32
      source = read_source(path, stderr)
      return 1 unless source

      errors = SyntaxChecker.new.errors(source)
      errors.each { |message| stderr.puts message }
      errors.empty? ? 0 : 1
    end

    private def read_source(path : String, stderr : IO) : String?
      source = begin
        File.read(path)
      rescue ex : File::NotFoundError
        stderr.puts "Error: file not found '#{path}'"
        return nil
      rescue ex : File::Error
        stderr.puts "Error: could not read file '#{path}': #{ex.message}"
        return nil
      end

      if source.strip.empty?
        stderr.puts "Error: file '#{path}' is empty"
        return nil
      end

      source
    end
  end
end
