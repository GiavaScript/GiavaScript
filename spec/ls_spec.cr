require "./spec_helper"

describe Ls do
  it "assigns integer values" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 5;").should eq([] of String)
    interpreter.eval("a;").should eq(["a = 5"])
  end

  it "prints error when assigning undeclared variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("a = 5;").should eq(["Error: variable 'a' does not exist"])
  end

  it "prints error when redeclaring variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 5;").should eq([] of String)
    interpreter.eval("var a = 6;").should eq(["Error: variable 'a' already exists"])
  end

  it "supports declarations without initializer" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a;").should eq([] of String)
    interpreter.eval("a;").should eq(["a = undefined"])
  end

  it "assigns from another variable" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 5; var another_value = a;").should eq([] of String)
    interpreter.eval("another_value;").should eq(["another_value = 5"])
  end

  it "assigns string values" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = \"hello world!\";").should eq([] of String)
    interpreter.eval("a;").should eq(["a = \"hello world!\""])
  end

  it "assigns single-quoted string values" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 'hello world!';").should eq([] of String)
    interpreter.eval("a;").should eq(["a = \"hello world!\""])
  end

  it "assigns string values from another variable" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = \"hello\"; var b = a;").should eq([] of String)
    interpreter.eval("b;").should eq(["b = \"hello\""])
  end

  it "evaluates integer arithmetic" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var result = 2 + 3 * 4;").should eq([] of String)
    interpreter.eval("result;").should eq(["result = 14"])
  end

  it "evaluates power expressions" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("2^2;").should eq(["4"])
    interpreter.eval("2^3;").should eq(["8"])
  end

  it "uses right associativity for power" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("2^3^2;").should eq(["512"])
  end

  it "evaluates modulo expressions" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("10 % 3;").should eq(["1"])
  end

  it "prints expression result without assignment" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("2 + 3 * 4;").should eq(["14"])
  end

  it "prints expression result using variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 5;").should eq([] of String)
    interpreter.eval("a + 1;").should eq(["6"])
  end

  it "prints string literal result without assignment" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("\"hello world!\";").should eq(["\"hello world!\""])
  end

  it "concatenates string literals" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("\"hello\" + \" world\";").should eq(["\"hello world\""])
  end

  it "concatenates string variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = \"hello\"; var b = \" world\"; var c = a + b;").should eq([] of String)
    interpreter.eval("c;").should eq(["c = \"hello world\""])
  end

  it "concatenates string with number using coercion" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("\"count: \" + 5;").should eq(["\"count: 5\""])
  end

  it "concatenates number with string using coercion" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("5 + \" items\";").should eq(["\"5 items\""])
  end

  it "evaluates float arithmetic" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var ratio = 7 / 2;").should eq([] of String)
    interpreter.eval("ratio;").should eq(["ratio = 3.5"])
  end

  it "supports mixed arithmetic with variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 10; var b = 2.5; var c = (a - 2) * b;").should eq([] of String)
    interpreter.eval("c;").should eq(["c = 20.0"])
  end

  it "prints error for division by zero" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var x = 4 / 0;").should eq(["Error: division by zero"])
  end

  it "prints error for modulo by zero" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var x = 4 % 0;").should eq(["Error: modulo by zero"])
  end

  it "prints error for invalid arithmetic" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var x = 5 + ;").should eq(["Error: invalid right-hand side '5 +'"])
  end

  it "supports mixed concatenation in assignments" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = 7; var x = \"value=\" + value;").should eq([] of String)
    interpreter.eval("x;").should eq(["x = \"value=7\""])
  end

  it "keeps dollar signs as plain string content" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("\"cost is $5\";").should eq(["\"cost is $5\""])
  end

  it "supports escaping quote delimiters" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("\"a \\\"quote\\\"\";").should eq(["\"a \\\"quote\\\"\""])
    interpreter.eval("'a \\\'quote\\\'';").should eq(["\"a 'quote'\""])
  end

  it "defines functions and reads outer values" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var outside_value = 0;\nfunction sum_numbers(a, b) {\n  return a + b + outside_value;\n}\nvar result = sum_numbers(2, 3);").should eq([] of String)
    interpreter.eval("result;").should eq(["result = 5"])
  end

  it "keeps function variables local" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function get_local() {\n  var temp = 10;\n  return temp;\n}").should eq([] of String)
    interpreter.eval("get_local();").should eq(["10"])
    interpreter.eval("temp;").should eq(["Error: variable 'temp' does not exist"])
  end

  it "uses latest outer values when calling functions" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var outside_value = 1;\nfunction from_outside() {\n  return outside_value;\n}\noutside_value = 9;").should eq([] of String)
    interpreter.eval("from_outside();").should eq(["9"])
  end

  it "prints error for return outside functions" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("return 5;").should eq(["Error: return can only be used inside functions"])
  end

  it "handles explicit undefined returns" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function no_return() {\n  var a = 1;\n  return;\n}").should eq([] of String)
    interpreter.eval("no_return();").should eq(["undefined"])
  end

  it "allows assigning from a function with empty return" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function no_return() {\n  return;\n}").should eq([] of String)
    interpreter.eval("var x = no_return();").should eq([] of String)
    interpreter.eval("x;").should eq(["x = undefined"])
  end

  it "returns undefined when function has no return" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function no_return() {\n  var a = 1;\n}").should eq([] of String)
    interpreter.eval("no_return();").should eq(["undefined"])
  end

  it "prints error when print is not defined" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("print(\"hello world\");").should eq(["Error: function 'print' does not exist"])
  end

  it "prints error when len is not defined" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("len(\"hello\");").should eq(["Error: function 'len' does not exist"])
  end

  it "supports null as a value" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = null;").should eq([] of String)
    interpreter.eval("value;").should eq(["value = null"])
  end

  it "supports undefined as a value" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = undefined;").should eq([] of String)
    interpreter.eval("value;").should eq(["value = undefined"])
  end

  it "rejects legacy nil literal" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = nil;").should eq(["Error: variable 'nil' does not exist"])
  end

  it "prints null in strings as plain content" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = null;").should eq([] of String)
    interpreter.eval("\"value is value\";").should eq(["\"value is value\""])
  end

  it "prints undefined in strings as plain content" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = undefined;").should eq([] of String)
    interpreter.eval("\"value is value\";").should eq(["\"value is value\""])
  end

  it "allows statements without trailing semicolons" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 1").should eq([] of String)
    interpreter.eval("a").should eq(["a = 1"])
  end

  it "splits newline-separated statements without semicolons" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 1\nvar b = a + 2\nb").should eq(["b = 3"])
  end

  it "defines functions with braced bodies" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function sum_numbers(a, b) {\n  return a + b;\n}").should eq([] of String)
    interpreter.eval("sum_numbers(2, 3);").should eq(["5"])
  end

  it "rejects legacy end-based function syntax" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function sum_numbers(a, b)\n  return a + b;\nend").should eq(["Error: invalid function definition"])
  end

  it "prints error for missing variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("missing;").should eq(["Error: variable 'missing' does not exist"])
  end
end
