require "./spec_helper"

describe "GiavaScript capability scoping" do
  it "keeps host capabilities by default" do
    engine = GiavaScript::Interpreter.new

    engine.eval_value("typeof File").should eq("object")
    engine.eval_value("typeof Path").should eq("object")
    engine.eval_value("typeof fetch").should eq("function")
    engine.eval_value("typeof process").should eq("object")
  end

  it "omits host capabilities not listed" do
    engine = GiavaScript::Interpreter.new(capabilities: [:console, :math, :json])

    engine.eval_value("typeof File").should eq("undefined")
    engine.eval_value("typeof Path").should eq("undefined")
    engine.eval_value("typeof fetch").should eq("undefined")
    engine.eval_value("typeof process").should eq("undefined")
    engine.eval_value("typeof console").should eq("object")
    engine.eval_value("typeof JSON").should eq("object")
    engine.eval_value("typeof parseInt").should eq("function")
  end

  it "installs only selected host capabilities" do
    engine = GiavaScript::Interpreter.new(capabilities: [:file])

    engine.eval_value("typeof File").should eq("object")
    engine.eval_value("typeof Path").should eq("object")
    engine.eval_value("typeof fetch").should eq("undefined")
    engine.eval_value("typeof process").should eq("undefined")
  end

  it "reports blocked globals as undefined" do
    engine = GiavaScript::Interpreter.new(capabilities: [:console])

    expect_raises(GiavaScript::ExecutionError, /File/) { engine.eval_value("File.read(\"x\")") }
    expect_raises(GiavaScript::ExecutionError, /fetch/) { engine.eval_value("fetch(\"http://example.com\")") }
    expect_raises(GiavaScript::ExecutionError, /process/) { engine.eval_value("process.exit(1)") }
  end
end
