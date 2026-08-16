require "./spec_helper"

describe GiavaScript do
  it "runs if branch when condition is truthy" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 1; if (value) value = 2;").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "runs else branch when condition is falsy" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (value) value = 2; else value = 3;").should eq([] of String)
    interpreter.eval("value;").should eq(["3"])
  end

  it "supports if without else" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 4; if (0) value = 8;").should eq([] of String)
    interpreter.eval("value;").should eq(["4"])
  end

  it "supports if / else if / else chains" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (0) value = 1; else if (1) value = 2; else value = 3;").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "supports braced blocks in if statements" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (1) { value = 9; }").should eq([] of String)
    interpreter.eval("value;").should eq(["9"])
  end

  it "supports braced blocks in else statements" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (0) { value = 1; } else { value = 7; }").should eq([] of String)
    interpreter.eval("value;").should eq(["7"])
  end

  it "supports nested if with dangling else" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (1) if (0) value = 1; else value = 2;").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "executes only the selected if chain branch" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 0; if (0) value = missing; else if (1) value = 7; else value = anotherMissing;").should eq([] of String)
    interpreter.eval("value;").should eq(["7"])
  end

  it "supports single-line if statements without braces" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("if (true) console.log(\"hello!\");").should eq(["undefined"])
    output.to_s.should eq("hello!\n")
  end

  it "supports logical operators with short-circuit semantics" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("true && false;").should eq(["false"])
    interpreter.eval("true || false;").should eq(["true"])
    interpreter.eval("!0;").should eq(["true"])
    interpreter.eval("!1;").should eq(["false"])
    interpreter.eval("5 && 9;").should eq(["9"])
    interpreter.eval("0 || 7;").should eq(["7"])
    interpreter.eval("\"\" || \"fallback\";").should eq(["\"fallback\""])
    interpreter.eval("false && missing;").should eq(["false"])
    interpreter.eval("true || missing;").should eq(["true"])
    interpreter.eval("false && (1 / 0);").should eq(["false"])
    interpreter.eval("true || (1 / 0);").should eq(["true"])
    interpreter.eval("missing && true;").should eq(["Error: variable 'missing' does not exist"])
  end

  it "applies logical operator precedence" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("true || false && false;").should eq(["true"])
    interpreter.eval("(true || false) && false;").should eq(["false"])
  end

  it "supports a ? b : c expression" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("true ? 99 : 88;").should eq(["99"])
    interpreter.eval("false ? 99 : 88;").should eq(["88"])
  end

  it "supports a ? b : c with truthy condition" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("1 ? 'hello' : 'world';").should eq(["\"hello\""])
    interpreter.eval("'nonempty' ? 42 : 0;").should eq(["42"])
  end

  it "supports a ? b : c with falsey condition" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("0 ? 'yes' : 'no';").should eq(["\"no\""])
    interpreter.eval("'' ? 'yes' : 'no';").should eq(["\"no\""])
    interpreter.eval("null ? 'yes' : 'no';").should eq(["\"no\""])
    interpreter.eval("undefined ? 'yes' : 'no';").should eq(["\"no\""])
  end

  it "supports nested a ? b : c ? d : e (right-associative)" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("true ? 1 : false ? 2 : 3;").should eq(["1"])
    interpreter.eval("false ? 1 : false ? 2 : 3;").should eq(["3"])
    interpreter.eval("true ? false ? 1 : 2 : 3;").should eq(["2"])
  end

  it "supports a ? b : c with complex expressions" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var score = 85; score > 80 ? 'high' : 'low';").should eq(["\"high\""])
    interpreter.eval("var isMember = true; isMember ? 2 : 10;").should eq(["2"])
  end

  it "applies a ? b : c precedence lower than || and &&" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("false || true ? 1 : 2;").should eq(["1"])
    interpreter.eval("false && false ? 1 : 2;").should eq(["2"])
  end

  it "supports a ? b : c in assignment" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var fee = true ? 2 : 10;").should eq([] of String)
    interpreter.eval("fee;").should eq(["2"])
  end

  it "supports ECMAScript-style for loop with all components" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var i = 0; i < 3; i = i + 1) console.log(i);").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports postfix increment in for update" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var i = 0; i < 3; i++) console.log(i);").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports compound assignment in for update" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var i = 0; i < 3; i += 1) console.log(i);").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports for loop with missing components" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; for (; i < 2;) { console.log(i); i = i + 1; }").should eq([] of String)
    output.to_s.should eq("0\n1\n")
  end

  it "propagates runtime errors raised inside for-loop bodies" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("for (;;) { Math.sqrt(); }").should eq(["Error: Math.sqrt expects 1 arguments but got 0"])
  end

  it "supports for (;;) with break" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var i = 0; for (;;) { i = i + 1; break; }").should eq([] of String)
    interpreter.eval("i;").should eq(["1"])
  end

  it "supports continue in for loops" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var i = 0; i < 4; i = i + 1) { if (i == 2) continue; console.log(i); }").should eq([] of String)
    output.to_s.should eq("0\n1\n3\n")
  end

  it "runs update before next condition check on continue" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var i = 0; var seen = 0; for (; i < 3; i = i + 1) { if (i == 1) continue; seen = seen + 1; }").should eq([] of String)
    interpreter.eval("i;").should eq(["3"])
    interpreter.eval("seen;").should eq(["2"])
  end

  it "supports for...of iteration over arrays" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var x of [10, 20, 30]) console.log(x);").should eq([] of String)
    output.to_s.should eq("10\n20\n30\n")
  end

  it "supports for...of iteration over strings" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var ch of \"ab\") console.log(ch);").should eq([] of String)
    output.to_s.should eq("a\nb\n")
  end

  it "supports break inside for...of" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var result = 0; for (var x of [1, 2, 3, 4]) { if (x == 3) break; result = result + x; }").should eq([] of String)
    interpreter.eval("result;").should eq(["3"])
  end

  it "supports continue inside for...of" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("for (var x of [1, 2, 3, 4]) { if (x == 3) continue; console.log(x); }").should eq([] of String)
    output.to_s.should eq("1\n2\n4\n")
  end

  it "supports empty array iteration in for...of" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var count = 0; for (var x of []) { count = count + 1; }").should eq([] of String)
    interpreter.eval("count;").should eq(["0"])
  end

  it "returns error for for...of with non-iterable value" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var n = 42; for (var x of n) console.log(x);").should eq(["Error: for...of requires an iterable (array or string)"])
  end

  it "supports for...in iteration over object keys" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var obj = {a: 1, b: 2, c: 3}; for (var key in obj) console.log(key, obj[key]);").should eq([] of String)
    output.to_s.should eq("a 1\nb 2\nc 3\n")
  end

  it "supports for...in with existing variable" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var key; var obj = {x: 10, y: 20}; for (key in obj) console.log(key);").should eq([] of String)
    output.to_s.should eq("x\ny\n")
  end

  it "supports break inside for...in" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var obj = {a: 1, b: 2, c: 3}; for (var key in obj) { if (key == 'b') break; console.log(key); }").should eq([] of String)
    output.to_s.should eq("a\n")
  end

  it "supports continue inside for...in" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var obj = {a: 1, b: 2, c: 3}; for (var key in obj) { if (key == 'b') continue; console.log(key); }").should eq([] of String)
    output.to_s.should eq("a\nc\n")
  end

  it "supports empty object iteration in for...in" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var count = 0; for (var key in {}) { count = count + 1; }").should eq([] of String)
    interpreter.eval("count;").should eq(["0"])
  end

  it "returns error for for...in with non-object value" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var n = 42; for (var key in n) console.log(key);").should eq(["Error: for...in requires an object"])
  end

  it "supports for...in accessing object values" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var obj = {name: 'test', count: 5}; for (var key in obj) console.log(key, obj[key]);").should eq([] of String)
    output.to_s.should eq("name test\ncount 5\n")
  end

  it "supports while loops" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; while (i < 3) { console.log(i); i = i + 1; }").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports continue in while loops" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; while (i < 4) { i = i + 1; if (i == 3) continue; console.log(i); }").should eq([] of String)
    output.to_s.should eq("1\n2\n4\n")
  end

  it "supports do...while loops" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; do { console.log(i); i = i + 1; } while (i < 3);").should eq([] of String)
    output.to_s.should eq("0\n1\n2\n")
  end

  it "supports do...while loops without whitespace before block" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; do{ console.log(i); i = i + 1; } while (i < 2);").should eq([] of String)
    output.to_s.should eq("0\n1\n")
  end

  it "runs do...while body at least once" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var i = 0; do { i = i + 1; } while (0);").should eq([] of String)
    interpreter.eval("i;").should eq(["1"])
  end

  it "supports switch with matching case and break" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 0; switch (2) { case 1: value = 1; break; case 2: value = 7; break; default: value = 9; }").should eq([] of String)
    interpreter.eval("value;").should eq(["7"])
  end

  it "supports switch fallthrough behavior" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 0; switch (1) { case 1: value = 1; case 2: value = value + 2; break; default: value = 99; }").should eq([] of String)
    interpreter.eval("value;").should eq(["3"])
  end

  it "uses strict matching semantics in switch cases" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 0; switch (1) { case \"1\": value = 1; break; default: value = 2; }").should eq([] of String)
    interpreter.eval("value;").should eq(["2"])
  end

  it "supports default clauses and case labels after default" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 0; switch (4) { case 1: value = 1; break; default: value = 2; case 3: value = value + 3; break; }").should eq([] of String)
    interpreter.eval("value;").should eq(["5"])
  end

  it "allows continue inside switch when nested in loops" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var i = 0; var seen = 0; while (i < 3) { i = i + 1; switch (i) { case 2: continue; default: seen = seen + 1; } }").should eq([] of String)
    interpreter.eval("seen;").should eq(["2"])
  end

  it "returns runtime error for continue in switch outside loops" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("switch (1) { case 1: continue; }").should eq(["Error: continue can only be used inside loops"])
  end

  it "supports try/catch with catch parameter binding" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var message = \"\";").should eq([] of String)
    interpreter.eval("try { throw \"boom\"; } catch (err) { message = err + \"!\"; }").should eq([] of String)
    interpreter.eval("message;").should eq(["\"boom!\""])
  end

  it "supports try/finally without catch" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var value = 1;").should eq([] of String)
    interpreter.eval("try { value = value + 1; } finally { value = value * 3; }").should eq([] of String)
    interpreter.eval("value;").should eq(["6"])
  end

  it "propagates uncaught throw after running finally" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var marker = 0;").should eq([] of String)
    interpreter.eval("try { throw 7; } finally { marker = 1; }").should eq(["Error: uncaught 7"])
    interpreter.eval("marker;").should eq(["1"])
  end

  it "supports rethrow from catch blocks" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("try { try { throw \"inner\"; } catch (err) { throw err + \"-x\"; } } catch (outer) { outer; }").should eq(["\"inner-x\""])
  end

  it "allows finally to override return in functions" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("function pick() { try { return 1; } finally { return 2; } }").should eq([] of String)
    interpreter.eval("pick();").should eq(["2"])
  end

  it "stops block execution after first runtime error" do
    output = IO::Memory.new
    interpreter = GiavaScript::Interpreter.new(output)

    interpreter.eval("var i = 0; while (i < 1) { missing; console.log(\"after\"); i = i + 1; }").should eq(["Error: variable 'missing' does not exist"])
    output.to_s.should eq("")
  end

  it "returns runtime error for break outside loops" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("break;").should eq(["Error: break can only be used inside loops or switch statements"])
  end

  it "returns runtime error for continue outside loops" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("continue;").should eq(["Error: continue can only be used inside loops"])
  end

end
describe "Error" do
  it "constructs Error with standard properties and behavior" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new Error(\"test\");").should eq([] of String)
    interpreter.eval("e.message;").should eq(["\"test\""])
    interpreter.eval("e.name;").should eq(["\"Error\""])
    interpreter.eval("e.stack.startsWith(\"Error: test\");").should eq(["true"])
    interpreter.eval("e.toString();").should eq(["\"Error: test\""])
    interpreter.eval("if (e) { \"yes\"; } else { \"no\"; }").should eq(["\"yes\""])
  end

  it "constructs without message" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new Error();").should eq([] of String)
    interpreter.eval("e.message;").should eq(["\"\""])
  end

  it "can be thrown and caught" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var caught = \"\";").should eq([] of String)
    interpreter.eval("try { throw new Error(\"boom\"); } catch (err) { caught = err.message; }").should eq([] of String)
    interpreter.eval("caught;").should eq(["\"boom\""])
  end

  it "raw values can still be thrown and caught" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("try { throw \"raw\"; } catch (err) { err + \"!\"; }").should eq(["\"raw!\""])
  end

  it "is typeof object" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("typeof new Error(\"test\");").should eq(["\"object\""])
  end
end

describe "TypeError" do
  it "constructs with TypeError name" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new TypeError(\"wrong type\");").should eq([] of String)
    interpreter.eval("e.name;").should eq(["\"TypeError\""])
  end

  it "can be thrown and caught" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("try { throw new TypeError(\"oops\"); } catch (err) { err.name + \": \" + err.message; }").should eq(["\"TypeError: oops\""])
  end
end

describe "ReferenceError" do
  it "constructs with ReferenceError name" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new ReferenceError(\"not found\");").should eq([] of String)
    interpreter.eval("e.name;").should eq(["\"ReferenceError\""])
  end
end

describe "SyntaxError" do
  it "constructs with SyntaxError name" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var e = new SyntaxError(\"bad syntax\");").should eq([] of String)
    interpreter.eval("e.name;").should eq(["\"SyntaxError\""])
  end
end

describe "JSON.stringify with Error" do
  it "serializes error as null via undefined return" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("typeof JSON.stringify(new Error(\"test\"));").should eq(["\"undefined\""])
  end

  it "omits error properties in objects" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("JSON.stringify({a: 1, e: new Error(\"oops\")});").should eq(["\"{\\\"a\\\":1}\""])
  end
end
