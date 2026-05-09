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

Monthly benchmark results are committed to `benchmarks/performance-comparison-latest.csv` by the GitHub Actions workflow. This chart uses interleaved bars so each benchmark keeps three separate runtime values (lower is better).

```mermaid
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#1f77b4, #ff7f0e, #2ca02c"}}}}%%
xychart-beta
    title "Median Runtime by Benchmark and Runtime"
    x-axis ["Bubble-Gia", "Bubble-LTS", "Bubble-0.12", "Matrix-Gia", "Matrix-LTS", "Matrix-0.12", "BST-Gia", "BST-LTS", "BST-0.12", "Slicing-Gia", "Slicing-LTS", "Slicing-0.12"]
    y-axis "Seconds" 0 --> 1.7149
    bar [0.713, 0.655, 1.328, 1.559, 0.039, 0.062, 0.097, 0.642, 1.432, 0.256, 0.03, 0.061]
```

- 🟦 `*-Gia` = GiavaScript
- 🟧 `*-LTS` = Node LTS v24.15.0
- 🟩 `*-0.12` = Node 0.12.18
