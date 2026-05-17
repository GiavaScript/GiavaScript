var add = function(a, b) {
  return a + b;
};

var result = add(7, 5);
console.log("add(7, 5) =", result);
console.log("typeof add =", typeof add);

var factorial = function fact(n) {
  if (n <= 1) {
    return 1;
  }

  return n * fact(n - 1);
};

console.log("factorial(5) =", factorial(5));

var immediate = (function(x) {
  return x * 3;
})(4);

console.log("iife result =", immediate);

void console.log("this line is a side effect");
