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
    x-axis ["GiavaScript (11.835s)", "Node LTS (0.673s)", "Node 0.12.18 (48.417s)"]
    y-axis "Seconds" 0 --> 53.2587
    bar [11.835, -1, -1]
    bar [-1, 0.673, -1]
    bar [-1, -1, 48.417]
```
### Matrix multiplication

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Matrix multiplication Average Runtime"
    x-axis ["GiavaScript (0.25s)", "Node LTS (0.035s)", "Node 0.12.18 (1.88s)"]
    y-axis "Seconds" 0 --> 2.068
    bar [0.25, -1, -1]
    bar [-1, 0.035, -1]
    bar [-1, -1, 1.88]
```
### Binary search tree

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Binary search tree Average Runtime"
    x-axis ["GiavaScript (0.112s)", "Node LTS (0.721s)", "Node 0.12.18 (48.13s)"]
    y-axis "Seconds" 0 --> 52.943
    bar [0.112, -1, -1]
    bar [-1, 0.721, -1]
    bar [-1, -1, 48.13]
```
### String slicing

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "String slicing Average Runtime"
    x-axis ["GiavaScript (0.037s)", "Node LTS (0.029s)", "Node 0.12.18 (1.952s)"]
    y-axis "Seconds" 0 --> 2.1472
    bar [0.037, -1, -1]
    bar [-1, 0.029, -1]
    bar [-1, -1, 1.952]
```
### Sieve primes

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4a4a4a, #2e7d32, #d4b000"}}}}%%
xychart-beta
    title "Sieve primes Average Runtime"
    x-axis ["GiavaScript (0.226s)", "Node LTS (0.035s)", "Node 0.12.18 (1.903s)"]
    y-axis "Seconds" 0 --> 2.0933
    bar [0.226, -1, -1]
    bar [-1, 0.035, -1]
    bar [-1, -1, 1.903]
```
