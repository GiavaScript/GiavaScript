var label = "start";

try {
  throw "boom";
} catch (err) {
  label = "caught: " + err;
} finally {
  label = label + " (cleanup)";
}

console.log(label);
