require "./spec_helper"

describe GiavaScript do
end
describe "RegExp literals" do
  it "parses literals and exposes their basic metadata" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = /hello/;\nre.source;").should eq(["\"hello\""])
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = /hello/gi;\nre.flags;").should eq(["\"gi\""])
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = /a\\/b/;\nre.test('a/b');").should eq(["true"])
    interpreter.eval("/[/]/.test('/');").should eq(["true"])
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = /(?:)/;\nre.source;").should eq(["\"(?:)\""])
    interpreter.eval("typeof /abc/;").should eq(["\"object\""])
  end
end

describe "RegExp.prototype.test" do
  it "matches strings and respects flags" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/.test('hello world');").should eq(["true"])
    interpreter.eval("/hello/.test('world');").should eq(["false"])
    interpreter.eval("/hello/i.test('HELLO');").should eq(["true"])
    interpreter.eval("/^b/m.test('a\\nb');").should eq(["true"])
  end
end

describe "RegExp.prototype.exec" do
  it "returns matches and captures or null" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = /hello/;\nvar m = r.exec('hello world');\nm[0];").should eq(["\"hello\""])
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var m = /he(.)l/.exec('hello');\nm[1];").should eq(["\"l\""])
    interpreter.eval("/hello/.exec('world');").should eq(["null"])
  end
end

describe "RegExp constructor" do
  it "creates and copies regular expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = new RegExp('hello');\nre.test('hello world');").should eq(["true"])
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var re = new RegExp('hello', 'i');\nre.ignoreCase;").should eq(["true"])
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r1 = /hello/gi;\nvar r2 = new RegExp(r1);\nr2.source;\nr2.flags;").should eq(["\"hello\"", "\"gi\""])
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r1 = /hello/g;\nvar r2 = new RegExp(r1, 'i');\nr2.ignoreCase;").should eq(["true"])
  end
end

describe "RegExp properties" do
  it "exposes source and flag properties" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/gi.source;").should eq(["\"hello\""])
    interpreter.eval("/hello/gim.flags;").should eq(["\"gim\""])
    interpreter.eval("/hello/g.global;").should eq(["true"])
    interpreter.eval("/hello/i.ignoreCase;").should eq(["true"])
    interpreter.eval("/hello/m.multiline;").should eq(["true"])
    interpreter.eval("/hello/s.dotAll;").should eq(["true"])
    interpreter.eval("/hello/u.unicode;").should eq(["true"])
  end
end

describe "RegExp.prototype.toString" do
  it "returns the regex string representation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("/hello/gi.toString();").should eq(["\"/hello/gi\""])
  end
end

describe "String.prototype.match with RegExp" do
  it "handles local, global, and missing matches" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello\".match(/he(.)l/);").should eq(["[\"hell\", \"l\"]"])
    interpreter.eval("\"hello world hello\".match(/hello/g);").should eq(["[\"hello\", \"hello\"]"])
    interpreter.eval("\"hello\".match(/xyz/);").should eq(["null"])
  end
end

describe "String.prototype.matchAll with RegExp" do
  it "returns all matches" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = \"hello world hello\".matchAll(/hello/g);\nvar s = '';\nfor (var i = 0; i < r.length; i = i + 1) s = s + r[i][0] + ',';\ns;").should eq(["\"hello,hello,\""])
  end
end

describe "String.prototype.replace with RegExp" do
  it "uses the global flag to control replacement count" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world hello\".replace(/hello/, 'hi');").should eq(["\"hi world hello\""])
    interpreter.eval("\"hello world hello\".replace(/hello/g, 'hi');").should eq(["\"hi world hi\""])
  end
end

describe "String.prototype.replaceAll with RegExp" do
  it "replaces all matches" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world hello\".replaceAll(/hello/g, 'hi');").should eq(["\"hi world hi\""])
  end
end

describe "String.prototype.split with RegExp" do
  it "splits by regex with an optional limit" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"a b  c\".split(/\\s+/);").should eq(["[\"a\", \"b\", \"c\"]"])
    interpreter.eval("\"a b c\".split(/\\s/, 2);").should eq(["[\"a\", \"b\"]"])
  end
end

describe "String.prototype.search with RegExp" do
  it "returns the first match index or -1" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world\".search(/world/);").should eq(["6"])
    interpreter.eval("\"hello\".search(/xyz/);").should eq(["-1"])
  end
end

describe "JSON.stringify with RegExp" do
  it "serializes regex as null" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("JSON.stringify(/abc/);").should eq(["\"null\""])
  end
end
