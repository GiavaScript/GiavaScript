require "./spec_helper"

describe GiavaScript do
  it "prints error when print is not defined" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("print(\"hello world\");").should eq(["Error: function 'print' does not exist"])
  end

  it "provides console.log as a global built-in method" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("console.log(\"hello\");").should eq(["undefined"])
    output.to_s.should eq("hello\n")
  end

  it "provides process arguments, environment, and exit" do
    key = "GIAVASCRIPT_PROCESS_ENV_SPEC"
    previous = ENV[key]?
    ENV[key] = "host"

    begin
      interpreter = GiavaScript::Interpreter.new(argv: ["script.js", "one"])

      interpreter.eval("process.argv;").should eq(["[\"script.js\", \"one\"]"])
      interpreter.eval("process.env[\"#{key}\"];").should eq(["\"host\""])
      interpreter.eval("process.env[\"#{key}\"] = \"script\";").should eq([] of String)
      ENV[key].should eq("host")
      interpreter.eval("typeof process.exit;").should eq(["\"function\""])
      interpreter.eval("process.exit(1, 2);").should eq(["Error: process.exit expects between 0 and 1 arguments but got 2"])
      interpreter.eval("process.exit(\"1\");").should eq(["Error: process.exit argument 1 must be a number"])
    ensure
      if previous
        ENV[key] = previous
      else
        ENV.delete(key)
      end
    end
  end

  it "runs external commands synchronously with process.run" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval(%(var result = process.run("crystal", ["eval", "STDOUT.print \\"out\\"; STDERR.print \\"err\\"; exit 7"]);)).should eq([] of String)
    interpreter.eval("result.stdout;").should eq([%q("out")])
    interpreter.eval("result.stderr;").should eq([%q("err")])
    interpreter.eval("result.status;").should eq(["7"])
    interpreter.eval("process.run(1);").should eq(["Error: process.run argument 1 must be a string"])
    interpreter.eval(%(process.run("crystal", "--version");)).should eq(["Error: process.run argument 2 must be an array"])
    interpreter.eval(%(process.run("crystal", [1]);)).should eq(["Error: process.run argument 2 item 1 must be a string"])
    interpreter.eval(%(process.run("giavascript-command-that-does-not-exist");))[0].should start_with("Error: process.run failed - ")
  end

  it "prints all console.log arguments in readable format" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("console.log(\"value:\", 42, true);").should eq(["undefined"])
    output.to_s.should eq("value: 42 true\n")
  end

  it "raises runtime error when console.log is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("console.log = 5;").should eq([] of String)
    interpreter.eval("console.log();").should eq(["Error: value is not callable"])
  end

  it "provides console.warn as a global built-in method" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("console.warn(\"something\");").should eq(["undefined"])
    interpreter.eval("typeof console.warn;").should eq(["\"function\""])
  end

  it "provides console.error as a global built-in method" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("console.error(\"failure\");").should eq(["undefined"])
    interpreter.eval("typeof console.error;").should eq(["\"function\""])
  end

  it "supports variadic arguments for console.warn and console.error" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("console.warn(\"a\", 1, true);").should eq(["undefined"])
    interpreter.eval("console.error(\"x\", 2, false);").should eq(["undefined"])
  end

  it "provides JSON.parse and JSON.stringify as global built-in methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("JSON.parse(\"{\\\"a\\\":1,\\\"b\\\":[true,null,\\\"x\\\"]}\")[\"a\"];").should eq(["1"])
    interpreter.eval("JSON.parse(\"[1,2,3]\")[2];").should eq(["3"])
    interpreter.eval("JSON.stringify({\"a\":1,\"b\":[true,null,\"x\"]});").should eq(["\"{\\\"a\\\":1,\\\"b\\\":[true,null,\\\"x\\\"]}\""])
    interpreter.eval("JSON.stringify(undefined);").should eq(["undefined"])
  end

  it "matches basic JavaScript-like JSON.stringify omission and null rules" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var o = {\"a\": 1};").should eq([] of String)
    interpreter.eval("o[\"skip\"] = undefined;").should eq([] of String)
    interpreter.eval("JSON.stringify(o);").should eq(["\"{\\\"a\\\":1}\""])
    interpreter.eval("JSON.stringify([1, undefined, 3]);").should eq(["\"[1,null,3]\""])
    interpreter.eval("JSON.stringify([Math.max()]);").should eq(["\"[null]\""])
  end

  it "detects circular references in JSON.stringify" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var a = []; a[0] = a;").should eq([] of String)
    interpreter.eval("JSON.stringify(a);").should eq(["Error: JSON.stringify cannot serialize circular arrays"])
  end

  it "validates JSON builtin arity, argument types, and parse errors" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("JSON.parse();").should eq(["Error: JSON.parse expects 1 arguments but got 0"])
    interpreter.eval("JSON.stringify(1, 2);").should eq(["Error: JSON.stringify expects 1 arguments but got 2"])
    interpreter.eval("JSON.parse(5);").should eq(["Error: JSON.parse argument 1 must be a string"])
    interpreter.eval("JSON.parse(\"{\");").should eq(["Error: JSON.parse argument 1 must be valid JSON"])
  end

  it "raises runtime error when JSON method is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("JSON.parse = 5;").should eq([] of String)
    interpreter.eval("JSON.parse(\"{}\");").should eq(["Error: value is not callable"])
  end

  it "supports Date.now and new Date with basic instance methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var before = Date.now();").should eq([] of String)
    interpreter.eval("var d = new Date();").should eq([] of String)
    interpreter.eval("var after = Date.now();").should eq([] of String)
    interpreter.eval("d.getTime() >= before && d.getTime() <= after;").should eq(["true"])
    interpreter.eval("typeof d.toString() == \"string\" && d.toString().length > 0;").should eq(["true"])
  end

  it "validates Date arity and constructor behavior" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Date.now(1);").should eq(["Error: Date.now expects 0 arguments but got 1"])
    interpreter.eval("new Date(1);").should eq(["Error: Date expects 0 arguments but got 1"])
    interpreter.eval("new Math();").should eq(["Error: value is not a constructor"])
  end

  it "raises runtime error when Date static method is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Date.now = 5;").should eq([] of String)
    interpreter.eval("Date.now();").should eq(["Error: value is not callable"])
  end

  it "provides parseInt, parseFloat, and isNaN as global functions" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("parseInt(\"42\");").should eq(["42"])
    interpreter.eval("parseInt(\"  -15px\");").should eq(["-15"])
    interpreter.eval("parseInt(\"11\", 2);").should eq(["3"])
    interpreter.eval("parseInt(\"0x10\");").should eq(["16"])
    interpreter.eval("parseInt(\"foo\");").should eq(["NaN"])
    interpreter.eval("parseFloat(\"3.14abc\");").should eq(["3.14"])
    interpreter.eval("parseFloat(\"-2.5e2x\");").should eq(["-250.0"])
    interpreter.eval("parseFloat(\"foo\");").should eq(["NaN"])
    interpreter.eval("isNaN(\"foo\");").should eq(["true"])
    interpreter.eval("isNaN(\"123\");").should eq(["false"])
    interpreter.eval("isNaN(undefined);").should eq(["true"])
    interpreter.eval("isNaN(null);").should eq(["false"])
  end

  it "provides Number.isInteger as a global static method" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Number.isInteger(42);").should eq(["true"])
    interpreter.eval("Number.isInteger(3.14);").should eq(["false"])
    interpreter.eval("var nan = parseInt('foo'); Number.isInteger(nan);").should eq(["false"])
    interpreter.eval("Number.isInteger(\"42\");").should eq(["false"])
    interpreter.eval("Number.isInteger(null);").should eq(["false"])
  end

  it "provides Number.isFinite as a global static method" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Number.isFinite(42);").should eq(["true"])
    interpreter.eval("Number.isFinite(3.14);").should eq(["true"])
    interpreter.eval("var nan = parseInt('foo'); Number.isFinite(nan);").should eq(["false"])
    interpreter.eval("Number.isFinite(\"42\");").should eq(["false"])
  end

  it "provides Number.isNaN as a global static method" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var nan = parseInt('foo'); Number.isNaN(nan);").should eq(["true"])
    interpreter.eval("Number.isNaN(42);").should eq(["false"])
    interpreter.eval("Number.isNaN(\"hello\");").should eq(["false"])
    interpreter.eval("Number.isNaN(undefined);").should eq(["false"])
  end

  it "validates Number static method arity" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Number.isInteger();").should eq(["Error: Number.isInteger expects 1 arguments but got 0"])
    interpreter.eval("Number.isFinite();").should eq(["Error: Number.isFinite expects 1 arguments but got 0"])
    interpreter.eval("Number.isNaN();").should eq(["Error: Number.isNaN expects 1 arguments but got 0"])
  end

  it "validates parseInt, parseFloat, and isNaN arguments" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("parseInt();").should eq(["Error: parseInt expects between 1 and 2 arguments but got 0"])
    interpreter.eval("parseInt(\"10\", \"2\");").should eq(["Error: parseInt argument 2 must be a number"])
    interpreter.eval("parseInt(\"10\", 1);").should eq(["NaN"])
    interpreter.eval("parseFloat();").should eq(["Error: parseFloat expects 1 arguments but got 0"])
    interpreter.eval("isNaN();").should eq(["Error: isNaN expects 1 arguments but got 0"])
  end

  it "raises runtime error when parseInt is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("parseInt = 5;").should eq([] of String)
    interpreter.eval("parseInt(\"10\");").should eq(["Error: value is not callable"])
  end

  it "provides File.read and File.readLines as global built-in methods" do
    interpreter = GiavaScript::Interpreter.new

    content = interpreter.eval("File.read(\"spec/fixtures/sample.txt\");")[0]
    content.should eq("\"hello giava\\nline two\\n\"")

    lines = interpreter.eval("File.readLines(\"spec/fixtures/sample.txt\");")[0]
    lines.should eq("[\"hello giava\", \"line two\", \"\"]")
  end

  it "validates File builtin arity and argument types" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("File.read();").should eq(["Error: File.read expects 1 arguments but got 0"])
    interpreter.eval("File.read(1, 2);").should eq(["Error: File.read expects 1 arguments but got 2"])
    interpreter.eval("File.read(5);").should eq(["Error: File.read argument 1 must be a string"])
    interpreter.eval("File.readLines();").should eq(["Error: File.readLines expects 1 arguments but got 0"])
    interpreter.eval("File.readLines(true);").should eq(["Error: File.readLines argument 1 must be a string"])
  end

  it "raises error for non-existent file path on File.read" do
    interpreter = GiavaScript::Interpreter.new

    result = interpreter.eval("File.read(\"nonexistent_file.txt\");")
    result[0].should start_with("Error: ")
  end

  it "raises runtime error when File method is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("File.read = 5;").should eq([] of String)
    interpreter.eval("File.read(\"foo\");").should eq(["Error: value is not callable"])
  end

  it "provides File.write as a global built-in method" do
    interpreter = GiavaScript::Interpreter.new
    test_path = "spec/fixtures/write_test.txt"

    interpreter.eval("File.write(\"#{test_path}\", \"hello write\");").should eq(["undefined"])
    interpreter.eval("File.read(\"#{test_path}\");").should eq(["\"hello write\""])
    ::File.delete(test_path) if ::File.exists?(test_path)
  end

  it "validates File.write arity and argument types" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("File.write();").should eq(["Error: File.write expects 2 arguments but got 0"])
    interpreter.eval("File.write(\"f\");").should eq(["Error: File.write expects 2 arguments but got 1"])
    interpreter.eval("File.write(5, \"c\");").should eq(["Error: File.write argument 1 must be a string"])
    interpreter.eval("File.write(\"f\", 5);").should eq(["Error: File.write argument 2 must be a string"])
  end

  it "provides File.append as a global built-in method" do
    interpreter = GiavaScript::Interpreter.new
    test_path = "spec/fixtures/append_test.txt"

    interpreter.eval("File.append(\"#{test_path}\", \"line one\\n\");").should eq(["undefined"])
    interpreter.eval("File.append(\"#{test_path}\", \"line two\\n\");").should eq(["undefined"])
    interpreter.eval("File.read(\"#{test_path}\");").should eq(["\"line one\\nline two\\n\""])
    ::File.delete(test_path) if ::File.exists?(test_path)
  end

  it "validates File.append arity and argument types" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("File.append();").should eq(["Error: File.append expects 2 arguments but got 0"])
    interpreter.eval("File.append(\"f\");").should eq(["Error: File.append expects 2 arguments but got 1"])
    interpreter.eval("File.append(5, \"c\");").should eq(["Error: File.append argument 1 must be a string"])
    interpreter.eval("File.append(\"f\", 5);").should eq(["Error: File.append argument 2 must be a string"])
  end

  it "supports import statement to include another file" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("import \"spec/fixtures/import_lib.js\";")
    interpreter.eval("libVar;").should eq(["\"hello from lib\""])
    interpreter.eval("libCount;").should eq(["42"])
    interpreter.eval("libFunction();").should eq(["\"called libFunction\""])
  end

  it "supports import inside a function to share scope" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("function testImport() { import \"spec/fixtures/import_lib.js\"; return libVar; }")
    interpreter.eval("testImport();").should eq(["\"hello from lib\""])
  end

  it "raises error for non-existent import file" do
    interpreter = GiavaScript::Interpreter.new

    result = interpreter.eval("import \"nonexistent.js\";")
    result[0].should start_with("Error: Error opening file")
  end

  it "raises error for non-string import path" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("import 42;").should eq(["Error: invalid import statement — expected import \"file.js\""])
  end

  it "prints error when len is not defined" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("len(\"hello\");").should eq(["Error: function 'len' does not exist"])
  end

end
