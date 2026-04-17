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

  it "evaluates integer arithmetic" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$result = 2 + 3 * 4;").should eq([] of String)
    interpreter.eval("$result").should eq(["$result = 14"])
  end

  it "prints expression result without assignment" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("2 + 3 * 4").should eq(["14"])
  end

  it "prints expression result using variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$a = 5;").should eq([] of String)
    interpreter.eval("$a + 1").should eq(["6"])
  end

  it "evaluates float arithmetic" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$ratio = 7 / 2;").should eq([] of String)
    interpreter.eval("$ratio").should eq(["$ratio = 3.5"])
  end

  it "supports mixed arithmetic with variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$a = 10; $b = 2.5; $c = ($a - 2) * $b;").should eq([] of String)
    interpreter.eval("$c").should eq(["$c = 20.0"])
  end

  it "prints error for division by zero" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$x = 4 / 0;").should eq(["Error: division by zero"])
  end

  it "prints error for invalid arithmetic" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$x = 5 + ;").should eq(["Error: invalid right-hand side '5 +'"])
  end

  it "prints error for missing variables" do
    interpreter = Ls::Interpreter.new
    interpreter.eval("$missing").should eq(["Error: variable '$missing' does not exist"])
  end
end
