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

## Versioning

GiavaScript follows Semantic Versioning 2.0.

Target audience: pre-1.0
- Bug fixes: bump the patch version (0.1.x)
- New features: bump the minor version (0.x.0)
- Breaking changes: bump the minor version as well (pre-1.0, so no
  compatibility guarantees yet)

Version is defined in two places:
- `shard.yml` (`version:` field)
- `src/giavascript.cr` (`VERSION` constant)

To cut a release:
1. Bump version in both files
2. Update `CHANGELOG.md`
3. Run `crystal spec` and regenerate `REFERENCE.md` if needed
4. Commit and tag: `git tag v<version>`
5. Push: `git push && git push --tags`

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
