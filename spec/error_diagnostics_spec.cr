require "./spec_helper"

describe GiavaScript do
  describe "error diagnostics" do
    it "locates a runtime error at its statement" do
      interpreter = GiavaScript::Interpreter.new
      diagnostics = interpreter.eval_diagnostics("var a = 1;\nvar b = a + missing;")

      error = diagnostics.find(&.error?).not_nil!
      error.message.should eq("Error: variable 'missing' does not exist")
      error.line.should eq(2)
      error.column.should eq(1)
    end

    it "locates a syntax error at its statement" do
      interpreter = GiavaScript::Interpreter.new
      diagnostics = interpreter.eval_diagnostics("var a = 1;\n\nif (a > 1 {")

      error = diagnostics.find(&.error?).not_nil!
      error.line.should eq(3)
      error.column.should eq(1)
    end

    it "keeps line numbers correct across block comments" do
      interpreter = GiavaScript::Interpreter.new
      source = "var a = 1;\n/* one\n   two */\nvar b = a + nope;"

      error = interpreter.eval_diagnostics(source).find(&.error?).not_nil!
      error.line.should eq(4)
    end

    it "keeps results in output order" do
      interpreter = GiavaScript::Interpreter.new
      diagnostics = interpreter.eval_diagnostics("1 + 1; missing;")

      diagnostics.size.should eq(2)
      diagnostics[0].error?.should be_false
      diagnostics[0].message.should eq("2")
      diagnostics[1].error?.should be_true
    end

    it "still returns plain messages from eval" do
      interpreter = GiavaScript::Interpreter.new
      interpreter.eval("var b = missing;").should eq(["Error: variable 'missing' does not exist"])
    end

    it "renders a located error with a caret" do
      interpreter = GiavaScript::Interpreter.new
      source = "var a = 1;\nvar b = a + missing;"
      diagnostic = interpreter.eval_diagnostics(source).find(&.error?).not_nil!

      io = IO::Memory.new
      diagnostic.to_display(io, "demo.js", source)
      rendered = io.to_s

      rendered.should contain("error: variable 'missing' does not exist")
      rendered.should contain(" --> demo.js:2:1")
      rendered.should contain("2 | var b = a + missing;")
      rendered.should contain("^" * diagnostic.length.not_nil!)
    end
  end
end
