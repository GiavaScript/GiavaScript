require "./spec_helper"

describe GiavaScript do
  describe "source positions" do
    it "reports 1-based line and column on tokens" do
      tokenizer = GiavaScript::Tokenizer.new("foo\n  bar")

      first = tokenizer.next_token
      first.lexeme.should eq("foo")
      first.line.should eq(1)
      first.column.should eq(1)

      second = tokenizer.next_token
      second.lexeme.should eq("bar")
      second.line.should eq(2)
      second.column.should eq(3)
    end

    it "attaches spans to AST nodes on a multi-line expression" do
      expr = GiavaScript::ExpressionParser.new("1 +\n 2 * x").parse

      outer = expr.span.not_nil!
      outer.line.should eq(1)
      outer.column.should eq(1)
      outer.length.should eq(10)

      right = expr.as(GiavaScript::BinaryExpr).right
      inner = right.span.not_nil!
      inner.line.should eq(2)
      inner.column.should eq(2)
      inner.length.should eq(5)
    end

    it "attaches spans to statement nodes" do
      source = "var a = 1;\nif (a) { a; }"
      parsed = GiavaScript::IfStatementParser.new(source).parse_from(source.index("if").not_nil!)

      span = parsed.statement.span.not_nil!
      span.line.should eq(2)
      span.column.should eq(1)
      span.length.should eq("if (a) { a; }".size)
    end
  end
end
