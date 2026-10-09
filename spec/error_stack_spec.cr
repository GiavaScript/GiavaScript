require "./spec_helper"

describe GiavaScript do
  it "shows user function frames for uncaught errors" do
    interpreter = GiavaScript::Interpreter.new
    source = "function inner() { throw new Error('boom'); }\nfunction outer() { inner(); }\nouter();"
    interpreter.eval(source).should eq(["Error: uncaught Error: boom\n    at inner\n    at outer"])
  end

  it "omits frames for top-level uncaught throws" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("throw new Error('x');").should eq(["Error: uncaught Error: x"])
  end

  it "keeps the message when a thrown error is caught" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var caught = '';").should eq([] of String)
    interpreter.eval("function fail() { throw new TypeError('oops'); }\ntry { fail(); } catch (err) { caught = err.name + ': ' + err.message; }").should eq([] of String)
    interpreter.eval("caught;").should eq(["\"TypeError: oops\""])
  end

  it "labels anonymous functions in the stack" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var fail = () => { throw new Error('arrow'); };").should eq([] of String)
    interpreter.eval("fail();").should eq(["Error: uncaught Error: arrow\n    at anonymous"])
  end

  it "adds a frame for each level of nesting" do
    interpreter = GiavaScript::Interpreter.new
    source = "function a() { throw new Error('deep'); }\nfunction b() { a(); }\nfunction c() { b(); }\nc();"
    interpreter.eval(source).should eq(["Error: uncaught Error: deep\n    at a\n    at b\n    at c"])
  end
end
