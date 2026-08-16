require "./spec_helper"

describe GiavaScript do
  it "provides Object.keys, Object.values, and Object.entries as global static methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var obj = {\"name\": \"giava\", \"count\": 3, \"ok\": true};").should eq([] of String)
    interpreter.eval("Object.keys(obj);").should eq(["[\"name\", \"count\", \"ok\"]"])
    interpreter.eval("Object.values(obj);").should eq(["[\"giava\", 3, true]"])
    interpreter.eval("Object.entries(obj);").should eq(["[[\"name\", \"giava\"], [\"count\", 3], [\"ok\", true]]"])
  end

  it "provides Object.assign and Object.hasOwn as global static methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var target = {\"a\": 1}; var source = {\"b\": 2};").should eq([] of String)
    interpreter.eval("Object.assign(target, source) === target;").should eq(["true"])
    interpreter.eval("target;").should eq(["{\"a\": 1, \"b\": 2}"])
    interpreter.eval("Object.hasOwn(target, \"a\");").should eq(["true"])
    interpreter.eval("Object.hasOwn(target, \"missing\");").should eq(["false"])
    interpreter.eval("Object.hasOwn({\"1\": true}, 1);").should eq(["true"])
  end

  it "validates Object static method arity and argument types" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Object.keys();").should eq(["Error: Object.keys expects 1 arguments but got 0"])
    interpreter.eval("Object.values({}, 1);").should eq(["Error: Object.values expects 1 arguments but got 2"])
    interpreter.eval("Object.entries(1);").should eq(["Error: Object.entries argument 1 must be an object"])
    interpreter.eval("Object.assign();").should eq(["Error: Object.assign expects at least 1 arguments but got 0"])
    interpreter.eval("Object.assign({}, 1);").should eq(["Error: Object.assign argument 2 must be an object"])
    interpreter.eval("Object.hasOwn({});").should eq(["Error: Object.hasOwn expects 2 arguments but got 1"])
    interpreter.eval("Object.hasOwn({}, []);").should eq(["Error: Object.hasOwn argument 2 must be a string, number, boolean, null, or undefined"])
  end

  it "raises runtime error when Object method is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Object.keys = 5;").should eq([] of String)
    interpreter.eval("Object.keys({});").should eq(["Error: value is not callable"])
  end

  it "provides Array.isArray and Array.of as global static methods" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Array.isArray([]);").should eq(["true"])
    interpreter.eval("Array.isArray({});").should eq(["false"])
    interpreter.eval("Array.of(1, \"two\", true);").should eq(["[1, \"two\", true]"])
    interpreter.eval("Array.of();").should eq(["[]"])
  end

  it "validates Array static method arity" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Array.isArray();").should eq(["Error: Array.isArray expects 1 arguments but got 0"])
    interpreter.eval("Array.isArray([], 1);").should eq(["Error: Array.isArray expects 1 arguments but got 2"])
  end

  it "raises runtime error when Array method is overwritten with non-callable" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("Array.of = 5;").should eq([] of String)
    interpreter.eval("Array.of(1);").should eq(["Error: value is not callable"])
  end

  it "supports spread in array literals" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var a = [3, 4];").should eq([] of String)
    interpreter.eval("[1, 2, ...a, 5];").should eq(["[1, 2, 3, 4, 5]"])
    interpreter.eval("var copy = [...a]; copy;").should eq(["[3, 4]"])
    interpreter.eval("[...[], 1, ...[]];").should eq(["[1]"])
  end

  it "supports spread in object literals" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var obj = {\"a\": 1, \"b\": 2};").should eq([] of String)
    interpreter.eval("var merged = {\"c\": 3, ...obj, \"d\": 4}; merged;").should eq(["{\"c\": 3, \"a\": 1, \"b\": 2, \"d\": 4}"])
    interpreter.eval("var clone = {...obj}; clone;").should eq(["{\"a\": 1, \"b\": 2}"])
  end

  it "supports heterogeneous array literals" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", 1, 2.5];").should eq(["[\"a\", 1, 2.5]"])
  end

  it "supports empty arrays and nested arrays" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[];").should eq(["[]"])
    interpreter.eval("[1, [2, 3], []];").should eq(["[1, [2, 3], []]"])
  end

  it "supports zero-based array indexing" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = [10, 20, 30];").should eq([] of String)
    interpreter.eval("r[0];").should eq(["10"])
    interpreter.eval("r[2];").should eq(["30"])
  end

  it "supports indexing nested arrays" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = [1, [2, 3], []];").should eq([] of String)
    interpreter.eval("r[1][0];").should eq(["2"])
  end

  it "supports assigning to existing array indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var alreadyDeclaredArray = [10, 20, 30];").should eq([] of String)
    interpreter.eval("alreadyDeclaredArray[0] = 42;").should eq([] of String)
    interpreter.eval("alreadyDeclaredArray;").should eq(["[42, 20, 30]"])
  end

  it "returns undefined for out-of-range array indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var r = [10, 20, 30];").should eq([] of String)
    interpreter.eval("r[3];").should eq(["undefined"])
    interpreter.eval("r[-1];").should eq(["undefined"])
    interpreter.eval("r[1.5];").should eq(["Error: array index must be an integer"])
  end

  it "supports object literals with dot and bracket property access" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var o = { a: 10, b: 2 };").should eq([] of String)
    interpreter.eval("o.a;").should eq(["10"])
    interpreter.eval("o[\"a\"];").should eq(["10"])
  end

  it "supports empty and nested objects" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("{};").should eq(["{}"])
    interpreter.eval("var o = { x: { y: [1, 2, 3] } };").should eq([] of String)
    interpreter.eval("o.x.y[2];").should eq(["3"])
  end

  it "prints objects using colon notation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("{ a: 1, nested: { b: 2 } };").should eq(["{\"a\": 1, \"nested\": {\"b\": 2}}"])
    interpreter.eval("[{ a: 1 }];").should eq(["[{\"a\": 1}]"])
  end

  it "supports heterogeneous object values and key normalization" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var o = { aKeyValue: 12, \"another-key\": \"some text here\", 99: \"ninety nine\", \"an-object\": { \"something-inside\": [1, 2, 3] } };").should eq([] of String)
    interpreter.eval("o.aKeyValue;").should eq(["12"])
    interpreter.eval("o[\"another-key\"];").should eq(["\"some text here\""])
    interpreter.eval("o[\"99\"];").should eq(["\"ninety nine\""])
    interpreter.eval("o[\"an-object\"][\"something-inside\"][1];").should eq(["2"])
  end

  it "supports numeric key lookup with bracket expressions" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var o = { 99: \"ninety nine\" }; var k = 99;").should eq([] of String)
    interpreter.eval("o[k];").should eq(["\"ninety nine\""])
  end

  it "returns undefined for missing object properties" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var o = { a: 10 };").should eq([] of String)
    interpreter.eval("o.b;").should eq(["undefined"])
    interpreter.eval("o[\"missing\"];").should eq(["undefined"])
    interpreter.eval("o[true];").should eq(["Error: object property key must be a string or number"])
  end

  it "supports Array.at with positive and negative indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[10, 20, 30].at(1);").should eq(["20"])
    interpreter.eval("[10, 20, 30].at(-1);").should eq(["30"])
    interpreter.eval("[10, 20, 30].at(9);").should eq(["undefined"])
  end

  it "supports Array.concat without mutating the receiver" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = [1, 2]; var b = a.concat([3, 4], 5);").should eq([] of String)
    interpreter.eval("a;").should eq(["[1, 2]"])
    interpreter.eval("b;").should eq(["[1, 2, 3, 4, 5]"])
  end

  it "supports Array.includes and Array.indexOf with optional fromIndex" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var n = +undefined;").should eq([] of String)
    interpreter.eval("[1, 2, 3, 2].includes(2);").should eq(["true"])
    interpreter.eval("[1, 2, 3, 2].includes(2, 2);").should eq(["true"])
    interpreter.eval("[1, 2, 3, 2].includes(2, 4);").should eq(["false"])
    interpreter.eval("[1, 2, 3].indexOf(2);").should eq(["1"])
    interpreter.eval("[1, 2, 3, 2].indexOf(2, 2);").should eq(["3"])
    interpreter.eval("[1, 2, 3].indexOf(9);").should eq(["-1"])
    interpreter.eval("[n].includes(n);").should eq(["true"])
  end

  it "supports Array.lastIndexOf with optional fromIndex" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 2].lastIndexOf(2);").should eq(["3"])
    interpreter.eval("[1, 2, 3, 2].lastIndexOf(2, 2);").should eq(["1"])
    interpreter.eval("[1, 2, 3, 2].lastIndexOf(2, -2);").should eq(["1"])
    interpreter.eval("[1, 2, 3].lastIndexOf(9);").should eq(["-1"])
  end

  it "supports Array.join with default and custom separator" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, true, \"x\"].join();").should eq(["\"1,true,x\""])
    interpreter.eval("[1, 2, 3].join(\" - \");").should eq(["\"1 - 2 - 3\""])
  end

  it "supports Array.pop and empty-array pop behavior" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var items = [1, 2, 3];").should eq([] of String)
    interpreter.eval("items.pop();").should eq(["3"])
    interpreter.eval("items;").should eq(["[1, 2]"])
    interpreter.eval("[].pop();").should eq(["undefined"])
  end

  it "supports Array.shift and Array.unshift with in-place mutation" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var items = [2, 3];").should eq([] of String)
    interpreter.eval("items.unshift(0, 1);").should eq(["4"])
    interpreter.eval("items;").should eq(["[0, 1, 2, 3]"])
    interpreter.eval("items.shift();").should eq(["0"])
    interpreter.eval("items;").should eq(["[1, 2, 3]"])
    interpreter.eval("[].shift();").should eq(["undefined"])
  end

  it "supports Array.reverse and Array.sort as in-place operations" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var a = [1, 2, 3]; a.reverse();").should eq(["[3, 2, 1]"])
    interpreter.eval("a;").should eq(["[3, 2, 1]"])
    interpreter.eval("var b = [10, 2, 1]; b.sort();").should eq(["[1, 10, 2]"])
    interpreter.eval("b;").should eq(["[1, 10, 2]"])
  end

  it "supports Array.slice with omitted and negative indexes" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var items = [1, 2, 3, 4];").should eq([] of String)
    interpreter.eval("items.slice();").should eq(["[1, 2, 3, 4]"])
    interpreter.eval("items.slice(1, 3);").should eq(["[2, 3]"])
    interpreter.eval("items.slice(-2);").should eq(["[3, 4]"])
    interpreter.eval("items.slice(3, 1);").should eq(["[]"])
    interpreter.eval("items;").should eq(["[1, 2, 3, 4]"])
  end

  it "supports Array.flat with configurable depth" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var nested = [1, [2, [3, [4]]], 5];").should eq([] of String)
    interpreter.eval("nested.flat();").should eq(["[1, 2, [3, [4]], 5]"])
    interpreter.eval("nested.flat(2);").should eq(["[1, 2, 3, [4], 5]"])
    interpreter.eval("nested.flat(99);").should eq(["[1, 2, 3, 4, 5]"])
    interpreter.eval("nested;").should eq(["[1, [2, [3, [4]]], 5]"])
  end

  it "supports Array.flatMap" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var numbers = [1, 2, 3];").should eq([] of String)
    interpreter.eval("numbers.flatMap(function(n) { return [n, n * 10]; });").should eq(["[1, 10, 2, 20, 3, 30]"])
    interpreter.eval("numbers.flatMap(function(n) { return n * 2; });").should eq(["[2, 4, 6]"])
    interpreter.eval("numbers;").should eq(["[1, 2, 3]"])
  end

  it "supports Array.splice with insertion and deletion" do
    interpreter = GiavaScript::Interpreter.new

    interpreter.eval("var items = [1, 2, 3, 4, 5];").should eq([] of String)
    interpreter.eval("items.splice(1, 2, 9, 8);").should eq(["[2, 3]"])
    interpreter.eval("items;").should eq(["[1, 9, 8, 4, 5]"])
    interpreter.eval("items.splice(-2);").should eq(["[4, 5]"])
    interpreter.eval("items;").should eq(["[1, 9, 8]"])
  end

  it "supports callback-based Array methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var numbers = [1, 2, 3, 4];").should eq([] of String)
    interpreter.eval("var seen = []; numbers.forEach(function(value, index, array) { seen.push(value + index + array.length); });").should eq(["undefined"])
    interpreter.eval("seen;").should eq(["[5, 7, 9, 11]"])
    interpreter.eval("numbers.map(function(value, index, array) { return value * index + array.length; });").should eq(["[4, 6, 10, 16]"])
    interpreter.eval("numbers.filter(function(value, index, array) { return value + index > array.length; });").should eq(["[3, 4]"])
    interpreter.eval("numbers.some(function(value, index, array) { return value + index == array.length; });").should eq(["false"])
    interpreter.eval("numbers.every(function(value, index, array) { return value + index >= 1; });").should eq(["true"])
    interpreter.eval("numbers.find(function(value, index, array) { return value * 2 == array.length + index + 1; });").should eq(["4"])
    interpreter.eval("numbers.findIndex(function(value, index, array) { return value * 2 == array.length + index + 1; });").should eq(["3"])
  end

  it "supports multiline chained calls after assignment" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var numbers = [3, -1, 1, 4];").should eq([] of String)
    interpreter.eval(<<-JS).should eq([] of String)
      var averaged = numbers
        .filter(function(n) { return n > 0; })
        .map(function(n) { return n; });
    JS
    interpreter.eval("averaged;").should eq(["[3, 1, 4]"])
  end

  it "uses JS-compatible callback arity for array methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("var array = [1, 4, 9, 16];").should eq([] of String)
    interpreter.eval("array.map(function(x) { return x * 2; });").should eq(["[2, 8, 18, 32]"])
    interpreter.eval("array.map(function(value, index, source, extra) { return extra; });").should eq(["[undefined, undefined, undefined, undefined]"])
    interpreter.eval("[1, 2, 3].reduce(function(acc, value) { return acc + value; }, 0);").should eq(["6"])
  end

  it "uses JS-compatible callback arity for function declaration references" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("function double(value) { return value * 2; }").should eq([] of String)
    interpreter.eval("[1, 2, 3].map(double);").should eq(["[2, 4, 6]"])

    interpreter.eval("function takeFourth(value, index, source, extra) { return extra; }").should eq([] of String)
    interpreter.eval("[1, 2].map(takeFourth);").should eq(["[undefined, undefined]"])

    interpreter.eval("function sum(acc, value) { return acc + value; }").should eq([] of String)
    interpreter.eval("[1, 2, 3].reduce(sum, 0);").should eq(["6"])
  end

  it "supports Array.reduce with and without an initial value" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3].reduce(function(acc, value, index, array) { return acc + value + index + array.length; }, 0);").should eq(["18"])
    interpreter.eval("[1, 2, 3].reduce(function(acc, value, index, array) { return acc + value + index + array.length; });").should eq(["15"])
    interpreter.eval("[].reduce(function(acc, value, index, array) { return acc + value + index + array.length; }, 10);").should eq(["10"])
  end

  it "handles empty and miss cases for callback-based Array methods" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[].some(function(value, index, array) { return true; });").should eq(["false"])
    interpreter.eval("[].every(function(value, index, array) { return false; });").should eq(["true"])
    interpreter.eval("[1, 2].find(function(value, index, array) { return value == 9; });").should eq(["undefined"])
    interpreter.eval("[1, 2].findIndex(function(value, index, array) { return value == 9; });").should eq(["-1"])
  end

  it "validates Array method argument counts and index types" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1].at();").should eq(["Error: Array.at expects 1 arguments but got 0"])
    interpreter.eval("[1].join(\",\", \";\");").should eq(["Error: Array.join expects between 0 and 1 arguments but got 2"])
    interpreter.eval("[1].slice(0, 1, 2);").should eq(["Error: Array.slice expects between 0 and 2 arguments but got 3"])
    interpreter.eval("[1].includes(1, 1.5);").should eq(["Error: Array.includes expects an integer argument"])
    interpreter.eval("[1].indexOf(1, 1.5);").should eq(["Error: Array.indexOf expects an integer argument"])
    interpreter.eval("[1].lastIndexOf(1, 1.5);").should eq(["Error: Array.lastIndexOf expects an integer argument"])
    interpreter.eval("[1].slice(1.5);").should eq(["Error: Array.slice expects an integer argument"])
    interpreter.eval("[1].shift(1);").should eq(["Error: Array.shift expects 0 arguments but got 1"])
    interpreter.eval("[1].reverse(1);").should eq(["Error: Array.reverse expects 0 arguments but got 1"])
    interpreter.eval("[1].sort(1);").should eq(["Error: Array.sort expects 0 arguments but got 1"])
    interpreter.eval("[1].forEach();").should eq(["Error: Array.forEach expects 1 arguments but got 0"])
    interpreter.eval("[1].map(1);").should eq(["Error: Array.map expects a function argument"])
    interpreter.eval("[1].flat(1.5);").should eq(["Error: Array.flat expects an integer argument"])
    interpreter.eval("[1].flatMap();").should eq(["Error: Array.flatMap expects 1 arguments but got 0"])
    interpreter.eval("[1].flatMap(1);").should eq(["Error: Array.flatMap expects a function argument"])
    interpreter.eval("[1].splice();").should eq(["Error: Array.splice expects at least 1 arguments but got 0"])
    interpreter.eval("[1].splice(0, 1.5);").should eq(["Error: Array.splice expects an integer argument"])
    interpreter.eval("[1].reduce();").should eq(["Error: Array.reduce expects between 1 and 2 arguments but got 0"])
    interpreter.eval("[].reduce(function(acc, value, index, array) { return acc + value + index + array.length; });").should eq(["Error: Array.reduce cannot reduce an empty array without an initial value"])
  end

end
describe "Array.prototype.fill" do
  it "fills ranges in place" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3].fill(0);").should eq(["[0, 0, 0]"])
    interpreter.eval("[1, 2, 3, 4, 5].fill(9, 2);").should eq(["[1, 2, 9, 9, 9]"])
    interpreter.eval("[1, 2, 3, 4, 5].fill(9, 1, 3);").should eq(["[1, 9, 9, 4, 5]"])
    interpreter.eval("[1, 2, 3, 4, 5].fill(0, -2);").should eq(["[1, 2, 3, 0, 0]"])
    interpreter.eval("var a = [1, 2]; a.fill(9) === a;").should eq(["true"])
  end
end

describe "Array.prototype.findLast" do
  it "finds the last match and passes callback arguments" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[2, 4, 6, 8].findLast(function(v) { return v < 6; });").should eq(["4"])
    interpreter.eval("[1, 2, 3].findLast(function(v) { return v > 9; });").should eq(["undefined"])
    interpreter.eval("[10, 20, 30].findLast(function(v, i, a) { return i == 1; });").should eq(["20"])
  end
end

describe "Array.prototype.findLastIndex" do
  it "returns the last matching index or -1" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[2, 4, 6, 8].findLastIndex(function(v) { return v < 6; });").should eq(["1"])
    interpreter.eval("[1, 2, 3].findLastIndex(function(v) { return v > 9; });").should eq(["-1"])
  end
end

describe "Array.prototype.entries" do
  it "returns index-value pairs, including for empty arrays" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", \"b\"].entries();").should eq(["[[0, \"a\"], [1, \"b\"]]"])
    interpreter.eval("[].entries();").should eq(["[]"])
  end
end

describe "Array.prototype.keys" do
  it "returns indices, including for empty arrays" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", \"b\"].keys();").should eq(["[0, 1]"])
    interpreter.eval("[].keys();").should eq(["[]"])
  end
end

describe "Array.prototype.values" do
  it "returns copied values, including for empty arrays" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[\"a\", \"b\"].values();").should eq(["[\"a\", \"b\"]"])
    interpreter.eval("[].values();").should eq(["[]"])
  end
end

describe "Array.prototype.copyWithin" do
  it "copies ranges in place" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4, 5].copyWithin(0, 3);").should eq(["[4, 5, 3, 4, 5]"])
    interpreter.eval("[1, 2, 3, 4, 5].copyWithin(-2, 0);").should eq(["[1, 2, 3, 1, 2]"])
    interpreter.eval("[1, 2, 3, 4, 5].copyWithin(0, 0, 2);").should eq(["[1, 2, 3, 4, 5]"])
    interpreter.eval("var a = [1, 2, 3]; a.copyWithin(0, 1) === a;").should eq(["true"])
  end
end

describe "Array.prototype.reduceRight" do
  it "reduces from right to left with optional initial value" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("[1, 2, 3, 4].reduceRight(function(acc, val) { return acc + val; }, 0);").should eq(["10"])
    interpreter.eval("[1, 2, 3, 4].reduceRight(function(acc, val) { return acc + val; });").should eq(["10"])
    interpreter.eval("[\"a\", \"b\", \"c\"].reduceRight(function(acc, val) { return acc + val; });").should eq(["\"cba\""])
    interpreter.eval("[].reduceRight(function(a, b) { return a + b; });").should eq(["Error: Array.reduceRight cannot reduce an empty array without an initial value"])
  end
end

describe "Array.from" do
  it "creates arrays from supported inputs" do
    interpreter = GiavaScript::Interpreter.new
    interpreter.eval("Array.from(\"abc\");").should eq(["[\"a\", \"b\", \"c\"]"])
    interpreter.eval("Array.from([1, 2, 3]);").should eq(["[1, 2, 3]"])
    interpreter.eval("Array.from({length: 3, \"0\": \"a\", \"1\": \"b\", \"2\": \"c\"});").should eq(["[\"a\", \"b\", \"c\"]"])
    interpreter.eval("Array.from(\"\");").should eq(["[]"])
  end
end
