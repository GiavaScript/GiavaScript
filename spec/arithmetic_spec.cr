require "./spec_helper"

describe GiavaScript do
  it "supports compound assignment operators" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 10; a += 5; a -= 3; a *= 2; a /= 4;").should eq([] of String)
    interpreter.eval("a;").should eq(["6.0"])
  end

  it "supports bitwise compound assignment operators" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 5; a &= 3; a |= 2; a ^= 1; a <<= 2; a >>= 1;").should eq([] of String)
    interpreter.eval("a;").should eq(["4"])
  end

  it "evaluates integer arithmetic" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var result = 2 + 3 * 4;").should eq([] of String)
    interpreter.eval("result;").should eq(["14"])
  end

  it "evaluates bitwise expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("5 & 3;").should eq(["1"])
    interpreter.eval("5 | 3;").should eq(["7"])
    interpreter.eval("5 ^ 3;").should eq(["6"])
    interpreter.eval("~0;").should eq(["-1"])
    interpreter.eval("8 >> 2;").should eq(["2"])
    interpreter.eval("1 << 3;").should eq(["8"])
  end

  it "evaluates bitwise operator precedence" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("5 | 3 & 1;").should eq(["5"])
    interpreter.eval("5 & 3 | 1;").should eq(["1"])
    interpreter.eval("1 | 2 ^ 3 & 4;").should eq(["3"])
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

end
