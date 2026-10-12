require "./spec_helper"

private def with_cli_temp_file(content : String, &)
  file = File.tempfile("giavascript_cli_spec", ".js")
  file.print(content)
  file.flush
  begin
    yield file.path
  ensure
    path = file.path
    file.close
    File.delete(path) if File.exists?(path)
  end
end

describe GiavaScript::CLI do
  it "evaluates a snippet with -e" do
    stdout = IO::Memory.new
    status = GiavaScript::CLI.run(["-e", "1 + 1"], IO::Memory.new, stdout, IO::Memory.new)
    status.should eq(0)
    stdout.to_s.should eq("2\n")
  end

  it "returns non-zero for a syntax error with -e" do
    stderr = IO::Memory.new
    status = GiavaScript::CLI.run(["--eval", "1 +"], IO::Memory.new, IO::Memory.new, stderr)
    status.should eq(1)
    stderr.to_s.should contain("error:")
  end

  it "prints the version" do
    stdout = IO::Memory.new
    status = GiavaScript::CLI.run(["--version"], IO::Memory.new, stdout, IO::Memory.new)
    status.should eq(0)
    stdout.to_s.strip.should eq(GiavaScript::VERSION)
  end

  it "runs a file" do
    with_cli_temp_file("1 + 1") do |path|
      stdout = IO::Memory.new
      status = GiavaScript::CLI.run([path], IO::Memory.new, stdout, IO::Memory.new)
      status.should eq(0)
      stdout.to_s.should eq("2\n")
    end
  end

  it "checks a valid file without running it" do
    with_cli_temp_file("var total = 0;\nfor (var i = 0; i < 3; i++) { total += i; }\nfunction f() { return total; }") do |path|
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      status = GiavaScript::CLI.run(["--check", path], IO::Memory.new, stdout, stderr)
      status.should eq(0)
      stdout.to_s.empty?.should be_true
      stderr.to_s.empty?.should be_true
    end
  end

  it "reports syntax errors without running the file" do
    with_cli_temp_file("console.log('should not run');\nvar broken = ;") do |path|
      stdout = IO::Memory.new
      stderr = IO::Memory.new
      status = GiavaScript::CLI.run(["--check", path], IO::Memory.new, stdout, stderr)
      status.should eq(1)
      stderr.to_s.should contain("Error")
      stdout.to_s.empty?.should be_true
    end
  end

  it "reports a missing file" do
    stderr = IO::Memory.new
    status = GiavaScript::CLI.run(["/definitely/not/here.js"], IO::Memory.new, IO::Memory.new, stderr)
    status.should eq(1)
    stderr.to_s.should contain("file not found")
  end
end
