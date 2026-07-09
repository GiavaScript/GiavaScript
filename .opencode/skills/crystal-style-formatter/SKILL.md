---
name: crystal-style-formatter
description: Formats Crystal code consistently using Ruby Style Guide principles adapted for Crystal
---

## Project conventions

- 2-space indent, LF line endings (see `.editorconfig`)
- Crystal idioms first; Ruby Style Guide as secondary reference
- Source lives in `src/`, tests in `spec/`, docs in `reference/`
- Module namespace: `GiavaScript` — all types live under this module
- No external shard dependencies — never introduce `require` of external libraries
- Format with `crystal tool format <path>` as the authoritative formatter; use
  it before manual edits when possible
- The main test file is `spec/giavascript_spec.cr` (~1688 lines); formatting
  changes must not break tests

## Key files

| File | What's inside |
|------|---------------|
| `src/giavascript.cr` | Module entry, `Value` type alias, forward declarations |
| `src/giavascript/interpreter.cr` | Main interpreter class (~1200 lines) |
| `src/giavascript/ast.cr` | AST node definitions |
| `src/giavascript/expression_parser.cr` | Parser |

## Crystal-specific adaptation rules

- Respect Crystal idioms first (type annotations, nilable handling, blocks, macro syntax, symbols, named args)
- Do not force Ruby constructs that are unidiomatic or invalid in Crystal
- Prefer existing project conventions when they are already consistent

## When handling a formatting request

- Briefly state what style issues you are addressing
- Apply edits directly to files when asked to format code
- If available and requested, run `crystal tool format <path>` and then fix remaining issues
- Summarize what changed and list the files touched

## Hard constraints

- Never change runtime logic unless required to resolve a pure formatting issue
- Do not add new dependencies or tools unless explicitly requested
- If a style decision is ambiguous, choose the option closest to Ruby Style Guide conventions while remaining idiomatic Crystal
- Do not commit formatting changes — let the user decide when to commit
