# CLAUDE.md

This file provides guidance to Claude Code (claude.ai) when working with code in this repository.

## Project overview

**GiavaScript** is an open-source, cross-platform JavaScript runtime implemented in **Crystal** (>= 1.19.1). It is intentionally not ECMAScript-compliant — it implements a curated subset of JavaScript with its own hand-written tokenizer, parser, AST, and interpreter. It has **zero external Crystal shard dependencies**.

- CLI: REPL mode (no args) or file execution (single argument)
- License: MIT
- Author: Ramb Memburg

## Build, test, and run commands

```bash
shards install                                  # Install Crystal deps
crystal spec                                    # Run all tests
crystal run src/giavascript_cli.cr -- file.js   # Run a JS file
./install.sh                                    # Build and install binary
crystal tool format src/some_file.cr            # Format a single file
```

## Documentation

```bash
python3 scripts/generate_reference.py           # Regenerate consolidated REFERENCE.md
python3 scripts/run_examples_smoke.py           # Smoke test all examples
```

## Before opening a PR

1. Run `crystal spec` — all tests must pass
2. If you changed `reference/Language.md`, `Types.md`, `Math.md`, or `JSON.md`, run `python3 scripts/generate_reference.py`
3. Verify with `git diff -- reference/REFERENCE.md`

## Architecture

Source lives in `src/` with a flat module structure:

- `giavascript.cr` — Module entry, core types (`Value` union, AST nodes)
- `giavascript_cli.cr` — CLI entry (REPL + file execution)
- `giavascript/tokenizer.cr` — Lexical tokenizer
- `giavascript/ast.cr` — AST node definitions
- `giavascript/expression_parser.cr` — Parse expressions into AST
- `giavascript/expression_evaluator.cr` — Evaluate parsed expressions
- `giavascript/interpreter.cr` — Main interpreter (~1200 lines, expression eval + statement dispatch)
- `giavascript/interpreter_builtins.cr` — Built-in globals (console, parseInt, etc.)
- `giavascript/runtime_types.cr` — Runtime type implementations (String, Array, Object, Number, JSON)
- `giavascript/environment.cr` — Variable scope chains
- `giavascript/function_runtime.cr` — Function declarations, expressions, arrow functions
- `giavascript/statement_splitter.cr` — Split source into statements
- `giavascript/{if,for,while,switch,try}_statement_parser.cr` — Statement parsers

## Code conventions

- **2-space indent**, LF line endings
- Crystal idioms first; Ruby Style Guide as secondary reference
- **No external Crystal shard dependencies** — never add one unless explicitly requested
- Tests use Crystal's built-in spec framework in `spec/` directory
- Main test file: `spec/giavascript_spec.cr`
- Documentation in `reference/` (split by topic)
- State is mutable; `Interpreter` owns `Environment`, caches, and `FunctionRuntime`

## Key constraints

- **Never add external Crystal dependencies** unless explicitly requested
- Interpreter changes must not break existing spec tests
- Runtime logic and formatting changes must be separate commits/PRs
- Template literal parsing has known complexity — changes there need extra care
