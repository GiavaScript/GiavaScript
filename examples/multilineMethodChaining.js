var numbers = [3, -1, 1, 4];

var positive = numbers
  .filter(function(n) {
    return n > 0;
  })
  .map(function(n) {
    return n * 2;
  });

console.log("doubled positives =", positive);
