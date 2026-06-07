var nested = [1, [2, [3, [4]]], 5];
console.log("flat(2):", nested.flat(2));

var pairs = [1, 2, 3].flatMap(function(n) {
  return [n, n * 10];
});
console.log("flatMap pairs:", pairs);

var items = ["a", "b", "c", "d"];
var removed = items.splice(1, 2, "x", "y", "z");
console.log("removed:", removed);
console.log("after splice:", items);
