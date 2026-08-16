require "./spec_helper"

describe GiavaScript do
  it "supports string concatenation with plus-equals" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = \"hello\"; a += \" world\";").should eq([] of String)
    interpreter.eval("a;").should eq(["\"hello world\""])
  end

  it "assigns string values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = \"hello world!\";").should eq([] of String)
    interpreter.eval("a;").should eq(["\"hello world!\""])
  end

  it "assigns single-quoted string values" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = 'hello world!';").should eq([] of String)
    interpreter.eval("a;").should eq(["\"hello world!\""])
  end

  it "assigns string values from another variable" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = \"hello\"; var b = a;").should eq([] of String)
    interpreter.eval("b;").should eq(["\"hello\""])
  end

  it "prints string literal result without assignment" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello world!\";").should eq(["\"hello world!\""])
  end

  it "concatenates string literals" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello\" + \" world\";").should eq(["\"hello world\""])
  end

  it "concatenates string variables" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = \"hello\"; var b = \" world\"; var c = a + b;").should eq([] of String)
    interpreter.eval("c;").should eq(["\"hello world\""])
  end

  it "concatenates string with number using coercion" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"count: \" + 5;").should eq(["\"count: 5\""])
  end

  it "concatenates number with string using coercion" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("5 + \" items\";").should eq(["\"5 items\""])
  end

  it "supports banana unary plus expression" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("('b' + 'a' + + 'a' + 'a').toLowerCase();").should eq(["\"banana\""])
  end

  it "supports mixed concatenation in assignments" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var value = 7; var x = \"value=\" + value;").should eq([] of String)
    interpreter.eval("x;").should eq(["\"value=7\""])
  end

  it "keeps dollar signs as plain string content" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"cost is $5\";").should eq(["\"cost is $5\""])
  end

  it "supports escaping quote delimiters" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"a \\\"quote\\\"\";").should eq(["\"a \\\"quote\\\"\""])
    interpreter.eval("'a \\'quote\\'';").should eq(["\"a 'quote'\""])
  end

  it "evaluates template literals without interpolation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("`hello world`;").should eq(["\"hello world\""])
  end

  it "interpolates template literal expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var name = \"GiavaScript\"; var major = 1;").should eq([] of String)
    interpreter.eval("`Hello ${name} v${major + 1}`;").should eq(["\"Hello GiavaScript v2\""])
  end

  it "supports multiline template literals and escaped interpolation markers" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("`line1\nline2`;").should eq(["\"line1\\nline2\""])
    interpreter.eval("`Price: \\${5}`;").should eq(["\"Price: ${5}\""])
  end

  it "supports nested template literal interpolation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("`outer ${`inner ${1 + 1}`}`;").should eq(["\"outer inner 2\""])
    interpreter.eval("`L1 ${`L2 ${`L3 ${3}`}`}`;").should eq(["\"L1 L2 L3 3\""])
  end

  it "uses JavaScript-like ToString semantics in string interpolation and concatenation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("`${[1, undefined, null, [2, 3]]}`;").should eq(["\"1,,,2,3\""])
    interpreter.eval("`${{ nested: true }}`;").should eq(["\"[object Object]\""])
    interpreter.eval("\"\" + [1, undefined, null, [2, 3]];").should eq(["\"1,,,2,3\""])
    interpreter.eval("\"\" + { a: 1 };").should eq(["\"[object Object]\""])
  end

  it "provides String.fromCharCode as a global static method" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("String.fromCharCode(71, 105, 97, 118, 97);").should eq(["\"Giava\""])
    interpreter.eval("String.fromCharCode();").should eq(["\"\""])
  end

  it "validates String.fromCharCode argument types" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("String.fromCharCode(65, \"66\");").should eq(["Error: String.fromCharCode argument 2 must be a number"])
  end

  it "resolves string and array builtins through type objects" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"hello\".length;").should eq(["5"])
    interpreter.eval("\"hello\".at(1);").should eq(["\"e\""])
    interpreter.eval("\"hello\".charAt(4);").should eq(["\"o\""])
    interpreter.eval("\"hello\".charCodeAt(1);").should eq(["101"])
    interpreter.eval("\"hello\".codePointAt(1);").should eq(["101"])
    interpreter.eval("\"hello\".concat(\" world\");").should eq(["\"hello world\""])
    interpreter.eval("\"abc\".endsWith(\"bc\");").should eq(["true"])
    interpreter.eval("\"abc\".includes(\"b\");").should eq(["true"])
    interpreter.eval("\"abc\".indexOf(\"b\");").should eq(["1"])
    interpreter.eval("\"abca\".lastIndexOf(\"a\");").should eq(["3"])
    interpreter.eval("\"a\".localeCompare(\"b\");").should eq(["-1"])
    interpreter.eval("\"abc\".match(\"bc\");").should eq(["[\"bc\"]"])
    interpreter.eval("\"aaaa\".matchAll(\"aa\");").should eq(["[\"aa\", \"aa\"]"])
    interpreter.eval("\"5\".padStart(3, \"0\");").should eq(["\"005\""])
    interpreter.eval("\"5\".padEnd(3, \"0\");").should eq(["\"500\""])
    interpreter.eval("\"ab\".repeat(3);").should eq(["\"ababab\""])
    interpreter.eval("\"a,b,c\".split(\",\");").should eq(["[\"a\", \"b\", \"c\"]"])
    interpreter.eval("\"hello world\".replace(\"world\", \"Giava\");").should eq(["\"hello Giava\""])
    interpreter.eval("\"foo bar foo\".replaceAll(\"foo\", \"baz\");").should eq(["\"baz bar baz\""])
    interpreter.eval("\"abcdef\".search(\"cd\");").should eq(["2"])
    interpreter.eval("\"abcdef\".slice(1, 4);").should eq(["\"bcd\""])
    interpreter.eval("\"abc\".startsWith(\"a\");").should eq(["true"])
    interpreter.eval("\"abcdef\".substring(1, 4);").should eq(["\"bcd\""])
    interpreter.eval("\"MiXeD\".toLocaleLowerCase();").should eq(["\"mixed\""])
    interpreter.eval("\"MiXeD\".toLocaleUpperCase();").should eq(["\"MIXED\""])
    interpreter.eval("\"MiXeD\".toLowerCase();").should eq(["\"mixed\""])
    interpreter.eval("\"MiXeD\".toUpperCase();").should eq(["\"MIXED\""])
    interpreter.eval("\"  spaced  \".trim();").should eq(["\"spaced\""])
    interpreter.eval("\"  spaced\".trimStart();").should eq(["\"spaced\""])
    interpreter.eval("\"spaced  \".trimEnd();").should eq(["\"spaced\""])
    interpreter.eval("\"abc\".valueOf();").should eq(["\"abc\""])
    interpreter.eval("[1, 2, 3].length;").should eq(["3"])
    interpreter.eval("var items = [1, 2, 3];").should eq([] of String)
    interpreter.eval("items.push(4);").should eq(["4"])
    interpreter.eval("items;").should eq(["[1, 2, 3, 4]"])
  end

  it "handles String.at and String.charAt out-of-range indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".at(5);").should eq(["undefined"])
    interpreter.eval("\"abc\".at(-1);").should eq(["\"c\""])
    interpreter.eval("\"abc\".charAt(5);").should eq(["\"\""])
  end

  it "supports String.slice with negative and optional end indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abcdef\".slice(-3);").should eq(["\"def\""])
    interpreter.eval("\"abcdef\".slice(-4, -1);").should eq(["\"cde\""])
    interpreter.eval("\"abcdef\".slice(4, 2);").should eq(["\"\""])
  end

  it "supports String.substring index normalization" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abcdef\".substring(4, 1);").should eq(["\"bcd\""])
    interpreter.eval("\"abcdef\".substring(-3, 2);").should eq(["\"ab\""])
    interpreter.eval("\"abcdef\".substring(2);").should eq(["\"cdef\""])
  end

  it "supports String.split optional limit and empty separator" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"a,b,c\".split(\",\", 2);").should eq(["[\"a\", \"b\"]"])
    interpreter.eval("\"abc\".split(\"\");").should eq(["[\"a\", \"b\", \"c\"]"])
    interpreter.eval("\"abc\".split(\"\", 0);").should eq(["[]"])
  end

  it "supports String.replace first-match behavior" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"aaaa\".replace(\"aa\", \"b\");").should eq(["\"baa\""])
    interpreter.eval("\"abc\".replace(\"\", \"_\");").should eq(["\"_abc\""])
    interpreter.eval("\"abc\".replace(\"z\", \"x\");").should eq(["\"abc\""])
  end

  it "supports String.match, matchAll, and search with string patterns" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abcabc\".match(\"bc\");").should eq(["[\"bc\"]"])
    interpreter.eval("\"abc\".match(\"z\");").should eq(["null"])
    interpreter.eval("\"ababa\".matchAll(\"ba\");").should eq(["[\"ba\", \"ba\"]"])
    interpreter.eval("\"abc\".matchAll(\"z\");").should eq(["[]"])
    interpreter.eval("\"abc\".search(\"b\");").should eq(["1"])
    interpreter.eval("\"abc\".search(\"z\");").should eq(["-1"])
  end

  it "supports String.padStart and padEnd" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"7\".padStart(3, \"0\");").should eq(["\"007\""])
    interpreter.eval("\"7\".padEnd(3, \"0\");").should eq(["\"700\""])
    interpreter.eval("\"abc\".padStart(2, \"0\");").should eq(["\"abc\""])
    interpreter.eval("\"abc\".padEnd(2, \"0\");").should eq(["\"abc\""])
    interpreter.eval("\"x\".padStart(5, \"\");").should eq(["\"x\""])
    interpreter.eval("\"x\".padEnd(5, \"\");").should eq(["\"x\""])
  end

  it "supports String.replaceAll special-casing for empty search" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".replaceAll(\"\", \"_\");").should eq(["\"_a_b_c_\""])
    interpreter.eval("\"abc\".replaceAll(\"b\", \"X\");").should eq(["\"aXc\""])
  end

  it "supports String.charCodeAt and String.codePointAt edge behavior" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".charCodeAt(0);").should eq(["97"])
    interpreter.eval("\"abc\".charCodeAt(9);").should eq(["NaN"])
    interpreter.eval("\"abc\".codePointAt(0);").should eq(["97"])
    interpreter.eval("\"abc\".codePointAt(9);").should eq(["undefined"])
  end

  it "supports String locale/correctness helpers" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".isWellFormed();").should eq(["true"])
    interpreter.eval("\"abc\".toWellFormed();").should eq(["\"abc\""])
    interpreter.eval("\"ABC\".toLocaleLowerCase();").should eq(["\"abc\""])
    interpreter.eval("\"abc\".toLocaleUpperCase();").should eq(["\"ABC\""])
    interpreter.eval("\"abc\".localeCompare(\"abc\");").should eq(["0"])
    interpreter.eval("\"abc\".localeCompare(\"abd\");").should eq(["-1"])
    interpreter.eval("\"abd\".localeCompare(\"abc\");").should eq(["1"])
  end

  it "rejects negative counts for String.repeat" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"ab\".repeat(-1);").should eq(["Error: String.repeat expects a non-negative integer argument"])
  end

  it "validates String argument types for simple string methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".includes(1);").should eq(["Error: String.includes expects a string argument"])
    interpreter.eval("\"abc\".indexOf(true);").should eq(["Error: String.indexOf expects a string argument"])
    interpreter.eval("\"abc\".concat(1);").should eq(["Error: String.concat expects a string argument"])
    interpreter.eval("\"abc\".split(1);").should eq(["Error: String.split expects a string argument"])
    interpreter.eval("\"abc\".replace(1, \"x\");").should eq(["Error: String.replace expects a string argument"])
    interpreter.eval("\"abc\".replaceAll(1, \"x\");").should eq(["Error: String.replaceAll expects a string argument"])
    interpreter.eval("\"abc\".search(1);").should eq(["Error: String.search expects a string argument"])
    interpreter.eval("\"abc\".match(1);").should eq(["Error: String.match expects a string argument"])
    interpreter.eval("\"abc\".matchAll(1);").should eq(["Error: String.matchAll expects a string argument"])
    interpreter.eval("\"abc\".localeCompare(1);").should eq(["Error: String.localeCompare expects a string argument"])
    interpreter.eval("\"abc\".padStart(2, 0);").should eq(["Error: String.padStart expects a string argument"])
    interpreter.eval("\"abc\".padEnd(2, 0);").should eq(["Error: String.padEnd expects a string argument"])
  end

  it "validates String index argument type" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".at(1.5);").should eq(["Error: String.at expects an integer argument"])
    interpreter.eval("\"abc\".charAt(1.5);").should eq(["Error: String.charAt expects an integer argument"])
    interpreter.eval("\"abc\".slice(1.5);").should eq(["Error: String.slice expects an integer argument"])
    interpreter.eval("\"abc\".substring(1.5);").should eq(["Error: String.substring expects an integer argument"])
    interpreter.eval("\"abc\".repeat(1.5);").should eq(["Error: String.repeat expects an integer argument"])
    interpreter.eval("\"abc\".split(\",\", 1.5);").should eq(["Error: String.split expects an integer argument"])
    interpreter.eval("\"abc\".charCodeAt(1.5);").should eq(["Error: String.charCodeAt expects an integer argument"])
    interpreter.eval("\"abc\".codePointAt(1.5);").should eq(["Error: String.codePointAt expects an integer argument"])
    interpreter.eval("\"abc\".padStart(1.5);").should eq(["Error: String.padStart expects an integer argument"])
    interpreter.eval("\"abc\".padEnd(1.5);").should eq(["Error: String.padEnd expects an integer argument"])
  end

  it "validates String slice and substring arity" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".slice();").should eq(["Error: String.slice expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".slice(0, 1, 2);").should eq(["Error: String.slice expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".substring();").should eq(["Error: String.substring expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".substring(0, 1, 2);").should eq(["Error: String.substring expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".split();").should eq(["Error: String.split expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".split(\",\", 1, 2);").should eq(["Error: String.split expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".replace();").should eq(["Error: String.replace expects 2 arguments but got 0"])
    interpreter.eval("\"abc\".replace(\"a\");").should eq(["Error: String.replace expects 2 arguments but got 1"])
    interpreter.eval("\"abc\".replaceAll(\"a\");").should eq(["Error: String.replaceAll expects 2 arguments but got 1"])
    interpreter.eval("\"abc\".charCodeAt();").should eq(["Error: String.charCodeAt expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".codePointAt();").should eq(["Error: String.codePointAt expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".padStart();").should eq(["Error: String.padStart expects between 1 and 2 arguments but got 0"])
    interpreter.eval("\"abc\".padEnd(1, \"x\", \"y\");").should eq(["Error: String.padEnd expects between 1 and 2 arguments but got 3"])
    interpreter.eval("\"abc\".match();").should eq(["Error: String.match expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".matchAll();").should eq(["Error: String.matchAll expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".search();").should eq(["Error: String.search expects 1 arguments but got 0"])
    interpreter.eval("\"abc\".localeCompare();").should eq(["Error: String.localeCompare expects 1 arguments but got 0"])
  end

  it "rejects negative limits for String.split" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"abc\".split(\",\", -1);").should eq(["Error: String.split expects a non-negative integer argument"])
  end

  it "validates String case conversion method arity" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("\"text\".toLowerCase(1);").should eq(["Error: String.toLowerCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toUpperCase(1);").should eq(["Error: String.toUpperCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toLocaleLowerCase(1);").should eq(["Error: String.toLocaleLowerCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toLocaleUpperCase(1);").should eq(["Error: String.toLocaleUpperCase expects 0 arguments but got 1"])
    interpreter.eval("\"text\".isWellFormed(1);").should eq(["Error: String.isWellFormed expects 0 arguments but got 1"])
    interpreter.eval("\"text\".toWellFormed(1);").should eq(["Error: String.toWellFormed expects 0 arguments but got 1"])
  end

end
