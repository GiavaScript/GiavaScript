require "./spec_helper"

describe GiavaScript do
  it "returns undefined for optional property access on null and undefined" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("null?.foo;").should eq(["undefined"])
    interpreter.eval("undefined?.foo;").should eq(["undefined"])
  end

  it "accesses properties through an optional chain" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var obj = { a: { b: 2 } };").should eq([] of String)
    interpreter.eval("obj?.a?.b;").should eq(["2"])
  end

  it "short-circuits the rest of an optional chain" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("null?.a.b;").should eq(["undefined"])
    interpreter.eval("var missing; missing?.a[0]();").should eq(["undefined"])
  end

  it "still errors on non-optional access after an existing target" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var obj = { a: null };").should eq([] of String)
    interpreter.eval("obj?.a.b;").should eq(["Error: cannot access property 'b' of null"])
  end

  it "supports optional index access" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var items = [10, 20];").should eq([] of String)
    interpreter.eval("items?.[1];").should eq(["20"])
    interpreter.eval("null?.[0];").should eq(["undefined"])
  end

  it "supports optional calls with and without arguments" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var obj = { greet: function(name) { return name; } };").should eq([] of String)
    interpreter.eval("obj?.greet('Ada');").should eq(["\"Ada\""])
    interpreter.eval("var fn = null; fn?.();").should eq(["undefined"])
  end

  it "ignores falsy non-nullish targets for optional access" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var zero = 0;").should eq([] of String)
    interpreter.eval("zero?.toString();").should eq(["\"0\""])
  end

  it "returns the right operand of ?? for null and undefined" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("null ?? 3;").should eq(["3"])
    interpreter.eval("undefined ?? 3;").should eq(["3"])
  end

  it "keeps falsy left operands of ??" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("0 ?? 3;").should eq(["0"])
    interpreter.eval("false ?? true;").should eq(["false"])
    interpreter.eval("'' ?? 'fallback';").should eq(["\"\""])
  end

  it "chains the ?? operator" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("null ?? undefined ?? 4;").should eq(["4"])
  end

  it "binds ?? looser than ||" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("null ?? 0 || 9;").should eq(["9"])
    interpreter.eval("1 ?? 0 && 5;").should eq(["1"])
  end

  it "keeps ternary parsing intact" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("true ? 1 : 2;").should eq(["1"])
    interpreter.eval("false?1:2;").should eq(["2"])
  end
end
