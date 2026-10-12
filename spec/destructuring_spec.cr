require "./spec_helper"

describe GiavaScript do
  it "destructures arrays into var declarations" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var [a, b] = [1, 2];").should eq([] of String)
    interpreter.eval("a;").should eq(["1"])
    interpreter.eval("b;").should eq(["2"])
  end

  it "collects array rest elements" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var [first, ...rest] = [1, 2, 3];").should eq([] of String)
    interpreter.eval("first;").should eq(["1"])
    interpreter.eval("rest;").should eq(["[2, 3]"])
  end

  it "applies array defaults only for undefined" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var [a = 5, b = 6] = [1];").should eq([] of String)
    interpreter.eval("a;").should eq(["1"])
    interpreter.eval("b;").should eq(["6"])
    interpreter.eval("var [c = 5] = [null];").should eq([] of String)
    interpreter.eval("c;").should eq(["null"])
  end

  it "destructures objects with shorthand and renaming" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var {name, age: years} = {name: 'Ada', age: 36};").should eq([] of String)
    interpreter.eval("name;").should eq(["\"Ada\""])
    interpreter.eval("years;").should eq(["36"])
  end

  it "collects object rest properties" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var {a, ...others} = {a: 1, b: 2, c: 3};").should eq([] of String)
    interpreter.eval("a;").should eq(["1"])
    interpreter.eval("others;").should eq(["{\"b\": 2, \"c\": 3}"])
  end

  it "applies object defaults only for undefined" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var {a = 1} = {};").should eq([] of String)
    interpreter.eval("a;").should eq(["1"])
    interpreter.eval("var {b = 1} = {b: null};").should eq([] of String)
    interpreter.eval("b;").should eq(["null"])
  end

  it "destructures nested patterns" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var {user: {name}} = {user: {name: 'Ada'}};").should eq([] of String)
    interpreter.eval("name;").should eq(["\"Ada\""])
    interpreter.eval("var [[x], y] = [[1], 2];").should eq([] of String)
    interpreter.eval("x;").should eq(["1"])
    interpreter.eval("var [{z}] = [{z: 9}];").should eq([] of String)
    interpreter.eval("z;").should eq(["9"])
  end

  it "supports let and const destructuring" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("let [a, b] = [1, 2];").should eq([] of String)
    interpreter.eval("a;").should eq(["1"])
    interpreter.eval("const {c} = {c: 3};").should eq([] of String)
    interpreter.eval("c;").should eq(["3"])
  end

  it "destructures arrays assigned to existing variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 0; var b = 0;").should eq([] of String)
    interpreter.eval("[a, b] = [10, 20];").should eq([] of String)
    interpreter.eval("a;").should eq(["10"])
    interpreter.eval("b;").should eq(["20"])
  end

  it "destructures strings into characters" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var [a, b] = 'hi';").should eq([] of String)
    interpreter.eval("a + b;").should eq(["\"hi\""])
  end

  it "reports a missing initializer" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var [a, b];").should eq(["Error: destructuring declaration requires an initializer"])
  end

  it "rejects redeclaring a destructured variable" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 1;").should eq([] of String)
    interpreter.eval("var [a] = [2];").should eq(["Error: variable 'a' already exists"])
  end

  it "rejects assignment to a destructured constant" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("const {a} = {a: 1};").should eq([] of String)
    interpreter.eval("[a] = [2];").should eq(["Error: assignment to constant variable 'a'"])
  end
end
