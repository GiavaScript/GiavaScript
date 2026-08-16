# GiavaScript — AI Instructions

## Project

GiavaScript is an open-source, cross-platform JavaScript runtime implemented in
Crystal (>= 1.19.1). It is **intentionally not ECMAScript-compliant** — it
implements a curated subset of JavaScript with its own hand-written tokenizer,
parser, AST, and interpreter. It has **zero external Crystal shard dependencies**.

- CLI: REPL mode (no args) or file execution (single argument)
- License: MIT
- Author: Ramb Memburg

## Architecture

```
src/
├── giavascript.cr            # Module entry, core types (Value union, etc.)
├── giavascript_cli.cr        # CLI entry point (REPL + file execution)
└── giavascript/              # Sub-modules
    ├── tokenizer.cr              # Lexical tokenizer
    ├── comment_stripper.cr       # Strip comments before tokenizing
    ├── string_literal_parser.cr   # String literal handling
    ├── template_literal_parser.cr # Template literal handling
    ├── ast.cr                    # AST node definitions
    ├── expression_parser.cr      # Parse expressions into AST
    ├── expression_evaluator.cr   # Evaluate parsed expressions
    ├── environment.cr            # Variable scope / environment
    ├── interpreter.cr            # Main interpreter (eval + statement dispatch)
    ├── interpreter_builtins.cr   # Built-in globals (console, parseInt, etc.)
    ├── runtime_types.cr          # Runtime type implementations
    ├── statement_tokenizer.cr    # Statement-level tokenizer
    ├── statement_parser_shared.cr # Shared statement parsing utilities
    ├── if_statement_parser.cr    # if/else parsing
    ├── for_statement_parser.cr   # for loop parsing
    ├── while_statement_parser.cr # while/do-while parsing
    ├── switch_statement_parser.cr # switch parsing
    └── try_statement_parser.cr   # try/catch/finally parsing
```

Core type alias (all runtime values):

```crystal
alias Value = Number | Bool | String | Nil | UndefinedValue | Array(Value) | Hash(String, Value) | BuiltinFunction | UserFunction | DateValue | RegExpValue | ErrorValue
alias Number = Int32 | Float64
```

Interpreter caches: expressions (8192 entries), evaluators (1024 entries), JSON
stringify depth limit (1000).

## Commands

| Action | Command |
|--------|---------|
| Run tests | `crystal spec` |
| Run a JS file | `crystal run src/giavascript_cli.cr -- <path/to/file.js>` |
| Build & install binary | `./install.sh` |
| Smoke test examples | `crystal run src/giavascript_cli.cr -- scripts/run_examples_smoke.js` |
| Format a single file | `crystal tool format <path>` |

## Before opening a PR

Run `crystal spec` before opening a PR.

## Code conventions

- **2-space indent**, LF line endings (see `.editorconfig`)
- Crystal idioms first; Ruby Style Guide as secondary reference
- No external shard dependencies — everything is hand-written
- Tests use the `spec/` directory with Crystal's built-in spec framework
- `spec_helper.cr` bootstraps the test environment
- Main test file: `spec/giavascript_spec.cr`
- Documentation lives in the four topic files under `reference/`

## Versioning

GiavaScript follows Semantic Versioning 2.0. Pre-1.0: patch bumps for bug
fixes, minor bumps for new features (breaking or not — stability not guaranteed
until 1.0).

Version is stored in two places — both must be updated together for a release:

- `shard.yml` (`version:` field)
- `src/giavascript.cr` (`VERSION` constant)

Release checklist: bump both locations, update `CHANGELOG.md`, then
`git tag v<version>`.

## Key constraints

- **Never add external Crystal dependencies** unless explicitly requested
- Changes to the interpreter must pass all existing spec tests
- Keep the runtime logic and formatting changes separate
- The `CONTRIBUTING.md` file has the full contribution workflow

## Git conventions

Before every commit, randomly choose exactly one of these co-author trailers
and include it in the commit message:

```
Co-authored-by: Linus Torvalds <torvalds@linux-foundation.org>
Co-authored-by: Brendan Eich <brendan@mozilla.org>
```

This applies to all commits in this repository — never omit the selected trailer or include both.
