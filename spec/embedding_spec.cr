require "./spec_helper"

describe "GiavaScript embedding" do
  it "evaluates source to typed values" do
    engine = GiavaScript::Interpreter.new

    engine.eval_value("1 + 1").should eq(2)
    engine.eval_value("\"hi\"").should eq("hi")
    engine.eval_value("true").should eq(true)
    engine.eval_value("null").should eq(nil)
    engine.eval_value("var x = 3; x * 2").should eq(6)
  end

  it "gets and sets global bindings" do
    engine = GiavaScript::Interpreter.new

    engine.set("answer", 42)
    engine.get("answer").should eq(42)
    engine.eval_value("answer + 1").should eq(43)
    engine.get("missing").should eq(GiavaScript::UNDEFINED)
  end

  it "registers and calls host functions" do
    engine = GiavaScript::Interpreter.new
    engine.register("double") { |args| args[0].as(Int32) * 2 }

    engine.eval_value("double(21)").should eq(42)
    engine.call("double", [21] of GiavaScript::Value).should eq(42)
  end

  it "calls JavaScript-defined functions" do
    engine = GiavaScript::Interpreter.new
    engine.eval_value("function add(a, b) { return a + b; }")

    engine.call("add", [2, 3] of GiavaScript::Value).should eq(5)
  end

  it "raises ExecutionError on evaluation and call failures" do
    engine = GiavaScript::Interpreter.new

    expect_raises(GiavaScript::ExecutionError, /missing/) { engine.eval_value("missing;") }
    expect_raises(GiavaScript::ExecutionError, /uncaught/) { engine.eval_value("throw new Error(\"boom\");") }
    expect_raises(GiavaScript::ExecutionError, /does not exist/) { engine.call("nope") }

    engine.set("value", 5)
    expect_raises(GiavaScript::ExecutionError, /not a function/) { engine.call("value") }
  end

  it "keeps eval returning diagnostic strings" do
    engine = GiavaScript::Interpreter.new

    engine.eval("1 + 1").should eq(["2"])
    engine.eval("missing;").should eq(["Error: variable 'missing' does not exist"])
  end
end
