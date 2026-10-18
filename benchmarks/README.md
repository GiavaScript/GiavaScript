# Benchmarks

Small, deterministic programs that exercise interpreter hot paths. Use them to
measure the effect of performance changes.

## Run

From the repository root:

```bash
crystal run src/giavascript_cli.cr -- benchmarks/run.js
```

The runner builds a release binary (`giavascript_bench`, gitignored) and reports
the best of three runs for each benchmark.

## Benchmarks

| File | Focus |
| --- | --- |
| `numeric_loop.js` | Loop and arithmetic dispatch |
| `fib.js` | Recursive function calls |
| `array_object_churn.js` | Arrays, object literals, property access |
| `string_build.js` | String concatenation |
| `array_methods.js` | `filter` / `map` / `reduce` callbacks |

## Baseline

Measured on macOS 26.6, Apple M4, Crystal 1.21.0, with `--release --no-debug`:

| Benchmark | Best of 3 |
| --- | --- |
| `numeric_loop.js` | 344 ms |
| `fib.js` | 750 ms |
| `array_object_churn.js` | 168 ms |
| `string_build.js` | 309 ms |
| `array_methods.js` | 355 ms |

Numbers are machine-specific. Compare a fresh run against these on the same
machine before drawing conclusions.
