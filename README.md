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
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Bubble sort Average Runtime"
    x-axis ["GiavaScript (0.713s)", "Node LTS (0.655s)", "Node 0.12.18 (1.328s)"]
    y-axis "Seconds" 0 --> 1.4608
    bar [0.713, -1, -1]
    bar [-1, 0.655, -1]
    bar [-1, -1, 1.328]
```

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Matrix multiplication Average Runtime"
    x-axis ["GiavaScript (1.559s)", "Node LTS (0.039s)", "Node 0.12.18 (0.062s)"]
    y-axis "Seconds" 0 --> 1.7149
    bar [1.559, -1, -1]
    bar [-1, 0.039, -1]
    bar [-1, -1, 0.062]
```

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Binary search tree Average Runtime"
    x-axis ["GiavaScript (0.097s)", "Node LTS (0.642s)", "Node 0.12.18 (1.432s)"]
    y-axis "Seconds" 0 --> 1.5752
    bar [0.097, -1, -1]
    bar [-1, 0.642, -1]
    bar [-1, -1, 1.432]
```

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "String slicing Average Runtime"
    x-axis ["GiavaScript (0.256s)", "Node LTS (0.03s)", "Node 0.12.18 (0.061s)"]
    y-axis "Seconds" 0 --> 0.2816
    bar [0.256, -1, -1]
    bar [-1, 0.03, -1]
    bar [-1, -1, 0.061]
```
