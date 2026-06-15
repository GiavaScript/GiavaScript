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
    ├── function_runtime.cr       # Function declarations, expressions, arrows
    ├── statement_splitter.cr     # Split source into statements
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
alias Value = Number | Bool | String | Nil | UndefinedValue | Array(Value) | Hash(String, Value) | BuiltinFunction | UserFunction | DateValue
alias Number = Int32 | Float64
```

Interpreter caches: expressions (8192 entries), raw statements (8192 entries),
evaluators (1024 entries), JSON stringify depth limit (1000).

## Commands

| Action | Command |
|--------|---------|
| Install deps | `shards install` |
| Run tests | `crystal spec` |
| Run a JS file | `crystal run src/giavascript_cli.cr -- <path/to/file.js>` |
| Build & install binary | `./install.sh` |
| Regenerate reference docs | `python3 scripts/generate_reference.py` |
| Smoke test examples | `python3 scripts/run_examples_smoke.py` |
| Format a single file | `crystal tool format <path>` |

## Before opening a PR

1. Run `crystal spec` — all tests must pass
2. If you changed reference source files (`reference/Language.md`, `Types.md`,
   `Math.md`, `JSON.md`), run `python3 scripts/generate_reference.py`
3. Verify `git diff -- reference/REFERENCE.md` shows only intended changes

## Code conventions

- **2-space indent**, LF line endings (see `.editorconfig`)
- Crystal idioms first; Ruby Style Guide as secondary reference
- No external shard dependencies — everything is hand-written
- Tests use the `spec/` directory with Crystal's built-in spec framework
- `spec_helper.cr` bootstraps the test environment
- Main test file: `spec/giavascript_spec.cr` (~1700 lines)
- Documentation in `reference/` (split by topic) + auto-generated `REFERENCE.md`

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
