var items = [];

for (var i = 1000; i > 0; i -= 1) {
  items.push(i);
}

var pass = 0;
var j = 0;
var tmp = 0;

for (; pass < items.length - 1; pass += 1) {
  for (j = 0; j < items.length - 1 - pass; j += 1) {
    if (items[j] > items[j + 1]) {
      tmp = items[j];
      items[j] = items[j + 1];
      items[j + 1] = tmp;
    }
  }
}