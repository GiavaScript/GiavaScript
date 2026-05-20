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

GiavaScript is an open-source, cross-platform, non-standard-compliant JavaScript runtime environment.

## Get Started

1. Clone the repository:

   ```bash
   git clone https://github.com/memburg/GiavaScript.git
   cd GiavaScript
   ```

2. Ensure [Crystal](https://crystal-lang.org/) 1.19.1+ is installed and available in your `PATH`.

3. Build and install the `giavascript` binary:

   ```bash
   ./install.sh
   ```

   If you prefer a user-local install path, run:

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
