require "./spec_helper"

describe GiavaScript do
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

  it "supports complex defaults and trailing parameter commas" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval(%(function defaults(text = "hello", number = (1 + 2), values = [3, 4],) { return text + number + values[1]; })).should eq([] of String)
    interpreter.eval("defaults();").should eq(["\"hello34\""])
    interpreter.eval(%(var arrow = (value = [5, 6],) => value[1];)).should eq([] of String)
    interpreter.eval("arrow();").should eq(["6"])
  end

  it "does not overwrite existing bindings with function declarations" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var existing = 1; function existing() {}").should eq(["Error: variable 'existing' already exists"])
    interpreter.eval("existing;").should eq(["1"])
    interpreter.eval("function Math() {}").should eq(["Error: variable 'Math' already exists"])
    interpreter.eval("typeof Math;").should eq(["\"object\""])
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

  it "supports rest parameters in named functions" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("function collect(first, ...rest) { return rest; }")
    interpreter.eval("collect(1, 2, 3, 4);").should eq(["[2, 3, 4]"])
    interpreter.eval("collect(42);").should eq(["[]"])
  end

  it "supports rest parameters in arrow functions" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var arrow = (a, b, ...rest) => rest;")
    interpreter.eval("arrow(1, 2, 3, 4);").should eq(["[3, 4]"])
    interpreter.eval("arrow(1, 2);").should eq(["[]"])
  end

  it "supports spread in function call arguments" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("function sum(a, b, c) { return a + b + c; }")
    interpreter.eval("var nums = [10, 20, 30];")
    interpreter.eval("sum(...nums);").should eq(["60"])
  end

  it "validates rest parameter must be last" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("function bad(...a, b) { }").should eq(["Error: rest parameter must be last"])
    interpreter.eval("function bad2(a, ...b, c) { }").should eq(["Error: rest parameter must be last"])
  end

  it "keeps strict arity for non-callback function declaration calls" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function addOne(x) { return x + 1; }").should eq([] of String)
    interpreter.eval("addOne(1, 2);").should eq(["Error: function 'addOne' expects 1 arguments but got 2"])
    interpreter.eval("var ref = addOne;").should eq([] of String)
    interpreter.eval("ref(1, 2);").should eq(["Error: function 'addOne' expects 1 arguments but got 2"])
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

end
