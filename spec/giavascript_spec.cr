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

  it "supports compound assignment operators" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 10; a += 5; a -= 3; a *= 2; a /= 4;").should eq([] of String)
    interpreter.eval("a;").should eq(["6.0"])
  end

  it "supports string concatenation with plus-equals" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = \"hello\"; a += \" world\";").should eq([] of String)
    interpreter.eval("a;").should eq(["\"hello world\""])
  end

  it "assigns string values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = \"hello world!\";").should eq([] of String)
    interpreter.eval("a;").should eq(["\"hello world!\""])
  end

  it "assigns single-quoted string values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 'hello world!';").should eq([] of String)
    interpreter.eval("a;").should eq(["\"hello world!\""])
  end

  it "assigns string values from another variable" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = \"hello\"; var b = a;").should eq([] of String)
    interpreter.eval("b;").should eq(["\"hello\""])
  end

  it "evaluates integer arithmetic" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var result = 2 + 3 * 4;").should eq([] of String)
    interpreter.eval("result;").should eq(["14"])
  end

  it "evaluates power expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("2^2;").should eq(["4"])
    interpreter.eval("2^3;").should eq(["8"])
  end

  it "uses right associativity for power" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("2^3^2;").should eq(["512"])
  end

  it "evaluates modulo expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("10 % 3;").should eq(["1"])
  end

  it "prints expression result without assignment" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("2 + 3 * 4;").should eq(["14"])
  end

  it "prints expression result using variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 5;").should eq([] of String)
    interpreter.eval("a + 1;").should eq(["6"])
  end

  it "prints string literal result without assignment" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world!\";").should eq(["\"hello world!\""])
  end

  it "concatenates string literals" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello\" + \" world\";").should eq(["\"hello world\""])
  end

  it "concatenates string variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = \"hello\"; var b = \" world\"; var c = a + b;").should eq([] of String)
    interpreter.eval("c;").should eq(["\"hello world\""])
  end

  it "concatenates string with number using coercion" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"count: \" + 5;").should eq(["\"count: 5\""])
  end

  it "concatenates number with string using coercion" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("5 + \" items\";").should eq(["\"5 items\""])
  end

  it "evaluates float arithmetic" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var ratio = 7 / 2;").should eq([] of String)
    interpreter.eval("ratio;").should eq(["3.5"])
  end

  it "supports unary plus numeric coercion" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("+\"42\";").should eq(["42.0"])
    interpreter.eval("+\"  3.5  \";").should eq(["3.5"])
    interpreter.eval("+true;").should eq(["1"])
    interpreter.eval("+false;").should eq(["0"])
    interpreter.eval("+null;").should eq(["0"])
    interpreter.eval("+undefined;").should eq(["NaN"])
  end

  it "supports banana unary plus expression" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("('b' + 'a' + + 'a' + 'a').toLowerCase();").should eq(["\"banana\""])
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

  it "supports mixed arithmetic with variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 10; var b = 2.5; var c = (a - 2) * b;").should eq([] of String)
    interpreter.eval("c;").should eq(["20.0"])
  end

  it "prints error for division by zero" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var x = 4 / 0;").should eq(["Error: division by zero"])
  end

  it "prints error for modulo by zero" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var x = 4 % 0;").should eq(["Error: modulo by zero"])
  end

  it "prints error for invalid arithmetic" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var x = 5 + ;").should eq(["Error: invalid right-hand side '5 +'"])
  end

  it "supports mixed concatenation in assignments" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 7; var x = \"value=\" + value;").should eq([] of String)
    interpreter.eval("x;").should eq(["\"value=7\""])
  end

  it "keeps dollar signs as plain string content" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"cost is $5\";").should eq(["\"cost is $5\""])
  end

  it "supports escaping quote delimiters" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"a \\\"quote\\\"\";").should eq(["\"a \\\"quote\\\"\""])
    interpreter.eval("'a \\'quote\\'';").should eq(["\"a 'quote'\""])
  end

  it "defines functions and reads outer values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var outsideValue = 0;\nfunction sumNumbers(a, b) {\n  return a + b + outsideValue;\n}\nvar result = sumNumbers(2, 3);").should eq([] of String)
    interpreter.eval("result;").should eq(["5"])
  end

  it "keeps function variables local" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function getLocal() {\n  var temp = 10;\n  return temp;\n}").should eq([] of String)
    interpreter.eval("getLocal();").should eq(["10"])
    interpreter.eval("temp;").should eq(["Error: variable 'temp' does not exist"])
  end

  it "uses latest outer values when calling functions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var outsideValue = 1;\nfunction fromOutside() {\n  return outsideValue;\n}\noutsideValue = 9;").should eq([] of String)
    interpreter.eval("fromOutside();").should eq(["9"])
  end

  it "prints error for return outside functions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("return 5;").should eq(["Error: return can only be used inside functions"])
  end

  it "handles explicit undefined returns" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function noReturn() {\n  var a = 1;\n  return;\n}").should eq([] of String)
    interpreter.eval("noReturn();").should eq(["undefined"])
  end

  it "allows assigning from a function with empty return" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function noReturn() {\n  return;\n}").should eq([] of String)
    interpreter.eval("var x = noReturn();").should eq([] of String)
    interpreter.eval("x;").should eq(["undefined"])
  end

  it "returns undefined when function has no return" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function noReturn() {\n  var a = 1;\n}").should eq([] of String)
    interpreter.eval("noReturn();").should eq(["undefined"])
  end

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

  it "provides Math.sqrt and Math.abs as global built-in methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Math.sqrt(9);").should eq(["3.0"])
    interpreter.eval("Math.abs(-5);").should eq(["5"])
    interpreter.eval("Math.abs(-2.5);").should eq(["2.5"])
  end

  it "provides basic Math rounding and utility methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Math.acos(1);").should eq(["0.0"])
    interpreter.eval("Math.asin(0);").should eq(["0.0"])
    interpreter.eval("Math.atan(0);").should eq(["0.0"])
    interpreter.eval("Math.atan2(0, 1);").should eq(["0.0"])
    interpreter.eval("Math.ceil(1.2);").should eq(["2"])
    interpreter.eval("Math.cos(0);").should eq(["1.0"])
    interpreter.eval("Math.exp(1);").should eq(["2.718281828459045"])
    interpreter.eval("Math.floor(1.8);").should eq(["1"])
    interpreter.eval("Math.log(1);").should eq(["0.0"])
    interpreter.eval("Math.round(1.5);").should eq(["2"])
    interpreter.eval("Math.pow(2, 3);").should eq(["8.0"])
    interpreter.eval("Math.sign(-10);").should eq(["-1"])
    interpreter.eval("Math.sign(0);").should eq(["0"])
    interpreter.eval("Math.sin(0);").should eq(["0.0"])
    interpreter.eval("Math.tan(0);").should eq(["0.0"])
    interpreter.eval("Math.trunc(-1.8);").should eq(["-1"])
    interpreter.eval("Math.max(1, 9, 3);").should eq(["9.0"])
    interpreter.eval("Math.min(1, 9, 3);").should eq(["1.0"])
  end

  it "supports Math.max and Math.min empty argument behavior" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Math.max();").should eq(["-Infinity"])
    interpreter.eval("Math.min();").should eq(["Infinity"])
  end

  it "provides Math constants as global static properties" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Math.E;").should eq(["2.718281828459045"])
    interpreter.eval("Math.LN10;").should eq(["2.302585092994046"])
    interpreter.eval("Math.LN2;").should eq(["0.6931471805599453"])
    interpreter.eval("Math.LOG10E;").should eq(["0.4342944819032518"])
    interpreter.eval("Math.LOG2E;").should eq(["1.4426950408889634"])
    interpreter.eval("Math.PI;").should eq(["3.141592653589793"])
    interpreter.eval("Math.SQRT1_2;").should eq(["0.7071067811865476"])
    interpreter.eval("Math.SQRT2;").should eq(["1.4142135623730951"])
  end

  it "validates Math builtin arity and argument types" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Math.sqrt();").should eq(["Error: Math.sqrt expects 1 arguments but got 0"])
    interpreter.eval("Math.atan2(1);").should eq(["Error: Math.atan2 expects 2 arguments but got 1"])
    interpreter.eval("Math.abs(1, 2);").should eq(["Error: Math.abs expects 1 arguments but got 2"])
    interpreter.eval("Math.sqrt(\"nine\");").should eq(["Error: Math.sqrt argument 1 must be a number"])
    interpreter.eval("Math.pow(2);").should eq(["Error: Math.pow expects 2 arguments but got 1"])
    interpreter.eval("Math.ceil(\"up\");").should eq(["Error: Math.ceil argument 1 must be a number"])
    interpreter.eval("Math.max(1, \"two\");").should eq(["Error: Math.max argument 2 must be a number"])
    interpreter.eval("Math.cos(\"angle\");").should eq(["Error: Math.cos argument 1 must be a number"])
  end

  it "raises runtime error when Math method is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Math.sqrt = 5;").should eq([] of String)
    interpreter.eval("Math.sqrt(9);").should eq(["Error: value is not callable"])
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

  it "prints error when len is not defined" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("len(\"hello\");").should eq(["Error: function 'len' does not exist"])
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

  it "supports heterogeneous array literals" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", 1, 2.5];").should eq(["[\"a\", 1, 2.5]"])
  end

  it "supports empty arrays and nested arrays" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[];").should eq(["[]"])
    interpreter.eval("[1, [2, 3], []];").should eq(["[1, [2, 3], []]"])
  end

  it "supports zero-based array indexing" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = [10, 20, 30];").should eq([] of String)
    interpreter.eval("r[0];").should eq(["10"])
    interpreter.eval("r[2];").should eq(["30"])
  end

  it "supports indexing nested arrays" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = [1, [2, 3], []];").should eq([] of String)
    interpreter.eval("r[1][0];").should eq(["2"])
  end

  it "supports assigning to existing array indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var alreadyDeclaredArray = [10, 20, 30];").should eq([] of String)
    interpreter.eval("alreadyDeclaredArray[0] = 42;").should eq([] of String)
    interpreter.eval("alreadyDeclaredArray;").should eq(["[42, 20, 30]"])
  end

  it "returns undefined for out-of-range array indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = [10, 20, 30];").should eq([] of String)
    interpreter.eval("r[3];").should eq(["undefined"])
    interpreter.eval("r[-1];").should eq(["undefined"])
    interpreter.eval("r[1.5];").should eq(["Error: array index must be an integer"])
  end

  it "supports object literals with dot and bracket property access" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var o = { a: 10, b: 2 };").should eq([] of String)
    interpreter.eval("o.a;").should eq(["10"])
    interpreter.eval("o[\"a\"];").should eq(["10"])
  end

  it "supports empty and nested objects" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("{};").should eq(["{}"])
    interpreter.eval("var o = { x: { y: [1, 2, 3] } };").should eq([] of String)
    interpreter.eval("o.x.y[2];").should eq(["3"])
  end

  it "prints objects using colon notation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("{ a: 1, nested: { b: 2 } };").should eq(["{\"a\": 1, \"nested\": {\"b\": 2}}"])
    interpreter.eval("[{ a: 1 }];").should eq(["[{\"a\": 1}]"])
  end

  it "supports heterogeneous object values and key normalization" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var o = { aKeyValue: 12, \"another-key\": \"some text here\", 99: \"ninety nine\", \"an-object\": { \"something-inside\": [1, 2, 3] } };").should eq([] of String)
    interpreter.eval("o.aKeyValue;").should eq(["12"])
    interpreter.eval("o[\"another-key\"];").should eq(["\"some text here\""])
    interpreter.eval("o[\"99\"];").should eq(["\"ninety nine\""])
    interpreter.eval("o[\"an-object\"][\"something-inside\"][1];").should eq(["2"])
  end

  it "supports numeric key lookup with bracket expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var o = { 99: \"ninety nine\" }; var k = 99;").should eq([] of String)
    interpreter.eval("o[k];").should eq(["\"ninety nine\""])
  end

  it "returns undefined for missing object properties" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var o = { a: 10 };").should eq([] of String)
    interpreter.eval("o.b;").should eq(["undefined"])
    interpreter.eval("o[\"missing\"];").should eq(["undefined"])
    interpreter.eval("o[true];").should eq(["Error: object property key must be a string or number"])
  end

  it "resolves string and array builtins through type objects" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello\".length;").should eq(["5"])
    interpreter.eval("\"hello\".at(1);").should eq(["\"e\""])
    interpreter.eval("\"hello\".charAt(4);").should eq(["\"o\""])
    interpreter.eval("\"hello\".concat(\" world\");").should eq(["\"hello world\""])
    interpreter.eval("\"abc\".endsWith(\"bc\");").should eq(["true"])
    interpreter.eval("\"abc\".includes(\"b\");").should eq(["true"])
    interpreter.eval("\"abc\".indexOf(\"b\");").should eq(["1"])
    interpreter.eval("\"abca\".lastIndexOf(\"a\");").should eq(["3"])
    interpreter.eval("\"ab\".repeat(3);").should eq(["\"ababab\""])
    interpreter.eval("\"abcdef\".slice(1, 4);").should eq(["\"bcd\""])
    interpreter.eval("\"abc\".startsWith(\"a\");").should eq(["true"])
    interpreter.eval("\"abcdef\".substring(1, 4);").should eq(["\"bcd\""])
    interpreter.eval("\"MiXeD\".toLowerCase();").should eq(["\"mixed\""])
    interpreter.eval("\"MiXeD\".toUpperCase();").should eq(["\"MIXED\""])
    interpreter.eval("\"  spaced  \".trim();").should eq(["\"spaced\""])
    interpreter.eval("\"  spaced\".trimStart();").should eq(["\"spaced\""])
    interpreter.eval("\"spaced  \".trimEnd();").should eq(["\"spaced\""])
    interpreter.eval("\"abc\".valueOf();").should eq(["\"abc\""])
    interpreter.eval("[1, 2, 3].length;").should eq(["3"])
    interpreter.eval("var items = [1, 2, 3];").should eq([] of String)
    interpreter.eval("items.push(4);").should eq(["4"])
    interpreter.eval("items;").should eq(["[1, 2, 3, 4]"])
  end

  it "supports Array.at with positive and negative indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[10, 20, 30].at(1);").should eq(["20"])
    interpreter.eval("[10, 20, 30].at(-1);").should eq(["30"])
    interpreter.eval("[10, 20, 30].at(9);").should eq(["undefined"])
  end

  it "supports Array.concat without mutating the receiver" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = [1, 2]; var b = a.concat([3, 4], 5);").should eq([] of String)
    interpreter.eval("a;").should eq(["[1, 2]"])
    interpreter.eval("b;").should eq(["[1, 2, 3, 4, 5]"])
  end

  it "supports Array.includes and Array.indexOf with optional fromIndex" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var n = +undefined;").should eq([] of String)
    interpreter.eval("[1, 2, 3, 2].includes(2);").should eq(["true"])
    interpreter.eval("[1, 2, 3, 2].includes(2, 2);").should eq(["true"])
    interpreter.eval("[1, 2, 3, 2].includes(2, 4);").should eq(["false"])
    interpreter.eval("[1, 2, 3].indexOf(2);").should eq(["1"])
    interpreter.eval("[1, 2, 3, 2].indexOf(2, 2);").should eq(["3"])
    interpreter.eval("[1, 2, 3].indexOf(9);").should eq(["-1"])
    interpreter.eval("[n].includes(n);").should eq(["true"])
  end

  it "supports Array.lastIndexOf with optional fromIndex" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 2].lastIndexOf(2);").should eq(["3"])
    interpreter.eval("[1, 2, 3, 2].lastIndexOf(2, 2);").should eq(["1"])
    interpreter.eval("[1, 2, 3, 2].lastIndexOf(2, -2);").should eq(["1"])
    interpreter.eval("[1, 2, 3].lastIndexOf(9);").should eq(["-1"])
  end

  it "supports Array.join with default and custom separator" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, true, \"x\"].join();").should eq(["\"1,true,x\""])
    interpreter.eval("[1, 2, 3].join(\" - \");").should eq(["\"1 - 2 - 3\""])
  end

  it "supports Array.pop and empty-array pop behavior" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var items = [1, 2, 3];").should eq([] of String)
    interpreter.eval("items.pop();").should eq(["3"])
    interpreter.eval("items;").should eq(["[1, 2]"])
    interpreter.eval("[].pop();").should eq(["undefined"])
  end

  it "supports Array.shift and Array.unshift with in-place mutation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var items = [2, 3];").should eq([] of String)
    interpreter.eval("items.unshift(0, 1);").should eq(["4"])
    interpreter.eval("items;").should eq(["[0, 1, 2, 3]"])
    interpreter.eval("items.shift();").should eq(["0"])
    interpreter.eval("items;").should eq(["[1, 2, 3]"])
    interpreter.eval("[].shift();").should eq(["undefined"])
  end

  it "supports Array.reverse and Array.sort as in-place operations" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = [1, 2, 3]; a.reverse();").should eq(["[3, 2, 1]"])
    interpreter.eval("a;").should eq(["[3, 2, 1]"])
    interpreter.eval("var b = [10, 2, 1]; b.sort();").should eq(["[1, 10, 2]"])
    interpreter.eval("b;").should eq(["[1, 10, 2]"])
  end

  it "supports Array.slice with omitted and negative indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var items = [1, 2, 3, 4];").should eq([] of String)
    interpreter.eval("items.slice();").should eq(["[1, 2, 3, 4]"])
    interpreter.eval("items.slice(1, 3);").should eq(["[2, 3]"])
    interpreter.eval("items.slice(-2);").should eq(["[3, 4]"])
    interpreter.eval("items.slice(3, 1);").should eq(["[]"])
    interpreter.eval("items;").should eq(["[1, 2, 3, 4]"])
  end

  it "validates Array method argument counts and index types" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1].at();").should eq(["Error: Array.at expects 1 arguments but got 0"])
    interpreter.eval("[1].join(\",\", \";\");").should eq(["Error: Array.join expects between 0 and 1 arguments but got 2"])
    interpreter.eval("[1].slice(0, 1, 2);").should eq(["Error: Array.slice expects between 0 and 2 arguments but got 3"])
    interpreter.eval("[1].includes(1, 1.5);").should eq(["Error: Array.includes expects an integer argument"])
    interpreter.eval("[1].indexOf(1, 1.5);").should eq(["Error: Array.indexOf expects an integer argument"])
    interpreter.eval("[1].lastIndexOf(1, 1.5);").should eq(["Error: Array.lastIndexOf expects an integer argument"])
    interpreter.eval("[1].slice(1.5);").should eq(["Error: Array.slice expects an integer argument"])
    interpreter.eval("[1].shift(1);").should eq(["Error: Array.shift expects 0 arguments but got 1"])
    interpreter.eval("[1].reverse(1);").should eq(["Error: Array.reverse expects 0 arguments but got 1"])
    interpreter.eval("[1].sort(1);").should eq(["Error: Array.sort expects 0 arguments but got 1"])
  end

  it "handles String.at and String.charAt out-of-range indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".at(5);").should eq(["undefined"])
    interpreter.eval("\"abc\".at(-1);").should eq(["\"c\""])
    interpreter.eval("\"abc\".charAt(5);").should eq(["\"\""])
  end

  it "supports String.slice with negative and optional end indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abcdef\".slice(-3);").should eq(["\"def\""])
    interpreter.eval("\"abcdef\".slice(-4, -1);").should eq(["\"cde\""])
    interpreter.eval("\"abcdef\".slice(4, 2);").should eq(["\"\""])
  end

  it "supports String.substring index normalization" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abcdef\".substring(4, 1);").should eq(["\"bcd\""])
    interpreter.eval("\"abcdef\".substring(-3, 2);").should eq(["\"ab\""])
    interpreter.eval("\"abcdef\".substring(2);").should eq(["\"cdef\""])
  end

  it "rejects negative counts for String.repeat" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"ab\".repeat(-1);").should eq(["Error: String.repeat expects a non-negative integer argument"])
  end

  it "validates String argument types for simple string methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".includes(1);").should eq(["Error: String.includes expects a string argument"])
    interpreter.eval("\"abc\".indexOf(true);").should eq(["Error: String.indexOf expects a string argument"])
    interpreter.eval("\"abc\".concat(1);").should eq(["Error: String.concat expects a string argument"])
  end

  it "validates String index argument type" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".at(1.5);").should eq(["Error: String.at expects an integer argument"])
    interpreter.eval("\"abc\".charAt(1.5);").should eq(["Error: String.charAt expects an integer argument"])
    interpreter.eval("\"abc\".slice(1.5);").should eq(["Error: String.slice expects an integer argument"])
    interpreter.eval("\"abc\".substring(1.5);").should eq(["Error: String.substring expects an integer argument"])
    interpreter.eval("\"abc\".repeat(1.5);").should eq(["Error: String.repeat expects an integer argument"])
  end

  it "validates String slice and substring arity" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".slice();").should eq(["Error: String.slice expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".slice(0, 1, 2);").should eq(["Error: String.slice expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".substring();").should eq(["Error: String.substring expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".substring(0, 1, 2);").should eq(["Error: String.substring expects between 1 and 2 arguments but got 3"])
  end

  it "validates String case conversion method arity" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"text\".toLowerCase(1);").should eq(["Error: String.toLowerCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toUpperCase(1);").should eq(["Error: String.toUpperCase expects 0 arguments but got 1"])
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

  it "prints null in strings as plain content" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = null;").should eq([] of String)
    interpreter.eval("\"value is value\";").should eq(["\"value is value\""])
  end

  it "prints undefined in strings as plain content" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = undefined;").should eq([] of String)
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

  it "defines functions with braced bodies" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function sumNumbers(a, b) {\n  return a + b;\n}").should eq([] of String)
    interpreter.eval("sumNumbers(2, 3);").should eq(["5"])
  end

  it "treats functions as first-class values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function addOne(x) {\n  return x + 1;\n}\nvar f = addOne;\nvar result = f(2);").should eq([] of String)
    interpreter.eval("result;").should eq(["3"])
  end

  it "passes and returns function values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function addOne(x) {\n  return x + 1;\n}\nfunction applyTwice(fn, value) {\n  return fn(fn(value));\n}\nfunction getFn() {\n  return addOne;\n}\nvar fromReturn = getFn();\nvar result = applyTwice(fromReturn, 1);").should eq([] of String)
    interpreter.eval("result;").should eq(["3"])
  end

  it "raises a runtime error when calling non-callable values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("5();").should eq(["Error: value is not callable"])
  end

  it "rejects legacy end-based function syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function sumNumbers(a, b)\n  return a + b;\nend").should eq(["Error: invalid function definition"])
  end

  it "runs if branch when condition is truthy" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 1; if (value) value = 2;").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "runs else branch when condition is falsy" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (value) value = 2; else value = 3;").should eq([] of String)
    interpreter.eval("value;").should eq(["3"])
  end

  it "supports if without else" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 4; if (0) value = 8;").should eq([] of String)
    interpreter.eval("value;").should eq(["4"])
  end

  it "supports if / else if / else chains" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (0) value = 1; else if (1) value = 2; else value = 3;").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "supports braced blocks in if statements" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (1) { value = 9; }").should eq([] of String)
    interpreter.eval("value;").should eq(["9"])
  end

  it "supports braced blocks in else statements" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (0) { value = 1; } else { value = 7; }").should eq([] of String)
    interpreter.eval("value;").should eq(["7"])
  end

  it "supports nested if with dangling else" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (1) if (0) value = 1; else value = 2;").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "executes only the selected if chain branch" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (0) value = missing; else if (1) value = 7; else value = anotherMissing;").should eq([] of String)
    interpreter.eval("value;").should eq(["7"])
  end

  it "supports single-line if statements without braces" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("if (true) console.log(\"hello!\");").should eq(["undefined"])
    output.to_s.should eq("hello!\n")
  end

  it "supports logical operators with short-circuit semantics" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("true && false;").should eq(["false"])
    interpreter.eval("true || false;").should eq(["true"])
    interpreter.eval("!0;").should eq(["true"])
    interpreter.eval("!1;").should eq(["false"])
    interpreter.eval("5 && 9;").should eq(["9"])
    interpreter.eval("0 || 7;").should eq(["7"])
    interpreter.eval("\"\" || \"fallback\";").should eq(["\"fallback\""])
    interpreter.eval("false && missing;").should eq(["false"])
    interpreter.eval("true || missing;").should eq(["true"])
    interpreter.eval("false && (1 / 0);").should eq(["false"])
    interpreter.eval("true || (1 / 0);").should eq(["true"])
    interpreter.eval("missing && true;").should eq(["Error: variable 'missing' does not exist"])
  end

  it "applies logical operator precedence" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("true || false && false;").should eq(["true"])
    interpreter.eval("(true || false) && false;").should eq(["false"])
  end

  it "supports ECMAScript-style for loop with all components" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var i = 0; i < 3; i = i + 1) console.log(i);").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports postfix increment in for update" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var i = 0; i < 3; i++) console.log(i);").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports compound assignment in for update" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var i = 0; i < 3; i += 1) console.log(i);").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports for loop with missing components" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; for (; i < 2;) { console.log(i); i = i + 1; }").should eq([] of String)
    output.to_s.should eq("0\n1\n")
  end

  it "propagates runtime errors raised inside for-loop bodies" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("for (;;) { Math.sqrt(); }").should eq(["Error: Math.sqrt expects 1 arguments but got 0"])
  end

  it "supports for (;;) with break" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var i = 0; for (;;) { i = i + 1; break; }").should eq([] of String)
    interpreter.eval("i;").should eq(["1"])
  end

  it "supports continue in for loops" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var i = 0; i < 4; i = i + 1) { if (i == 2) continue; console.log(i); }").should eq([] of String)
    output.to_s.should eq("0\n1\n3\n")
  end

  it "runs update before next condition check on continue" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var i = 0; var seen = 0; for (; i < 3; i = i + 1) { if (i == 1) continue; seen = seen + 1; }").should eq([] of String)
    interpreter.eval("i;").should eq(["3"])
    interpreter.eval("seen;").should eq(["2"])
  end

  it "supports while loops" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; while (i < 3) { console.log(i); i = i + 1; }").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports continue in while loops" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; while (i < 4) { i = i + 1; if (i == 3) continue; console.log(i); }").should eq([] of String)
    output.to_s.should eq("1\n2\n4\n")
  end

  it "supports do...while loops" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; do { console.log(i); i = i + 1; } while (i < 3);").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports do...while loops without whitespace before block" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; do{ console.log(i); i = i + 1; } while (i < 2);").should eq([] of String)
    output.to_s.should eq("0\n1\n")
  end

  it "runs do...while body at least once" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var i = 0; do { i = i + 1; } while (0);").should eq([] of String)
    interpreter.eval("i;").should eq(["1"])
  end

  it "supports switch with matching case and break" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 0; switch (2) { case 1: value = 1; break; case 2: value = 7; break; default: value = 9; }").should eq([] of String)
    interpreter.eval("value;").should eq(["7"])
  end

  it "supports switch fallthrough behavior" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 0; switch (1) { case 1: value = 1; case 2: value = value + 2; break; default: value = 99; }").should eq([] of String)
    interpreter.eval("value;").should eq(["3"])
  end

  it "uses strict matching semantics in switch cases" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 0; switch (1) { case \"1\": value = 1; break; default: value = 2; }").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "supports default clauses and case labels after default" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 0; switch (4) { case 1: value = 1; break; default: value = 2; case 3: value = value + 3; break; }").should eq([] of String)
    interpreter.eval("value;").should eq(["5"])
  end

  it "allows continue inside switch when nested in loops" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var i = 0; var seen = 0; while (i < 3) { i = i + 1; switch (i) { case 2: continue; default: seen = seen + 1; } }").should eq([] of String)
    interpreter.eval("seen;").should eq(["2"])
  end

  it "returns runtime error for continue in switch outside loops" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("switch (1) { case 1: continue; }").should eq(["Error: continue can only be used inside loops"])
  end

  it "stops block execution after first runtime error" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; while (i < 1) { missing; console.log(\"after\"); i = i + 1; }").should eq(["Error: variable 'missing' does not exist"])
    output.to_s.should eq("")
  end

  it "returns runtime error for break outside loops" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("break;").should eq(["Error: break can only be used inside loops or switch statements"])
  end

  it "returns runtime error for continue outside loops" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("continue;").should eq(["Error: continue can only be used inside loops"])
  end

  it "returns error for invalid if syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("if value) value = 1;").should eq(["Error: invalid if statement"])
  end

  it "returns error for invalid for syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("for (var i = 0 i < 3; i = i + 1) console.log(i);").should eq(["Error: invalid for statement"])
  end

  it "returns error for invalid while syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("while value) value = 1;").should eq(["Error: invalid while statement"])
  end

  it "returns error for invalid do...while syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("do value = 1; while value);").should eq(["Error: invalid do...while statement"])
  end

  it "returns error for invalid switch syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("switch value) { case 1: value = 1; }").should eq(["Error: invalid switch statement"])
  end

  it "prints error for missing variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("missing;").should eq(["Error: variable 'missing' does not exist"])
  end
end
