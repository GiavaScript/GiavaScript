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

    ### Bubble sort

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Bubble sort Average Runtime"
    x-axis ["GiavaScript (68.212s)", "Node LTS (0.804s)", "Node 0.12.18 (1.51s)"]
    y-axis "Seconds" 0 --> 75.0332
    bar [68.212, -1, -1]
    bar [-1, 0.804, -1]
    bar [-1, -1, 1.51]
```
### Matrix multiplication

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Matrix multiplication Average Runtime"
    x-axis ["GiavaScript (1.702s)", "Node LTS (0.045s)", "Node 0.12.18 (0.068s)"]
    y-axis "Seconds" 0 --> 1.8722
    bar [1.702, -1, -1]
    bar [-1, 0.045, -1]
    bar [-1, -1, 0.068]
```
### Binary search tree

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Binary search tree Average Runtime"
    x-axis ["GiavaScript (0.106s)", "Node LTS (0.761s)", "Node 0.12.18 (1.564s)"]
    y-axis "Seconds" 0 --> 1.7204
    bar [0.106, -1, -1]
    bar [-1, 0.761, -1]
    bar [-1, -1, 1.564]
```
### String slicing

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "String slicing Average Runtime"
    x-axis ["GiavaScript (0.276s)", "Node LTS (0.036s)", "Node 0.12.18 (0.067s)"]
    y-axis "Seconds" 0 --> 0.3036
    bar [0.276, -1, -1]
    bar [-1, 0.036, -1]
    bar [-1, -1, 0.067]
```
### Sieve primes

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Sieve primes Average Runtime"
    x-axis ["GiavaScript (1.623s)", "Node LTS (0.046s)", "Node 0.12.18 (0.083s)"]
    y-axis "Seconds" 0 --> 1.7853
    bar [1.623, -1, -1]
    bar [-1, 0.046, -1]
    bar [-1, -1, 0.083]
```
