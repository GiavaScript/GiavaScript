require "benchmark"
require "../src/giavascript"

def run_script(source : String)
  interpreter = GiavaScript::Interpreter.new(IO::Memory.new)
  result = interpreter.eval(source)
  if result.any? { |line| line.starts_with?("Error:") }
    raise "Benchmark script failed: #{result.join(" | ")}"
  end
end

function_calls_script = <<-JS
var outside = 1;
function addWithOutside(a, b) {
  return a + b + outside;
}
var total = 0;
for (var i = 0; i < 1000; i++) {
  total += addWithOutside(1, 2);
}
JS

compound_assignment_script = <<-JS
var x = 1;
for (var i = 0; i < 5000; i++) {
  x += 2;
  x -= 1;
  x *= 2;
  x /= 2;
}
JS

math_pow_script = <<-JS
var total = 0;
for (var i = 0; i < 3000; i++) {
  total += 3 ^ 12;
}
JS

Benchmark.ips do |bench|
  bench.report("function_calls") { run_script(function_calls_script) }
  bench.report("compound_assignment") { run_script(compound_assignment_script) }
  bench.report("pow_int") { run_script(math_pow_script) }
end
