require "./spec_helper"

describe GiavaScript do
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

end
