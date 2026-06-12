# Contributing to GiavaScript

Thanks for contributing to GiavaScript.

This guide covers the local workflow CI expects, so your changes are easy to review and merge.

## Prerequisites

- [Crystal](https://crystal-lang.org/) 1.19.1 or later
- Python 3

## Local setup

```bash
git clone https://github.com/memburg/GiavaScript.git
cd GiavaScript
shards install
```

## Build and run

Run the CLI directly from source:

```bash
crystal run src/giavascript_cli.cr -- examples/templateLiterals.js
```

Or install the binary:

```bash
./install.sh
```

## Run tests

```bash
crystal spec
```

Run this before opening a pull request.

## Documentation updates

If you change any reference source file in `reference/` (`Language.md`, `Types.md`, `Math.md`, or `JSON.md`), regenerate the consolidated file:

```bash
python3 scripts/generate_reference.py
```

Before opening a pull request, make sure `reference/REFERENCE.md` shows no unintended changes in `git diff`. If your PR intentionally updates the reference docs, run the generator first. CI checks that this file matches the generator output; a mismatch will fail the build.

## Pull request checklist

- Keep changes focused and scoped.
- Update docs for any user-facing behavior changes.
- Run `crystal spec`.
- Regenerate `reference/REFERENCE.md` when needed.
- Include a short summary of behavior changes in your PR description.

## Recommended pre-PR command sequence

```bash
crystal spec
python3 scripts/generate_reference.py
git diff -- reference/REFERENCE.md
```
