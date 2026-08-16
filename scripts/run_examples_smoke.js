var listing = process.run("crystal", [
  "eval",
  "Dir.mkdir_p(\"bin\"); Dir.glob(\"examples/*.js\").sort.each { |path| puts path }"
]);

if (listing.status != 0) {
  console.error(listing.stdout + listing.stderr);
  process.exit(listing.status);
}

var examples = listing.stdout.trim().split("\n");
if (examples.length == 1 && examples[0] == "") {
  console.error("No examples found under examples/*.js");
  process.exit(1);
}

var binary = "bin/giavascript-smoke";
var build = process.run("crystal", [
  "build",
  "src/giavascript_cli.cr",
  "-o",
  binary
]);

if (build.status != 0) {
  console.error(build.stdout + build.stderr);
  process.exit(build.status);
}

var failures = [];
var result;
for (var example of examples) {
  console.log("Running " + example);
  result = process.run(binary, [example]);

  if (result.status != 0) {
    failures.push(example);
    console.error(result.stdout + result.stderr);
  }
}

if (failures.length > 0) {
  console.error("\nExample smoke tests failed:");
  for (var failure of failures) {
    console.error("- " + failure);
  }
  process.exit(1);
}

console.log("All " + examples.length + " example smoke tests passed");
process.exit(0);
