# GiavaScript

[![GiavaScript CI](https://github.com/memburg/GiavaScript/actions/workflows/test.yml/badge.svg)](https://github.com/memburg/GiavaScript/actions/workflows/test.yml)
![crystal](https://img.shields.io/badge/crystal-1.19.1+-000000.svg?logo=crystal&logoColor=white)

GiavaScript is an open-source, cross-platform, non-standard-compliant JavaScript runtime environment.

## Install (optimized build)

Build and install the `giavascript` executable globally:

```bash
./install.sh
```

This compiles with Crystal release optimizations and installs to `/usr/local/bin` by default.

If you prefer a user-local location:

```bash
INSTALL_DIR="$HOME/.local/bin" ./install.sh
```

## Run a Source File

```bash
giavascript path/to/program.js
```

The interpreter reads the file and executes it through the same evaluation pipeline used for in-memory strings.

## Run the REPL

```bash
giavascript
```

Exit with:

```txt
:quit
```

## JavaScript Feature Reference

Use the reference docs to track which standard JavaScript features are currently available:

- [Consolidated Reference](reference/REFERENCE.md)

Table of Contents:

- [Language](reference/Language.md)
- [Types](reference/Types.md)
- [Math](reference/Math.md)
- [JSON](reference/JSON.md)

Regenerate the consolidated file with:

```bash
python3 scripts/generate_reference.py
```

or the short wrapper:

```bash
./scripts/reference.sh
```

## Current Limitations

- Partial JavaScript support; many standard globals and language features are still missing.

## Benchmarks

Monthly benchmark results are committed to `benchmarks/performance-comparison-latest.csv` by the GitHub Actions workflow. Each chart compares average runtime for a single algorithm (lower is better).

```mermaid
xychart-beta
    title "Bubble sort Average Runtime"
    x-axis ["GiavaScript", "Node LTS", "Node 0.12.18"]
    y-axis "Seconds" 0.524 --> 1.4608
    bar [0.713, 0.655, 1.328]
```

```mermaid
xychart-beta
    title "Matrix multiplication Average Runtime"
    x-axis ["GiavaScript", "Node LTS", "Node 0.12.18"]
    y-axis "Seconds" 0.0312 --> 1.7149
    bar [1.559, 0.039, 0.062]
```

```mermaid
xychart-beta
    title "Binary search tree Average Runtime"
    x-axis ["GiavaScript", "Node LTS", "Node 0.12.18"]
    y-axis "Seconds" 0.0776 --> 1.5752
    bar [0.097, 0.642, 1.432]
```

```mermaid
xychart-beta
    title "String slicing Average Runtime"
    x-axis ["GiavaScript", "Node LTS", "Node 0.12.18"]
    y-axis "Seconds" 0.024 --> 0.2816
    bar [0.256, 0.03, 0.061]
```

- 🟦 `GiavaScript` = GiavaScript runtime
- 🟧 `Node LTS` = Node LTS v24.15.0
- 🟩 `Node 0.12.18` = Node 0.12.18
