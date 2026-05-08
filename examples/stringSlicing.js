var text = "abcdefghijklmnopqrstuvwxyz";
var total = 0;
var i = 0;
var slicePart = "";
var substringPart = "";
var tail = "";

for (i = 0; i < 30000; i = i + 1) {
  slicePart = text.slice(3, 20);
  substringPart = text.substring(2, 18);
  tail = text.slice(-5);
  total = total + slicePart.length + substringPart.length + tail.length;
}

console.log("string slicing total", total);
