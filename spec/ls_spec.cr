require "./spec_helper"

describe Ls do
  it "assigns integer values" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$a = 5;").should eq([] of String)
    interpreter.eval("$a").should eq(["$a = 5"])
  end

  it "assigns from another variable" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$a = 5; $another_value = $a;").should eq([] of String)
    interpreter.eval("$another_value").should eq(["$another_value = 5"])
  end

  it "prints error for missing variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$missing").should eq(["Error: variable '$missing' does not exist"])
  end
end
