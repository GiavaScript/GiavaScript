require "./spec_helper"

describe "REPL" do
  it "retains input history for the session" do
    input = IO::Memory.new("1 + 1\n.history\n.exit\n")
    output = IO::Memory.new

    GiavaScript::Interpreter.new.repl(input, output)

    output.to_s.should contain("1 + 1")
  end

  it "supports multi-line blocks and functions" do
    input = IO::Memory.new("function f() {\n  return 7;\n}\nf()\n.exit\n")
    output = IO::Memory.new

    GiavaScript::Interpreter.new.repl(input, output)

    output.to_s.should contain("7")
  end

  it "documents commands with .help" do
    input = IO::Memory.new(".help\n.exit\n")
    output = IO::Memory.new

    GiavaScript::Interpreter.new.repl(input, output)

    output.to_s.should contain(".history")
    output.to_s.should contain(".exit")
  end

  it "exits on :quit without evaluating later lines" do
    input = IO::Memory.new("1 + 1\n:quit\n2 + 2\n")
    output = IO::Memory.new

    GiavaScript::Interpreter.new.repl(input, output)

    output.to_s.should contain("2")
    output.to_s.should_not contain("4")
  end

  it "writes errors to the error stream" do
    input = IO::Memory.new("missing\n.exit\n")
    output = IO::Memory.new
    error_output = IO::Memory.new

    GiavaScript::Interpreter.new.repl(input, output, error_output)

    error_output.to_s.should contain("error:")
    output.to_s.should_not contain("error:")
  end
end
