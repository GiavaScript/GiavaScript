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

  it "evaluates template literals without interpolation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("`hello world`;").should eq(["\"hello world\""])
  end

  it "interpolates template literal expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var name = \"GiavaScript\"; var major = 1;").should eq([] of String)
    interpreter.eval("`Hello ${name} v${major + 1}`;").should eq(["\"Hello GiavaScript v2\""])
  end

  it "supports multiline template literals and escaped interpolation markers" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("`line1\nline2`;").should eq(["\"line1\\nline2\""])
    interpreter.eval("`Price: \\${5}`;").should eq(["\"Price: ${5}\""])
  end

  it "supports nested template literal interpolation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("`outer ${`inner ${1 + 1}`}`;").should eq(["\"outer inner 2\""])
    interpreter.eval("`L1 ${`L2 ${`L3 ${3}`}`}`;").should eq(["\"L1 L2 L3 3\""])
  end

  it "uses JavaScript-like ToString semantics in string interpolation and concatenation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("`${[1, undefined, null, [2, 3]]}`;").should eq(["\"1,,,2,3\""])
    interpreter.eval("`${{ nested: true }}`;").should eq(["\"[object Object]\""])
    interpreter.eval("\"\" + [1, undefined, null, [2, 3]];").should eq(["\"1,,,2,3\""])
    interpreter.eval("\"\" + { a: 1 };").should eq(["\"[object Object]\""])
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

  it "supports function expressions assigned to variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var sum = function(a, b) { return a + b; };").should eq([] of String)
    interpreter.eval("sum(2, 3);").should eq(["5"])
    interpreter.eval("typeof sum;").should eq(["\"function\""])
  end

  it "supports immediately-invoked function expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("(function(a, b) { return a + b; })(4, 6);").should eq(["10"])
  end

  it "supports named function expressions for recursion without leaking the name" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var factorial = function fact(n) { if (n <= 1) return 1; return n * fact(n - 1); };").should eq([] of String)
    interpreter.eval("factorial(5);").should eq(["120"])
    interpreter.eval("fact;").should eq(["Error: variable 'fact' does not exist"])
  end

  it "supports no-parameter arrow with expression body" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("(() => 42)();").should eq(["42"])
  end

  it "supports single-parameter arrow without parens with expression body" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var double = x => x * 2;").should eq([] of String)
    interpreter.eval("double(5);").should eq(["10"])
  end

  it "supports multi-parameter arrow with expression body" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var sum = (a, b) => a + b;").should eq([] of String)
    interpreter.eval("sum(2, 3);").should eq(["5"])
  end

  it "supports no-parameter arrow with block body" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var fn = () => { return 42; };").should eq([] of String)
    interpreter.eval("fn();").should eq(["42"])
  end

  it "supports single-parameter arrow with block body" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var triple = x => { return x * 3; };").should eq([] of String)
    interpreter.eval("triple(4);").should eq(["12"])
  end

  it "supports multi-parameter arrow with block body" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var multiply = (a, b) => { return a * b; };").should eq([] of String)
    interpreter.eval("multiply(4, 5);").should eq(["20"])
  end

  it "supports immediately-invoked arrow function" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("((a, b) => a + b)(4, 6);").should eq(["10"])
  end

  it "returns function for typeof arrow function" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var fn = () => 1;").should eq([] of String)
    interpreter.eval("typeof fn;").should eq(["\"function\""])
  end

  it "supports arrow with implicit return of empty block" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var fn = () => {};").should eq([] of String)
    interpreter.eval("fn();").should eq(["undefined"])
  end

  it "supports arrow functions returning expressions with operators" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var fn = (a, b) => a * b + 1;").should eq([] of String)
    interpreter.eval("fn(3, 4);").should eq(["13"])
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

  it "provides Math.sqrt and Math.abs as global built-in methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Math.sqrt(9);").should eq(["3.0"])
    interpreter.eval("Math.abs(-5);").should eq(["5"])
    interpreter.eval("Math.abs(-2.5);").should eq(["2.5"])
  end

  it "provides basic Math rounding and utility methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Math.acos(1);").should eq(["0.0"])
    interpreter.eval("Math.acosh(1);").should eq(["0.0"])
    interpreter.eval("Math.asin(0);").should eq(["0.0"])
    interpreter.eval("Math.asinh(0);").should eq(["0.0"])
    interpreter.eval("Math.atan(0);").should eq(["0.0"])
    interpreter.eval("Math.atan2(0, 1);").should eq(["0.0"])
    interpreter.eval("Math.atanh(0);").should eq(["0.0"])
    interpreter.eval("Math.cbrt(1);").should eq(["1.0"])
    interpreter.eval("Math.ceil(1.2);").should eq(["2"])
    interpreter.eval("Math.clz32(1);").should eq(["31"])
    interpreter.eval("Math.cos(0);").should eq(["1.0"])
    interpreter.eval("Math.cosh(0);").should eq(["1.0"])
    interpreter.eval("Math.exp(1);").should eq(["2.718281828459045"])
    interpreter.eval("Math.expm1(0);").should eq(["0.0"])
    interpreter.eval("Math.f16round(1);").should eq(["1.0"])
    interpreter.eval("Math.floor(1.8);").should eq(["1"])
    interpreter.eval("Math.fround(1.5);").should eq(["1.5"])
    interpreter.eval("Math.hypot();").should eq(["0.0"])
    interpreter.eval("Math.hypot(5);").should eq(["5.0"])
    interpreter.eval("Math.hypot(3, 4);").should eq(["5.0"])
    interpreter.eval("Math.hypot(Math.min(), parseFloat(\"foo\"));").should eq(["Infinity"])
    interpreter.eval("Math.imul(-1, 5);").should eq(["-5"])
    interpreter.eval("Math.log(1);").should eq(["0.0"])
    interpreter.eval("Math.log10(1000);").should eq(["3.0"])
    interpreter.eval("Math.log1p(0);").should eq(["0.0"])
    interpreter.eval("Math.log2(8);").should eq(["3.0"])
    interpreter.eval("Math.round(1.5);").should eq(["2"])
    interpreter.eval("Math.pow(2, 3);").should eq(["8.0"])
    interpreter.eval("Math.sign(-10);").should eq(["-1"])
    interpreter.eval("Math.sign(0);").should eq(["0"])
    interpreter.eval("Math.sin(0);").should eq(["0.0"])
    interpreter.eval("Math.sinh(0);").should eq(["0.0"])
    interpreter.eval("Math.sumPrecise();").should eq(["0.0"])
    interpreter.eval("Math.sumPrecise(2);").should eq(["2.0"])
    interpreter.eval("Math.sumPrecise(0.1, 0.2, 0.3);").should eq(["0.6"])
    interpreter.eval("Math.tan(0);").should eq(["0.0"])
    interpreter.eval("Math.tanh(0);").should eq(["0.0"])
    interpreter.eval("Math.trunc(-1.8);").should eq(["-1"])
    interpreter.eval("Math.max(1, 9, 3);").should eq(["9.0"])
    interpreter.eval("Math.min(1, 9, 3);").should eq(["1.0"])
    interpreter.eval("var randomValue = Math.random();").should eq([] of String)
    interpreter.eval("randomValue >= 0 && randomValue < 1;").should eq(["true"])
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
    interpreter.eval("Math.acosh();").should eq(["Error: Math.acosh expects 1 arguments but got 0"])
    interpreter.eval("Math.imul(1);").should eq(["Error: Math.imul expects 2 arguments but got 1"])
    interpreter.eval("Math.hypot(1, \"two\");").should eq(["Error: Math.hypot argument 2 must be a number"])
    interpreter.eval("Math.sumPrecise(1, \"two\");").should eq(["Error: Math.sumPrecise argument 2 must be a number"])
    interpreter.eval("Math.random(1);").should eq(["Error: Math.random expects 0 arguments but got 1"])
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

  it "provides Object.keys, Object.values, and Object.entries as global static methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var obj = {\"name\": \"giava\", \"count\": 3, \"ok\": true};").should eq([] of String)
    interpreter.eval("Object.keys(obj);").should eq(["[\"name\", \"count\", \"ok\"]"])
    interpreter.eval("Object.values(obj);").should eq(["[\"giava\", 3, true]"])
    interpreter.eval("Object.entries(obj);").should eq(["[[\"name\", \"giava\"], [\"count\", 3], [\"ok\", true]]"])
  end

  it "provides Object.assign and Object.hasOwn as global static methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var target = {\"a\": 1}; var source = {\"b\": 2};").should eq([] of String)
    interpreter.eval("Object.assign(target, source) === target;").should eq(["true"])
    interpreter.eval("target;").should eq(["{\"a\": 1, \"b\": 2}"])
    interpreter.eval("Object.hasOwn(target, \"a\");").should eq(["true"])
    interpreter.eval("Object.hasOwn(target, \"missing\");").should eq(["false"])
    interpreter.eval("Object.hasOwn({\"1\": true}, 1);").should eq(["true"])
  end

  it "validates Object static method arity and argument types" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Object.keys();").should eq(["Error: Object.keys expects 1 arguments but got 0"])
    interpreter.eval("Object.values({}, 1);").should eq(["Error: Object.values expects 1 arguments but got 2"])
    interpreter.eval("Object.entries(1);").should eq(["Error: Object.entries argument 1 must be an object"])
    interpreter.eval("Object.assign();").should eq(["Error: Object.assign expects at least 1 arguments but got 0"])
    interpreter.eval("Object.assign({}, 1);").should eq(["Error: Object.assign argument 2 must be an object"])
    interpreter.eval("Object.hasOwn({});").should eq(["Error: Object.hasOwn expects 2 arguments but got 1"])
    interpreter.eval("Object.hasOwn({}, []);").should eq(["Error: Object.hasOwn argument 2 must be a string, number, boolean, null, or undefined"])
  end

  it "raises runtime error when Object method is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Object.keys = 5;").should eq([] of String)
    interpreter.eval("Object.keys({});").should eq(["Error: value is not callable"])
  end

  it "provides Array.isArray and Array.of as global static methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Array.isArray([]);").should eq(["true"])
    interpreter.eval("Array.isArray({});").should eq(["false"])
    interpreter.eval("Array.of(1, \"two\", true);").should eq(["[1, \"two\", true]"])
    interpreter.eval("Array.of();").should eq(["[]"])
  end

  it "validates Array static method arity" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Array.isArray();").should eq(["Error: Array.isArray expects 1 arguments but got 0"])
    interpreter.eval("Array.isArray([], 1);").should eq(["Error: Array.isArray expects 1 arguments but got 2"])
  end

  it "raises runtime error when Array method is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Array.of = 5;").should eq([] of String)
    interpreter.eval("Array.of(1);").should eq(["Error: value is not callable"])
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

  it "provides String.fromCharCode as a global static method" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("String.fromCharCode(71, 105, 97, 118, 97);").should eq(["\"Giava\""])
    interpreter.eval("String.fromCharCode();").should eq(["\"\""])
  end

  it "validates String.fromCharCode argument types" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("String.fromCharCode(65, \"66\");").should eq(["Error: String.fromCharCode argument 2 must be a number"])
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
    interpreter.eval("\"hello\".charCodeAt(1);").should eq(["101"])
    interpreter.eval("\"hello\".codePointAt(1);").should eq(["101"])
    interpreter.eval("\"hello\".concat(\" world\");").should eq(["\"hello world\""])
    interpreter.eval("\"abc\".endsWith(\"bc\");").should eq(["true"])
    interpreter.eval("\"abc\".includes(\"b\");").should eq(["true"])
    interpreter.eval("\"abc\".indexOf(\"b\");").should eq(["1"])
    interpreter.eval("\"abc\".isWellFormed();").should eq(["true"])
    interpreter.eval("\"abca\".lastIndexOf(\"a\");").should eq(["3"])
    interpreter.eval("\"a\".localeCompare(\"b\");").should eq(["-1"])
    interpreter.eval("\"abc\".match(\"bc\");").should eq(["[\"bc\"]"])
    interpreter.eval("\"aaaa\".matchAll(\"aa\");").should eq(["[\"aa\", \"aa\"]"])
    interpreter.eval("\"5\".padStart(3, \"0\");").should eq(["\"005\""])
    interpreter.eval("\"5\".padEnd(3, \"0\");").should eq(["\"500\""])
    interpreter.eval("\"ab\".repeat(3);").should eq(["\"ababab\""])
    interpreter.eval("\"a,b,c\".split(\",\");").should eq(["[\"a\", \"b\", \"c\"]"])
    interpreter.eval("\"hello world\".replace(\"world\", \"Giava\");").should eq(["\"hello Giava\""])
    interpreter.eval("\"foo bar foo\".replaceAll(\"foo\", \"baz\");").should eq(["\"baz bar baz\""])
    interpreter.eval("\"abcdef\".search(\"cd\");").should eq(["2"])
    interpreter.eval("\"abcdef\".slice(1, 4);").should eq(["\"bcd\""])
    interpreter.eval("\"abc\".startsWith(\"a\");").should eq(["true"])
    interpreter.eval("\"abcdef\".substring(1, 4);").should eq(["\"bcd\""])
    interpreter.eval("\"MiXeD\".toLocaleLowerCase();").should eq(["\"mixed\""])
    interpreter.eval("\"MiXeD\".toLocaleUpperCase();").should eq(["\"MIXED\""])
    interpreter.eval("\"MiXeD\".toLowerCase();").should eq(["\"mixed\""])
    interpreter.eval("\"MiXeD\".toUpperCase();").should eq(["\"MIXED\""])
    interpreter.eval("\"abc\".toWellFormed();").should eq(["\"abc\""])
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

  it "supports Array.flat with configurable depth" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var nested = [1, [2, [3, [4]]], 5];").should eq([] of String)
    interpreter.eval("nested.flat();").should eq(["[1, 2, [3, [4]], 5]"])
    interpreter.eval("nested.flat(2);").should eq(["[1, 2, 3, [4], 5]"])
    interpreter.eval("nested.flat(99);").should eq(["[1, 2, 3, 4, 5]"])
    interpreter.eval("nested;").should eq(["[1, [2, [3, [4]]], 5]"])
  end

  it "supports Array.flatMap" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var numbers = [1, 2, 3];").should eq([] of String)
    interpreter.eval("numbers.flatMap(function(n) { return [n, n * 10]; });").should eq(["[1, 10, 2, 20, 3, 30]"])
    interpreter.eval("numbers.flatMap(function(n) { return n * 2; });").should eq(["[2, 4, 6]"])
    interpreter.eval("numbers;").should eq(["[1, 2, 3]"])
  end

  it "supports Array.splice with insertion and deletion" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var items = [1, 2, 3, 4, 5];").should eq([] of String)
    interpreter.eval("items.splice(1, 2, 9, 8);").should eq(["[2, 3]"])
    interpreter.eval("items;").should eq(["[1, 9, 8, 4, 5]"])
    interpreter.eval("items.splice(-2);").should eq(["[4, 5]"])
    interpreter.eval("items;").should eq(["[1, 9, 8]"])
  end

  it "supports callback-based Array methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var numbers = [1, 2, 3, 4];").should eq([] of String)
    interpreter.eval("var seen = []; numbers.forEach(function(value, index, array) { seen.push(value + index + array.length); });").should eq(["undefined"])
    interpreter.eval("seen;").should eq(["[5, 7, 9, 11]"])
    interpreter.eval("numbers.map(function(value, index, array) { return value * index + array.length; });").should eq(["[4, 6, 10, 16]"])
    interpreter.eval("numbers.filter(function(value, index, array) { return value + index > array.length; });").should eq(["[3, 4]"])
    interpreter.eval("numbers.some(function(value, index, array) { return value + index == array.length; });").should eq(["false"])
    interpreter.eval("numbers.every(function(value, index, array) { return value + index >= 1; });").should eq(["true"])
    interpreter.eval("numbers.find(function(value, index, array) { return value * 2 == array.length + index + 1; });").should eq(["4"])
    interpreter.eval("numbers.findIndex(function(value, index, array) { return value * 2 == array.length + index + 1; });").should eq(["3"])
  end

  it "supports multiline chained calls after assignment" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var numbers = [3, -1, 1, 4];").should eq([] of String)
    interpreter.eval(<<-JS).should eq([] of String)
      var averaged = numbers
        .filter(function(n) { return n > 0; })
        .map(function(n) { return n; });
    JS
    interpreter.eval("averaged;").should eq(["[3, 1, 4]"])
  end

  it "uses JS-compatible callback arity for array methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var array = [1, 4, 9, 16];").should eq([] of String)
    interpreter.eval("array.map(function(x) { return x * 2; });").should eq(["[2, 8, 18, 32]"])
    interpreter.eval("array.map(function(value, index, source, extra) { return extra; });").should eq(["[undefined, undefined, undefined, undefined]"])
    interpreter.eval("[1, 2, 3].reduce(function(acc, value) { return acc + value; }, 0);").should eq(["6"])
  end

  it "uses JS-compatible callback arity for function declaration references" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function double(value) { return value * 2; }").should eq([] of String)
    interpreter.eval("[1, 2, 3].map(double);").should eq(["[2, 4, 6]"])

    interpreter.eval("function takeFourth(value, index, source, extra) { return extra; }").should eq([] of String)
    interpreter.eval("[1, 2].map(takeFourth);").should eq(["[undefined, undefined]"])

    interpreter.eval("function sum(acc, value) { return acc + value; }").should eq([] of String)
    interpreter.eval("[1, 2, 3].reduce(sum, 0);").should eq(["6"])
  end

  it "keeps strict arity for non-callback function declaration calls" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function addOne(x) { return x + 1; }").should eq([] of String)
    interpreter.eval("addOne(1, 2);").should eq(["Error: function 'addOne' expects 1 arguments but got 2"])
    interpreter.eval("var ref = addOne;").should eq([] of String)
    interpreter.eval("ref(1, 2);").should eq(["Error: function 'addOne' expects 1 arguments but got 2"])
  end

  it "supports Array.reduce with and without an initial value" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3].reduce(function(acc, value, index, array) { return acc + value + index + array.length; }, 0);").should eq(["18"])
    interpreter.eval("[1, 2, 3].reduce(function(acc, value, index, array) { return acc + value + index + array.length; });").should eq(["15"])
    interpreter.eval("[].reduce(function(acc, value, index, array) { return acc + value + index + array.length; }, 10);").should eq(["10"])
  end

  it "handles empty and miss cases for callback-based Array methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[].some(function(value, index, array) { return true; });").should eq(["false"])
    interpreter.eval("[].every(function(value, index, array) { return false; });").should eq(["true"])
    interpreter.eval("[1, 2].find(function(value, index, array) { return value == 9; });").should eq(["undefined"])
    interpreter.eval("[1, 2].findIndex(function(value, index, array) { return value == 9; });").should eq(["-1"])
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
    interpreter.eval("[1].forEach();").should eq(["Error: Array.forEach expects 1 arguments but got 0"])
    interpreter.eval("[1].map(1);").should eq(["Error: Array.map expects a function argument"])
    interpreter.eval("[1].flat(1.5);").should eq(["Error: Array.flat expects an integer argument"])
    interpreter.eval("[1].flatMap();").should eq(["Error: Array.flatMap expects 1 arguments but got 0"])
    interpreter.eval("[1].flatMap(1);").should eq(["Error: Array.flatMap expects a function argument"])
    interpreter.eval("[1].splice();").should eq(["Error: Array.splice expects at least 1 arguments but got 0"])
    interpreter.eval("[1].splice(0, 1.5);").should eq(["Error: Array.splice expects an integer argument"])
    interpreter.eval("[1].reduce();").should eq(["Error: Array.reduce expects between 1 and 2 arguments but got 0"])
    interpreter.eval("[].reduce(function(acc, value, index, array) { return acc + value + index + array.length; });").should eq(["Error: Array.reduce cannot reduce an empty array without an initial value"])
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

  it "supports String.split optional limit and empty separator" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"a,b,c\".split(\",\", 2);").should eq(["[\"a\", \"b\"]"])
    interpreter.eval("\"abc\".split(\"\");").should eq(["[\"a\", \"b\", \"c\"]"])
    interpreter.eval("\"abc\".split(\"\", 0);").should eq(["[]"])
  end

  it "supports String.replace first-match behavior" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"aaaa\".replace(\"aa\", \"b\");").should eq(["\"baa\""])
    interpreter.eval("\"abc\".replace(\"\", \"_\");").should eq(["\"_abc\""])
    interpreter.eval("\"abc\".replace(\"z\", \"x\");").should eq(["\"abc\""])
  end

  it "supports String.match, matchAll, and search with string patterns" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abcabc\".match(\"bc\");").should eq(["[\"bc\"]"])
    interpreter.eval("\"abc\".match(\"z\");").should eq(["null"])
    interpreter.eval("\"ababa\".matchAll(\"ba\");").should eq(["[\"ba\", \"ba\"]"])
    interpreter.eval("\"abc\".matchAll(\"z\");").should eq(["[]"])
    interpreter.eval("\"abc\".search(\"b\");").should eq(["1"])
    interpreter.eval("\"abc\".search(\"z\");").should eq(["-1"])
  end

  it "supports String.padStart and padEnd" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"7\".padStart(3, \"0\");").should eq(["\"007\""])
    interpreter.eval("\"7\".padEnd(3, \"0\");").should eq(["\"700\""])
    interpreter.eval("\"abc\".padStart(2, \"0\");").should eq(["\"abc\""])
    interpreter.eval("\"abc\".padEnd(2, \"0\");").should eq(["\"abc\""])
    interpreter.eval("\"x\".padStart(5, \"\");").should eq(["\"x\""])
    interpreter.eval("\"x\".padEnd(5, \"\");").should eq(["\"x\""])
  end

  it "supports String.replaceAll special-casing for empty search" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".replaceAll(\"\", \"_\");").should eq(["\"_a_b_c_\""])
    interpreter.eval("\"abc\".replaceAll(\"b\", \"X\");").should eq(["\"aXc\""])
  end

  it "supports String.charCodeAt and String.codePointAt edge behavior" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".charCodeAt(0);").should eq(["97"])
    interpreter.eval("\"abc\".charCodeAt(9);").should eq(["NaN"])
    interpreter.eval("\"abc\".codePointAt(0);").should eq(["97"])
    interpreter.eval("\"abc\".codePointAt(9);").should eq(["undefined"])
  end

  it "supports String locale/correctness helpers" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".isWellFormed();").should eq(["true"])
    interpreter.eval("\"abc\".toWellFormed();").should eq(["\"abc\""])
    interpreter.eval("\"ABC\".toLocaleLowerCase();").should eq(["\"abc\""])
    interpreter.eval("\"abc\".toLocaleUpperCase();").should eq(["\"ABC\""])
    interpreter.eval("\"abc\".localeCompare(\"abc\");").should eq(["0"])
    interpreter.eval("\"abc\".localeCompare(\"abd\");").should eq(["-1"])
    interpreter.eval("\"abd\".localeCompare(\"abc\");").should eq(["1"])
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
    interpreter.eval("\"abc\".split(1);").should eq(["Error: String.split expects a string argument"])
    interpreter.eval("\"abc\".replace(1, \"x\");").should eq(["Error: String.replace expects a string argument"])
    interpreter.eval("\"abc\".replaceAll(1, \"x\");").should eq(["Error: String.replaceAll expects a string argument"])
    interpreter.eval("\"abc\".search(1);").should eq(["Error: String.search expects a string argument"])
    interpreter.eval("\"abc\".match(1);").should eq(["Error: String.match expects a string argument"])
    interpreter.eval("\"abc\".matchAll(1);").should eq(["Error: String.matchAll expects a string argument"])
    interpreter.eval("\"abc\".localeCompare(1);").should eq(["Error: String.localeCompare expects a string argument"])
    interpreter.eval("\"abc\".padStart(2, 0);").should eq(["Error: String.padStart expects a string argument"])
    interpreter.eval("\"abc\".padEnd(2, 0);").should eq(["Error: String.padEnd expects a string argument"])
  end

  it "validates String index argument type" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".at(1.5);").should eq(["Error: String.at expects an integer argument"])
    interpreter.eval("\"abc\".charAt(1.5);").should eq(["Error: String.charAt expects an integer argument"])
    interpreter.eval("\"abc\".slice(1.5);").should eq(["Error: String.slice expects an integer argument"])
    interpreter.eval("\"abc\".substring(1.5);").should eq(["Error: String.substring expects an integer argument"])
    interpreter.eval("\"abc\".repeat(1.5);").should eq(["Error: String.repeat expects an integer argument"])
    interpreter.eval("\"abc\".split(\",\", 1.5);").should eq(["Error: String.split expects an integer argument"])
    interpreter.eval("\"abc\".charCodeAt(1.5);").should eq(["Error: String.charCodeAt expects an integer argument"])
    interpreter.eval("\"abc\".codePointAt(1.5);").should eq(["Error: String.codePointAt expects an integer argument"])
    interpreter.eval("\"abc\".padStart(1.5);").should eq(["Error: String.padStart expects an integer argument"])
    interpreter.eval("\"abc\".padEnd(1.5);").should eq(["Error: String.padEnd expects an integer argument"])
  end

  it "validates String slice and substring arity" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".slice();").should eq(["Error: String.slice expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".slice(0, 1, 2);").should eq(["Error: String.slice expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".substring();").should eq(["Error: String.substring expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".substring(0, 1, 2);").should eq(["Error: String.substring expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".split();").should eq(["Error: String.split expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".split(\",\", 1, 2);").should eq(["Error: String.split expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".replace();").should eq(["Error: String.replace expects 2 arguments but got 0"])
    interpreter.eval("\"abc\".replace(\"a\");").should eq(["Error: String.replace expects 2 arguments but got 1"])
    interpreter.eval("\"abc\".replaceAll(\"a\");").should eq(["Error: String.replaceAll expects 2 arguments but got 1"])
    interpreter.eval("\"abc\".charCodeAt();").should eq(["Error: String.charCodeAt expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".codePointAt();").should eq(["Error: String.codePointAt expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".padStart();").should eq(["Error: String.padStart expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".padEnd(1, \"x\", \"y\");").should eq(["Error: String.padEnd expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".match();").should eq(["Error: String.match expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".matchAll();").should eq(["Error: String.matchAll expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".search();").should eq(["Error: String.search expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".localeCompare();").should eq(["Error: String.localeCompare expects 1 arguments but got 0"])
  end

  it "rejects negative limits for String.split" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".split(\",\", -1);").should eq(["Error: String.split expects a non-negative integer argument"])
  end

  it "validates String case conversion method arity" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"text\".toLowerCase(1);").should eq(["Error: String.toLowerCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toUpperCase(1);").should eq(["Error: String.toUpperCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toLocaleLowerCase(1);").should eq(["Error: String.toLocaleLowerCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toLocaleUpperCase(1);").should eq(["Error: String.toLocaleUpperCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".isWellFormed(1);").should eq(["Error: String.isWellFormed expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toWellFormed(1);").should eq(["Error: String.toWellFormed expects 0 arguments but got 1"])
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

  it "supports a ? b : c expression" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("true ? 99 : 88;").should eq(["99"])
    interpreter.eval("false ? 99 : 88;").should eq(["88"])
  end

  it "supports a ? b : c with truthy condition" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("1 ? 'hello' : 'world';").should eq(["\"hello\""])
    interpreter.eval("'nonempty' ? 42 : 0;").should eq(["42"])
  end

  it "supports a ? b : c with falsey condition" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("0 ? 'yes' : 'no';").should eq(["\"no\""])
    interpreter.eval("'' ? 'yes' : 'no';").should eq(["\"no\""])
    interpreter.eval("null ? 'yes' : 'no';").should eq(["\"no\""])
    interpreter.eval("undefined ? 'yes' : 'no';").should eq(["\"no\""])
  end

  it "supports nested a ? b : c ? d : e (right-associative)" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("true ? 1 : false ? 2 : 3;").should eq(["1"])
    interpreter.eval("false ? 1 : false ? 2 : 3;").should eq(["3"])
    interpreter.eval("true ? false ? 1 : 2 : 3;").should eq(["2"])
  end

  it "supports a ? b : c with complex expressions" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var score = 85; score > 80 ? 'high' : 'low';").should eq(["\"high\""])
    interpreter.eval("var isMember = true; isMember ? 2 : 10;").should eq(["2"])
  end

  it "applies a ? b : c precedence lower than || and &&" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("false || true ? 1 : 2;").should eq(["1"])
    interpreter.eval("false && false ? 1 : 2;").should eq(["2"])
  end

  it "supports a ? b : c in assignment" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var fee = true ? 2 : 10;").should eq([] of String)
    interpreter.eval("fee;").should eq(["2"])
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

  it "supports for...of iteration over arrays" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var x of [10, 20, 30]) console.log(x);").should eq([] of String)
    output.to_s.should eq("10\n20\n30\n")
  end

  it "supports for...of iteration over strings" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var ch of \"ab\") console.log(ch);").should eq([] of String)
    output.to_s.should eq("a\nb\n")
  end

  it "supports break inside for...of" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var result = 0; for (var x of [1, 2, 3, 4]) { if (x == 3) break; result = result + x; }").should eq([] of String)
    interpreter.eval("result;").should eq(["3"])
  end

  it "supports continue inside for...of" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var x of [1, 2, 3, 4]) { if (x == 3) continue; console.log(x); }").should eq([] of String)
    output.to_s.should eq("1\n2\n4\n")
  end

  it "supports empty array iteration in for...of" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var count = 0; for (var x of []) { count = count + 1; }").should eq([] of String)
    interpreter.eval("count;").should eq(["0"])
  end

  it "returns error for for...of with non-iterable value" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var n = 42; for (var x of n) console.log(x);").should eq(["Error: for...of requires an iterable (array or string)"])
  end

  it "supports for...in iteration over object keys" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var obj = {a: 1, b: 2, c: 3}; for (var key in obj) console.log(key, obj[key]);").should eq([] of String)
    output.to_s.should eq("a 1\nb 2\nc 3\n")
  end

  it "supports for...in with existing variable" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var key; var obj = {x: 10, y: 20}; for (key in obj) console.log(key);").should eq([] of String)
    output.to_s.should eq("x\ny\n")
  end

  it "supports break inside for...in" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var obj = {a: 1, b: 2, c: 3}; for (var key in obj) { if (key == 'b') break; console.log(key); }").should eq([] of String)
    output.to_s.should eq("a\n")
  end

  it "supports continue inside for...in" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var obj = {a: 1, b: 2, c: 3}; for (var key in obj) { if (key == 'b') continue; console.log(key); }").should eq([] of String)
    output.to_s.should eq("a\nc\n")
  end

  it "supports empty object iteration in for...in" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var count = 0; for (var key in {}) { count = count + 1; }").should eq([] of String)
    interpreter.eval("count;").should eq(["0"])
  end

  it "returns error for for...in with non-object value" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var n = 42; for (var key in n) console.log(key);").should eq(["Error: for...in requires an object"])
  end

  it "supports for...in accessing object values" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var obj = {name: 'test', count: 5}; for (var key in obj) console.log(key, obj[key]);").should eq([] of String)
    output.to_s.should eq("name test\ncount 5\n")
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

  it "supports try/catch with catch parameter binding" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var message = \"\";").should eq([] of String)
    interpreter.eval("try { throw \"boom\"; } catch (err) { message = err + \"!\"; }").should eq([] of String)
    interpreter.eval("message;").should eq(["\"boom!\""])
  end

  it "supports try/finally without catch" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 1;").should eq([] of String)
    interpreter.eval("try { value = value + 1; } finally { value = value * 3; }").should eq([] of String)
    interpreter.eval("value;").should eq(["6"])
  end

  it "propagates uncaught throw after running finally" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var marker = 0;").should eq([] of String)
    interpreter.eval("try { throw 7; } finally { marker = 1; }").should eq(["Error: uncaught 7"])
    interpreter.eval("marker;").should eq(["1"])
  end

  it "supports rethrow from catch blocks" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("try { try { throw \"inner\"; } catch (err) { throw err + \"-x\"; } } catch (outer) { outer; }").should eq(["\"inner-x\""])
  end

  it "allows finally to override return in functions" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("function pick() { try { return 1; } finally { return 2; } }").should eq([] of String)
    interpreter.eval("pick();").should eq(["2"])
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

  it "rejects let declarations with an explicit unsupported-declaration error" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("let value = 1;").should eq(["Error: unsupported declaration 'let'"])
  end

  it "rejects const declarations with an explicit unsupported-declaration error" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("const total = 2;").should eq(["Error: unsupported declaration 'const'"])
  end

  it "rejects class declarations" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("class Person {}").should eq(["Error: invalid right-hand side 'class Person {}'"])
  end

  it "rejects module import and export statements" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("import value from \"mod\";").should eq(["Error: invalid right-hand side 'import value from \"mod\"'"])
    interpreter.eval("export default 1;").should eq(["Error: invalid right-hand side 'export default 1'"])
  end

  it "rejects async and await syntax" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("async function load() {}").should eq(["Error: invalid right-hand side 'async function load() {}'"])
    interpreter.eval("await load();").should eq(["Error: invalid right-hand side 'await load()'"])
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

  it "returns error for invalid try syntax" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("try { var value = 1; }").should eq(["Error: invalid try statement"])
  end

  it "prints error for missing variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("missing;").should eq(["Error: variable 'missing' does not exist"])
  end
end

describe "RegExp literals" do
  it "parses a simple regex literal" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = /hello/;\nre.source;").should eq(["\"hello\""])
  end

  it "parses a regex literal with flags" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = /hello/gi;\nre.flags;").should eq(["\"gi\""])
  end

  it "parses a regex literal with escaped slash" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = /a\\/b/;\nre.test('a/b');").should eq(["true"])
  end

  it "parses a regex literal with character class containing slash" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/[/]/.test('/');").should eq(["true"])
  end

  it "parses a non-empty regex enclosing nothing" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = /(?:)/;\nre.source;").should eq(["\"(?:)\""])
  end

  it "returns correct typeof for regex" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("typeof /abc/;").should eq(["\"object\""])
  end
end

describe "RegExp.prototype.test" do
  it "returns true for a matching string" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/.test('hello world');").should eq(["true"])
  end

  it "returns false for a non-matching string" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/.test('world');").should eq(["false"])
  end

  it "respects the i flag" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/i.test('HELLO');").should eq(["true"])
  end

  it "respects the m flag" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/^b/m.test('a\\nb');").should eq(["true"])
  end
end

describe "RegExp.prototype.exec" do
  it "returns array with matched string" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = /hello/;\nvar m = r.exec('hello world');\nm[0];").should eq(["\"hello\""])
  end

  it "returns capture groups" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var m = /he(.)l/.exec('hello');\nm[1];").should eq(["\"l\""])
  end

  it "returns null for no match" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/.exec('world');").should eq(["null"])
  end
end

describe "RegExp constructor" do
  it "creates regex from string pattern" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = new RegExp('hello');\nre.test('hello world');").should eq(["true"])
  end

  it "creates regex from string with flags" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = new RegExp('hello', 'i');\nre.ignoreCase;").should eq(["true"])
  end

  it "copies existing RegExp" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r1 = /hello/gi;\nvar r2 = new RegExp(r1);\nr2.source;\nr2.flags;").should eq(["\"hello\"", "\"gi\""])
  end

  it "copies existing RegExp with new flags" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r1 = /hello/g;\nvar r2 = new RegExp(r1, 'i');\nr2.ignoreCase;").should eq(["true"])
  end
end

describe "RegExp properties" do
  it "exposes source property" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/gi.source;").should eq(["\"hello\""])
  end

  it "exposes flags property" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/gim.flags;").should eq(["\"gim\""])
  end

  it "exposes global property" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/g.global;").should eq(["true"])
  end

  it "exposes ignoreCase property" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/i.ignoreCase;").should eq(["true"])
  end

  it "exposes multiline property" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/m.multiline;").should eq(["true"])
  end

  it "exposes dotAll property" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/s.dotAll;").should eq(["true"])
  end

  it "exposes unicode property" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/u.unicode;").should eq(["true"])
  end
end

describe "RegExp.prototype.toString" do
  it "returns the regex string representation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/gi.toString();").should eq(["\"/hello/gi\""])
  end
end

describe "String.prototype.match with RegExp" do
  it "returns match array without global flag" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello\".match(/he(.)l/);").should eq(["[\"hell\", \"l\"]"])
  end

  it "returns all matches with global flag" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world hello\".match(/hello/g);").should eq(["[\"hello\", \"hello\"]"])
  end

  it "returns null when no match with regex" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello\".match(/xyz/);").should eq(["null"])
  end
end

describe "String.prototype.matchAll with RegExp" do
  it "returns all matches" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = \"hello world hello\".matchAll(/hello/g);\nvar s = '';\nfor (var i = 0; i < r.length; i = i + 1) s = s + r[i][0] + ',';\ns;").should eq(["\"hello,hello,\""])
  end
end

describe "String.prototype.replace with RegExp" do
  it "replaces first match without global flag" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world hello\".replace(/hello/, 'hi');").should eq(["\"hi world hello\""])
  end

  it "replaces all matches with global flag" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world hello\".replace(/hello/g, 'hi');").should eq(["\"hi world hi\""])
  end
end

describe "String.prototype.replaceAll with RegExp" do
  it "replaces all matches" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world hello\".replaceAll(/hello/g, 'hi');").should eq(["\"hi world hi\""])
  end
end

describe "String.prototype.split with RegExp" do
  it "splits by regex" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"a b  c\".split(/\\s+/);").should eq(["[\"a\", \"b\", \"c\"]"])
  end

  it "splits by regex with limit" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"a b c\".split(/\\s/, 2);").should eq(["[\"a\", \"b\"]"])
  end
end

describe "String.prototype.search with RegExp" do
  it "returns index of first match" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world\".search(/world/);").should eq(["6"])
  end

  it "returns -1 when no match" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello\".search(/xyz/);").should eq(["-1"])
  end
end

describe "JSON.stringify with RegExp" do
  it "serializes regex as null" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("JSON.stringify(/abc/);").should eq(["\"null\""])
  end
end

describe "Error" do
  it "constructs Error with message" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new Error(\"test\");").should eq([] of String)
    interpreter.eval("e.message;").should eq(["\"test\""])
  end

  it "has name property set to Error" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new Error(\"test\");").should eq([] of String)
    interpreter.eval("e.name;").should eq(["\"Error\""])
  end

  it "has a stack trace string" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new Error(\"test\");").should eq([] of String)
    interpreter.eval("e.stack.startsWith(\"Error: test\");").should eq(["true"])
  end

  it "toString returns name: message" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new Error(\"test\");").should eq([] of String)
    interpreter.eval("e.toString();").should eq(["\"Error: test\""])
  end

  it "constructs without message" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new Error();").should eq([] of String)
    interpreter.eval("e.message;").should eq(["\"\""])
  end

  it "can be thrown and caught" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var caught = \"\";").should eq([] of String)
    interpreter.eval("try { throw new Error(\"boom\"); } catch (err) { caught = err.message; }").should eq([] of String)
    interpreter.eval("caught;").should eq(["\"boom\""])
  end

  it "raw values can still be thrown and caught" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("try { throw \"raw\"; } catch (err) { err + \"!\"; }").should eq(["\"raw!\""])
  end

  it "is typeof object" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("typeof new Error(\"test\");").should eq(["\"object\""])
  end

  it "is truthy" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new Error(\"test\");").should eq([] of String)
    interpreter.eval("if (e) { \"yes\"; } else { \"no\"; }").should eq(["\"yes\""])
  end
end

describe "TypeError" do
  it "constructs with TypeError name" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new TypeError(\"wrong type\");").should eq([] of String)
    interpreter.eval("e.name;").should eq(["\"TypeError\""])
  end

  it "can be thrown and caught" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("try { throw new TypeError(\"oops\"); } catch (err) { err.name + \": \" + err.message; }").should eq(["\"TypeError: oops\""])
  end
end

describe "ReferenceError" do
  it "constructs with ReferenceError name" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new ReferenceError(\"not found\");").should eq([] of String)
    interpreter.eval("e.name;").should eq(["\"ReferenceError\""])
  end
end

describe "SyntaxError" do
  it "constructs with SyntaxError name" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new SyntaxError(\"bad syntax\");").should eq([] of String)
    interpreter.eval("e.name;").should eq(["\"SyntaxError\""])
  end
end

describe "JSON.stringify with Error" do
  it "serializes error as null via undefined return" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("typeof JSON.stringify(new Error(\"test\"));").should eq(["\"undefined\""])
  end

  it "omits error properties in objects" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("JSON.stringify({a: 1, e: new Error(\"oops\")});").should eq(["\"{\\\"a\\\":1}\""])
  end
end

describe "Array.prototype.fill" do
  it "fills entire array with a value" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3].fill(0);").should eq(["[0, 0, 0]"])
  end

  it "fills from start index" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4, 5].fill(9, 2);").should eq(["[1, 2, 9, 9, 9]"])
  end

  it "fills from start to end index" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4, 5].fill(9, 1, 3);").should eq(["[1, 9, 9, 4, 5]"])
  end

  it "handles negative start index" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4, 5].fill(0, -2);").should eq(["[1, 2, 3, 0, 0]"])
  end

  it "returns the modified array" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = [1, 2]; a.fill(9) === a;").should eq(["true"])
  end
end

describe "Array.prototype.findLast" do
  it "finds last element matching predicate" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[2, 4, 6, 8].findLast(function(v) { return v < 6; });").should eq(["4"])
  end

  it "returns undefined when no match" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3].findLast(function(v) { return v > 9; });").should eq(["undefined"])
  end

  it "passes element, index, and array to callback" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[10, 20, 30].findLast(function(v, i, a) { return i == 1; });").should eq(["20"])
  end
end

describe "Array.prototype.findLastIndex" do
  it "finds last index matching predicate" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[2, 4, 6, 8].findLastIndex(function(v) { return v < 6; });").should eq(["1"])
  end

  it "returns -1 when no match" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3].findLastIndex(function(v) { return v > 9; });").should eq(["-1"])
  end
end

describe "Array.prototype.entries" do
  it "returns [index, value] pairs" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", \"b\"].entries();").should eq(["[[0, \"a\"], [1, \"b\"]]"])
  end

  it "returns empty array for empty array" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[].entries();").should eq(["[]"])
  end
end

describe "Array.prototype.keys" do
  it "returns array of indices" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", \"b\"].keys();").should eq(["[0, 1]"])
  end

  it "returns empty array for empty array" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[].keys();").should eq(["[]"])
  end
end

describe "Array.prototype.values" do
  it "returns copy of array values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", \"b\"].values();").should eq(["[\"a\", \"b\"]"])
  end

  it "returns empty array for empty array" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[].values();").should eq(["[]"])
  end
end

describe "Array.prototype.copyWithin" do
  it "copies elements within the array" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4, 5].copyWithin(0, 3);").should eq(["[4, 5, 3, 4, 5]"])
  end

  it "handles negative indices" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4, 5].copyWithin(-2, 0);").should eq(["[1, 2, 3, 1, 2]"])
  end

  it "respects end argument" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4, 5].copyWithin(0, 0, 2);").should eq(["[1, 2, 3, 4, 5]"])
  end

  it "returns the modified array" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = [1, 2, 3]; a.copyWithin(0, 1) === a;").should eq(["true"])
  end
end

describe "Array.prototype.reduceRight" do
  it "reduces from right to left" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4].reduceRight(function(acc, val) { return acc + val; }, 0);").should eq(["10"])
  end

  it "works without initial value" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4].reduceRight(function(acc, val) { return acc + val; });").should eq(["10"])
  end

  it "processes in reverse order" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", \"b\", \"c\"].reduceRight(function(acc, val) { return acc + val; });").should eq(["\"cba\""])
  end

  it "throws on empty array without initial value" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[].reduceRight(function(a, b) { return a + b; });").should eq(["Error: Array.reduceRight cannot reduce an empty array without an initial value"])
  end
end

describe "Array.from" do
  it "creates array from string" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("Array.from(\"abc\");").should eq(["[\"a\", \"b\", \"c\"]"])
  end

  it "creates array from existing array" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("Array.from([1, 2, 3]);").should eq(["[1, 2, 3]"])
  end

  it "creates array from array-like object" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("Array.from({length: 3, \"0\": \"a\", \"1\": \"b\", \"2\": \"c\"});").should eq(["[\"a\", \"b\", \"c\"]"])
  end

  it "handles empty string" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("Array.from(\"\");").should eq(["[]"])
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

  describe "CLI" do
    it "recognizes --version flag" do
      argv = ["--version"]
      argv.size.should eq(1)
      (argv[0] == "--version" || argv[0] == "-v").should be_true
    end

    it "recognizes -v flag" do
      argv = ["-v"]
      argv.size.should eq(1)
      (argv[0] == "--version" || argv[0] == "-v").should be_true
    end
  end
end
