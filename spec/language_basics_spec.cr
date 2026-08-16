require "./spec_helper"

describe GiavaScript do
  it "assigns integer values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 5;").should eq([] of String)
    interpreter.eval("a;").should eq(["5"])
  end

  it "prints error when assigning undeclared variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("a = 5;").should eq(["Error: variable 'a' does not exist"])
  end

  it "prints error when redeclaring variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 5;").should eq([] of String)
    interpreter.eval("var a = 6;").should eq(["Error: variable 'a' already exists"])
  end

  it "supports declarations without initializer" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a;").should eq([] of String)
    interpreter.eval("a;").should eq(["undefined"])
  end

  it "assigns from another variable" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 5; var anotherValue = a;").should eq([] of String)
    interpreter.eval("anotherValue;").should eq(["5"])
  end

  it "supports single-line comments" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var a = 1; // set a\nvar b = 2; // set b\na + b;").should eq(["3"])
  end

  it "supports multi-line comments" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var a = 1; /* comment with ; and } and // */ var b = 2; a + b;").should eq(["3"])
  end

  it "ignores comment markers inside strings" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("\"//not a comment\";").should eq(["\"//not a comment\""])
    interpreter.eval("\"/*not a comment*/\";").should eq(["\"/*not a comment*/\""])
  end

  it "reports unterminated multi-line comments" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var a = 1; /* missing end").should eq(["Error: unterminated block comment"])
  end

  it "supports comments in if and else control flow" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var x = 0; if /*cond*/ (true) { x = 1; } else { x = 2; } x;").should eq(["1"])
  end

  it "supports comments in for-loop headers and bodies" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var total = 0; for (var i = 0; /*cond*/ i < 3; /*step*/ i++) { total += i; // add i\n } total;").should eq(["3"])
  end

  it "supports typeof for primitive and object values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("typeof undefined;").should eq(["\"undefined\""])
    interpreter.eval("typeof null;").should eq(["\"object\""])
    interpreter.eval("typeof true;").should eq(["\"boolean\""])
    interpreter.eval("typeof 42;").should eq(["\"number\""])
    interpreter.eval("typeof 'hello';").should eq(["\"string\""])
    interpreter.eval("typeof [1, 2, 3];").should eq(["\"object\""])
    interpreter.eval("typeof { a: 1 };").should eq(["\"object\""])
  end

  it "returns function for typeof callable values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function sum(a, b) { return a + b; }").should eq([] of String)
    interpreter.eval("typeof sum;").should eq(["\"function\""])
    interpreter.eval("typeof console.log;").should eq(["\"function\""])
  end

  it "returns undefined for typeof undeclared identifiers" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("typeof missingValue;").should eq(["\"undefined\""])
  end

  it "supports void and always returns undefined" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("void 42;").should eq(["undefined"])
    interpreter.eval("void 'hello';").should eq(["undefined"])
    interpreter.eval("void missingValue;").should eq(["Error: variable 'missingValue' does not exist"])
  end

  it "evaluates void operand for side effects" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)
    interpreter.eval("void console.log('side-effect');").should eq(["undefined"])
    output.to_s.should eq("side-effect\n")
  end

  it "evaluates relational operators" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("1 < 2;").should eq(["true"])
    interpreter.eval("3 > 5;").should eq(["false"])
    interpreter.eval("(1 + 2) > 2;").should eq(["true"])
  end

  it "coerces numeric strings in relational comparisons" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"10\" > 9;").should eq(["true"])
    interpreter.eval("9 < \"10\";").should eq(["true"])
  end

  it "returns false for non-numeric string and number comparisons" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"text\" > 10;").should eq(["false"])
    interpreter.eval("\"text\" < 10;").should eq(["false"])
  end

  it "evaluates equality operators for numbers and booleans" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("4 == 4;").should eq(["true"])
    interpreter.eval("4 != 4;").should eq(["false"])
    interpreter.eval("true == false;").should eq(["false"])
  end

  it "evaluates strict equality and inequality operators" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("4 === 4;").should eq(["true"])
    interpreter.eval("4 === \"4\";").should eq(["false"])
    interpreter.eval("true !== 1;").should eq(["true"])
    interpreter.eval("null === null;").should eq(["true"])
    interpreter.eval("undefined === undefined;").should eq(["true"])
    interpreter.eval("null === undefined;").should eq(["false"])
  end

  it "compares references with strict equality" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var arr = [1]; var same = arr; var other = [1];").should eq([] of String)
    interpreter.eval("arr === same;").should eq(["true"])
    interpreter.eval("arr === other;").should eq(["false"])
  end

  it "returns false for NaN strict equality" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var nan = +undefined;").should eq([] of String)
    interpreter.eval("nan === nan;").should eq(["false"])
  end

  it "uses comparison and equality precedence correctly" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("1 + 2 > 2 == true;").should eq(["true"])
  end

  it "uses comparison and strict equality precedence correctly" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("1 + 2 > 2 === true;").should eq(["true"])
  end

  it "prints error for incompatible relational comparisons" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("1 < true;").should eq(["Error: operator '<' requires numeric operands"])
  end

  it "coerces loose equality comparisons like vintage JavaScript" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("true == 1;").should eq(["true"])
    interpreter.eval("false == 0;").should eq(["true"])
    interpreter.eval("\"42\" == 42;").should eq(["true"])
    interpreter.eval("\"\" == 0;").should eq(["true"])
    interpreter.eval("null == undefined;").should eq(["true"])
    interpreter.eval("\"text\" == 0;").should eq(["false"])
    interpreter.eval("\"1\" != 1;").should eq(["false"])
  end

  it "coerces array and object values for loose equality" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[] == 0;").should eq(["true"])
    interpreter.eval("[1] == 1;").should eq(["true"])
    interpreter.eval("[1,2] == \"1,2\";").should eq(["true"])
    interpreter.eval("({}) == \"[object Object]\";").should eq(["true"])
  end

  it "supports null as a value" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = null;").should eq([] of String)
    interpreter.eval("value;").should eq(["null"])
  end

  it "supports undefined as a value" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = undefined;").should eq([] of String)
    interpreter.eval("value;").should eq(["undefined"])
  end

  it "falls back from object properties to type methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("{ a: 1 }.a;").should eq(["1"])
    interpreter.eval("true.toString;").should eq(["[builtin Bool.toString]"])
    interpreter.eval("true.toString();").should eq(["\"true\""])
  end

  it "rejects property access on undefined and null" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("undefined.foo;").should eq(["Error: cannot access property 'foo' of undefined"])
    interpreter.eval("null.bar;").should eq(["Error: cannot access property 'bar' of null"])
  end

  it "rejects legacy nil literal" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = nil;").should eq(["Error: variable 'nil' does not exist"])
  end

  it "keeps identifiers in strings as plain content" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"value is value\";").should eq(["\"value is value\""])
  end

  it "allows statements without trailing semicolons" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 1").should eq([] of String)
    interpreter.eval("a").should eq(["1"])
  end

  it "splits newline-separated statements without semicolons" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 1\nvar b = a + 2\nb").should eq(["3"])
  end

  it "rejects legacy end-based function syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function sumNumbers(a, b)\n  return a + b;\nend").should eq(["Error: invalid function definition"])
  end

  it "rejects unsupported declarations" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("let value = 1;").should eq(["Error: unsupported declaration 'let'"])
    interpreter.eval("const total = 2;").should eq(["Error: unsupported declaration 'const'"])
  end

  it "rejects class declarations" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("class Person {}").should eq(["Error: invalid right-hand side 'class Person {}'"])
  end

  it "rejects module import and export statements" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("import value from \"mod\";").should eq(["Error: invalid import statement — expected import \"file.js\""])
    interpreter.eval("export default 1;").should eq(["Error: invalid right-hand side 'export default 1'"])
  end

  it "rejects async and await syntax" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("async function load() {}").should eq(["Error: invalid right-hand side 'async function load() {}'"])
    interpreter.eval("await load();").should eq(["Error: invalid right-hand side 'await load()'"])
  end

  it "returns errors for invalid control-flow syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("if value) value = 1;").should eq(["Error: invalid if statement"])
    interpreter.eval("for (var i = 0 i < 3; i = i + 1) console.log(i);").should eq(["Error: invalid for statement"])
    interpreter.eval("while value) value = 1;").should eq(["Error: invalid while statement"])
    interpreter.eval("do value = 1; while value);").should eq(["Error: invalid do...while statement"])
    interpreter.eval("switch value) { case 1: value = 1; }").should eq(["Error: invalid switch statement"])
    interpreter.eval("try { var value = 1; }").should eq(["Error: invalid try statement"])
  end

  it "prints error for missing variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("missing;").should eq(["Error: variable 'missing' does not exist"])
  end
end

describe "VERSION" do
  it "is a non-empty string" do
    GiavaScript::VERSION.is_a?(String).should be_true
    GiavaScript::VERSION.empty?.should be_false
  end

  it "matches shard.yml version" do
    shard_yml = File.read(File.join(__DIR__, "..", "shard.yml"))
    version_line = shard_yml.lines.find { |line| line.starts_with?("version:") }
    version_line.should_not be_nil
    expected_version = version_line.not_nil!.split(":", 2).last.strip
    GiavaScript::VERSION.should eq(expected_version)
  end
end
