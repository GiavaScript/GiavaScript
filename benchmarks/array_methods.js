var values = [];

for (var i = 0; i < 20000; i = i + 1) {
  values.push(i);
}

var total = values
  .filter(function (n) { return n % 2 == 0; })
  .map(function (n) { return n * 2; })
  .reduce(function (sum, n) { return sum + n; }, 0);

console.log(total);
