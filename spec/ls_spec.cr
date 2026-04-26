require "./spec_helper"

describe Ls do
  it "assigns integer values" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 5;").should eq([] of String)
    interpreter.eval("a;").should eq(["5"])
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
    interpreter.eval("a;").should eq(["undefined"])
  end

  it "assigns from another variable" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 5; var anotherValue = a;").should eq([] of String)
    interpreter.eval("anotherValue;").should eq(["5"])
  end

  it "assigns string values" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = \"hello world!\";").should eq([] of String)
    interpreter.eval("a;").should eq(["\"hello world!\""])
  end

  it "assigns single-quoted string values" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 'hello world!';").should eq([] of String)
    interpreter.eval("a;").should eq(["\"hello world!\""])
  end

  it "assigns string values from another variable" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = \"hello\"; var b = a;").should eq([] of String)
    interpreter.eval("b;").should eq(["\"hello\""])
  end

  it "evaluates integer arithmetic" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var result = 2 + 3 * 4;").should eq([] of String)
    interpreter.eval("result;").should eq(["14"])
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
    interpreter.eval("c;").should eq(["\"hello world\""])
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
    interpreter.eval("ratio;").should eq(["3.5"])
  end

  it "evaluates relational operators" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("1 < 2;").should eq(["true"])
    interpreter.eval("3 > 5;").should eq(["false"])
    interpreter.eval("(1 + 2) > 2;").should eq(["true"])
  end

  it "coerces numeric strings in relational comparisons" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("\"10\" > 9;").should eq(["true"])
    interpreter.eval("9 < \"10\";").should eq(["true"])
  end

  it "returns false for non-numeric string and number comparisons" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("\"text\" > 10;").should eq(["false"])
    interpreter.eval("\"text\" < 10;").should eq(["false"])
  end

  it "evaluates equality operators for numbers and booleans" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("4 == 4;").should eq(["true"])
    interpreter.eval("4 != 4;").should eq(["false"])
    interpreter.eval("true == false;").should eq(["false"])
  end

  it "uses comparison and equality precedence correctly" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("1 + 2 > 2 == true;").should eq(["true"])
  end

  it "prints error for incompatible relational comparisons" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("1 < true;").should eq(["Error: operator '<' requires numeric operands"])
  end

  it "prints error for incompatible equality comparisons" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("true == 1;").should eq(["Error: operator '==' requires both operands to be numbers or both operands to be booleans"])
  end

  it "supports mixed arithmetic with variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 10; var b = 2.5; var c = (a - 2) * b;").should eq([] of String)
    interpreter.eval("c;").should eq(["20.0"])
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
    interpreter.eval("x;").should eq(["\"value=7\""])
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
    interpreter.eval("var outsideValue = 0;\nfunction sumNumbers(a, b) {\n  return a + b + outsideValue;\n}\nvar result = sumNumbers(2, 3);").should eq([] of String)
    interpreter.eval("result;").should eq(["5"])
  end

  it "keeps function variables local" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function getLocal() {\n  var temp = 10;\n  return temp;\n}").should eq([] of String)
    interpreter.eval("getLocal();").should eq(["10"])
    interpreter.eval("temp;").should eq(["Error: variable 'temp' does not exist"])
  end

  it "uses latest outer values when calling functions" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var outsideValue = 1;\nfunction fromOutside() {\n  return outsideValue;\n}\noutsideValue = 9;").should eq([] of String)
    interpreter.eval("fromOutside();").should eq(["9"])
  end

  it "prints error for return outside functions" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("return 5;").should eq(["Error: return can only be used inside functions"])
  end

  it "handles explicit undefined returns" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function noReturn() {\n  var a = 1;\n  return;\n}").should eq([] of String)
    interpreter.eval("noReturn();").should eq(["undefined"])
  end

  it "allows assigning from a function with empty return" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function noReturn() {\n  return;\n}").should eq([] of String)
    interpreter.eval("var x = noReturn();").should eq([] of String)
    interpreter.eval("x;").should eq(["undefined"])
  end

  it "returns undefined when function has no return" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function noReturn() {\n  var a = 1;\n}").should eq([] of String)
    interpreter.eval("noReturn();").should eq(["undefined"])
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
    interpreter.eval("value;").should eq(["null"])
  end

  it "supports undefined as a value" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = undefined;").should eq([] of String)
    interpreter.eval("value;").should eq(["undefined"])
  end

  it "supports heterogeneous array literals" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("[\"a\", 1, 2.5];").should eq(["[\"a\", 1, 2.5]"])
  end

  it "supports empty arrays and nested arrays" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("[];").should eq(["[]"])
    interpreter.eval("[1, [2, 3], []];").should eq(["[1, [2, 3], []]"])
  end

  it "supports zero-based array indexing" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var r = [10, 20, 30];").should eq([] of String)
    interpreter.eval("r[0];").should eq(["10"])
    interpreter.eval("r[2];").should eq(["30"])
  end

  it "supports indexing nested arrays" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var r = [1, [2, 3], []];").should eq([] of String)
    interpreter.eval("r[1][0];").should eq(["2"])
  end

  it "supports assigning to existing array indexes" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var alreadyDeclaredArray = [10, 20, 30];").should eq([] of String)
    interpreter.eval("alreadyDeclaredArray[0] = 42;").should eq([] of String)
    interpreter.eval("alreadyDeclaredArray;").should eq(["[42, 20, 30]"])
  end

  it "returns undefined for out-of-range array indexes" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var r = [10, 20, 30];").should eq([] of String)
    interpreter.eval("r[3];").should eq(["undefined"])
    interpreter.eval("r[-1];").should eq(["undefined"])
    interpreter.eval("r[1.5];").should eq(["Error: array index must be an integer"])
  end

  it "supports object literals with dot and bracket property access" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var o = { a: 10, b: 2 };").should eq([] of String)
    interpreter.eval("o.a;").should eq(["10"])
    interpreter.eval("o[\"a\"];").should eq(["10"])
  end

  it "supports empty and nested objects" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("{};").should eq(["{}"])
    interpreter.eval("var o = { x: { y: [1, 2, 3] } };").should eq([] of String)
    interpreter.eval("o.x.y[2];").should eq(["3"])
  end

  it "prints objects using colon notation" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("{ a: 1, nested: { b: 2 } };").should eq(["{\"a\": 1, \"nested\": {\"b\": 2}}"])
    interpreter.eval("[{ a: 1 }];").should eq(["[{\"a\": 1}]"])
  end

  it "supports heterogeneous object values and key normalization" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var o = { aKeyValue: 12, \"another-key\": \"some text here\", 99: \"ninety nine\", \"an-object\": { \"something-inside\": [1, 2, 3] } };").should eq([] of String)
    interpreter.eval("o.aKeyValue;").should eq(["12"])
    interpreter.eval("o[\"another-key\"];").should eq(["\"some text here\""])
    interpreter.eval("o[\"99\"];").should eq(["\"ninety nine\""])
    interpreter.eval("o[\"an-object\"][\"something-inside\"][1];").should eq(["2"])
  end

  it "supports numeric key lookup with bracket expressions" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var o = { 99: \"ninety nine\" }; var k = 99;").should eq([] of String)
    interpreter.eval("o[k];").should eq(["\"ninety nine\""])
  end

  it "returns undefined for missing object properties" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var o = { a: 10 };").should eq([] of String)
    interpreter.eval("o.b;").should eq(["undefined"])
    interpreter.eval("o[\"missing\"];").should eq(["undefined"])
    interpreter.eval("o[true];").should eq(["Error: object property key must be a string or number"])
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
    interpreter.eval("a").should eq(["1"])
  end

  it "splits newline-separated statements without semicolons" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var a = 1\nvar b = a + 2\nb").should eq(["3"])
  end

  it "defines functions with braced bodies" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function sumNumbers(a, b) {\n  return a + b;\n}").should eq([] of String)
    interpreter.eval("sumNumbers(2, 3);").should eq(["5"])
  end

  it "rejects legacy end-based function syntax" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("function sumNumbers(a, b)\n  return a + b;\nend").should eq(["Error: invalid function definition"])
  end

  it "runs if branch when condition is truthy" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = 1; if (value) value = 2;").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "runs else branch when condition is falsy" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = 0; if (value) value = 2; else value = 3;").should eq([] of String)
    interpreter.eval("value;").should eq(["3"])
  end

  it "supports if without else" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = 4; if (0) value = 8;").should eq([] of String)
    interpreter.eval("value;").should eq(["4"])
  end

  it "supports braced blocks in if statements" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = 0; if (1) { value = 9; }").should eq([] of String)
    interpreter.eval("value;").should eq(["9"])
  end

  it "supports braced blocks in else statements" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = 0; if (0) { value = 1; } else { value = 7; }").should eq([] of String)
    interpreter.eval("value;").should eq(["7"])
  end

  it "supports nested if with dangling else" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("var value = 0; if (1) if (0) value = 1; else value = 2;").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "returns error for invalid if syntax" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("if value) value = 1;").should eq(["Error: invalid if statement"])
  end

  it "prints error for missing variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("missing;").should eq(["Error: variable 'missing' does not exist"])
  end
end
