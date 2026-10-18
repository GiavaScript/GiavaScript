var values = [];

for (var i = 0; i < 100000; i = i + 1) {
  values.push({ index: i, value: i * 2 });
}

var total = 0;

for (var j = 0; j < values.length; j = j + 1) {
  total = total + values[j].value % 1000;
}

console.log(total);
