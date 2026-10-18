var binary = "./giavascript_bench";
var runs = 3;
var benchmarks = [
  "numeric_loop.js",
  "fib.js",
  "array_object_churn.js",
  "string_build.js",
  "array_methods.js"
];
var build;
var name;
var best;
var run;
var start;
var result;
var elapsed;
var out;

build = process.run("crystal", [
  "build", "src/giavascript_cli.cr",
  "--release", "--no-debug",
  "-o", "giavascript_bench"
]);

if (build.status != 0) {
  console.error(build.stderr);
  process.exit(1);
}

out = console.log("Best of " + runs + " runs, release build:");
out = console.log("");

for (var name of benchmarks) {
  best = 0;

  for (run = 0; run < runs; run = run + 1) {
    start = Date.now();
    result = process.run(binary, ["benchmarks/" + name]);
    elapsed = Date.now() - start;

    if (result.status != 0) {
      console.error(name + " failed:");
      console.error(result.stderr);
      process.exit(1);
    }

    if (best == 0 || elapsed < best) best = elapsed;
  }

  out = console.log(name + ": " + Math.round(best) + " ms");
}
