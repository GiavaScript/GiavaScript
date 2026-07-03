# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.1] - 2026-07-03

### Fixed
- Fix Windows CI failure where regenerated `REFERENCE.md` differed from committed version

## [0.5.0] - 2026-07-03

### Added
- `File.write()` global builtin for synchronous file writing (#77)
- `File.append()` global builtin for appending to files (#78)
- JavaScript-based reference generator replaces Python script (`scripts/generate_reference.js`) (#79)
- Broaden File method error handling from `File::Error` to `Exception` for robustness

## [0.4.0] - 2026-07-01

### Added
- `gs` shortcut symlink — run GiavaScript with `gs file.js` or `gs` for REPL (#69)
- `File.read()` and `File.readLines()` global builtins for synchronous file I/O (#67)
- `import "file.js"` statement (C-style include) for executing files in the caller's scope (#68)
- Spread/rest operator (`...`) in array literals, object literals, call arguments, and function parameters (#55)

## [0.3.0] - 2026-06-26

### Added
- `readLine()` built-in for synchronous terminal input
- `for...in` loops for iterating over object keys
- Ternary conditional operator (`condition ? consequent : alternate`)
- `--version` / `-v` CLI flag to print the GiavaScript version
- `Number.isInteger()`, `Number.isFinite()`, `Number.isNaN()` static methods
- `console.warn()` and `console.error()` writing to STDERR

## [0.2.0] - 2026-06-18

### Added
- `for...of` iteration over arrays and strings
- Regular expression literals (`/pattern/flags`) and `RegExp` runtime type
- Proper `Error` objects with stack traces
- Extended `Array.prototype` methods (`concat`, `copyWithin`, `entries`, `every`, `fill`, `filter`, `find`, `findIndex`, `flat`, `flatMap`, `forEach`, `includes`, `indexOf`, `join`, `keys`, `lastIndexOf`, `map`, `pop`, `push`, `reduce`, `reduceRight`, `reverse`, `shift`, `slice`, `some`, `sort`, `splice`, `toString`, `unshift`, `values`)
- `Array.from` static method
- Explicit error messages for unsupported `let`/`const` declarations

### Changed
- Code quality improvements: style, performance, and documentation

## [0.1.0] - 2026-06-12

### Added
- JavaScript runtime implemented in Crystal
- Tokenizer and expression parser
- Statement parsing for if, for, while, do...while, switch, try/catch/finally
- Function declarations, expressions, and calls
- Arrow function support
- Template literal support
- Built-in types: String, Array, Object, Number, Bool, Date, Math, JSON
- `console.log` built-in global function
- `typeof` and `void` operators
- `parseInt`, `parseFloat`, `isNaN` global functions
- REPL mode with `:quit` command
- File execution mode
