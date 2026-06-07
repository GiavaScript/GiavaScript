var before = Date.now();
var now = new Date();
var after = Date.now();

console.log("timestamp:", now.getTime());
console.log("iso:", now.toString());
console.log("within range:", now.getTime() >= before && now.getTime() <= after);
