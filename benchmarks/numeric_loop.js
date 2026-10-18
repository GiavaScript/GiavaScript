var total = 0;

for (var i = 0; i < 500000; i = i + 1) {
  total = total + i % 7;
}

console.log(total);
