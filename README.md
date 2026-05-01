# GiavaScript

[![GiavaScript CI](https://github.com/memburg/GiavaScript/actions/workflows/test.yml/badge.svg)](https://github.com/memburg/GiavaScript/actions/workflows/test.yml)

GiavaScript is a non-standard-compliant ECMAScript engine written in Crystal.

## JavaScript Feature Reference

Use the reference docs to track which standard JavaScript features are currently available:

- Consolidated view: `reference/REFERENCE.md`
- Topic files: `reference/Language.md`, `reference/Types.md`, `reference/Math.md`, `reference/JSON.md`

Regenerate the consolidated file with:

```bash
python3 scripts/generate_reference.py
```

or the short wrapper:

```bash
./scripts/reference.sh
```

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

- Partial JavaScript support; many standard globals and language features are still missing.

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
