# GiavaScript

[![GiavaScript CI](https://github.com/memburg/GiavaScript/actions/workflows/test.yml/badge.svg)](https://github.com/memburg/GiavaScript/actions/workflows/test.yml)

GiavaScript is a non-standard-compliant ECMAScript engine written in Crystal.

## Run the REPL

```bash
crystal run src/giavascript_cli.cr
```

Exit with:

```txt
:quit
```

## Run a Source File

```bash
crystal run src/giavascript_cli.cr -- path/to/program.ls
```

The interpreter reads the file and executes it through the same evaluation pipeline used for in-memory strings.

## Current Limitations

- No control flow or complex types yet.

## Development

Run tests:

```bash
crystal spec
```

## Benchmarks

Example benchmark scripts are available in:

- `examples/bubbleSort.js`
- `examples/matrixMultiply.js`

Run a benchmark locally with:

```bash
crystal run src/giavascript_cli.cr -- examples/bubbleSort.js
crystal run src/giavascript_cli.cr -- examples/matrixMultiply.js
```

A monthly GitHub Actions report compares GiavaScript with Node.js runtimes using these scripts.
See `.github/workflows/performance-comparison.yml`.
