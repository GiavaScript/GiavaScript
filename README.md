<p align="center">
  <picture align="center">
    <source media="(prefers-color-scheme: dark)" srcset="assets/gs_logo_light.png" width="350">
    <source media="(prefers-color-scheme: light)" srcset="assets/gs_logo.png" width="350">
    <img alt="GiavaScript Logo" src="gs.png">
  </picture>
</p>
<h1 align="center">GiavaScript</h1>

<p align="center">
  <a href="https://github.com/memburg/GiavaScript/actions/workflows/linux.yml">
    <img src="https://github.com/memburg/GiavaScript/actions/workflows/linux.yml/badge.svg" alt="Linux CI" />
  </a>
  <a href="https://github.com/memburg/GiavaScript/actions/workflows/macos.yml">
    <img src="https://github.com/memburg/GiavaScript/actions/workflows/macos.yml/badge.svg" alt="macOS CI" />
  </a>
  <a href="https://github.com/memburg/GiavaScript/actions/workflows/windows.yml">
    <img src="https://github.com/memburg/GiavaScript/actions/workflows/windows.yml/badge.svg" alt="Windows CI" />
  </a>
  <a href="https://crystal-lang.org/">
    <img src="https://img.shields.io/badge/crystal-1.19.1+-000000.svg?logo=crystal&logoColor=white" alt="Crystal" />
  </a>
</p>

GiavaScript is an open-source, cross-platform JavaScript runtime implemented in Crystal.

It intentionally does not aim for full ECMAScript compliance. Check the reference docs before relying on specific language features.

## Quick start

### Prerequisites

- [Crystal](https://crystal-lang.org/) 1.19.1 or later
- Python 3 (only needed to regenerate `reference/REFERENCE.md`)

### Install the CLI

```bash
git clone https://github.com/memburg/GiavaScript.git
cd GiavaScript
./install.sh
```

This installs the `giavascript` binary to `/usr/local/bin` by default.

Install to a user-local path instead of `/usr/local/bin`:

```bash
INSTALL_DIR="$HOME/.local/bin" ./install.sh
```

Make sure your install directory is on `PATH`.

## CLI usage

### Start the REPL

```bash
giavascript
```

REPL commands:

- `:quit` exits the REPL.

### Run a file

```bash
giavascript path/to/program.js
```

Behavior to expect:

- Empty files return an error.
- If a runtime error occurs, messages are written to standard error.
- Process exit code is `1` when any `Error:` message is produced; otherwise `0`.

### Run without installing

```bash
crystal run src/giavascript_cli.cr -- examples/templateLiterals.js
```

## Development workflow

Install dependencies and run tests:

```bash
shards install
crystal spec
```

Regenerate consolidated reference docs after editing files under `reference/`:

```bash
python3 scripts/generate_reference.py
```

CI verifies that `reference/REFERENCE.md` matches generated output.

## JavaScript feature reference

- [Consolidated reference](reference/REFERENCE.md)
- [Language features](reference/Language.md)
- [Type methods and properties](reference/Types.md)
- [Math](reference/Math.md)
- [JSON](reference/JSON.md)

## Examples

Sample programs are in `examples/`:

- `examples/templateLiterals.js` - string interpolation and expression formatting
- `examples/matrixMultiply.js` - nested loops and array indexing
- `examples/sievePrimes.js` - control flow and simple algorithm implementation

Run any example with:

```bash
giavascript examples/templateLiterals.js
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, test, and documentation update guidelines.
