# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `for...in` loops for iterating over object keys
- Ternary conditional operator (`condition ? consequent : alternate`)
- `--version` / `-v` CLI flag to print the GiavaScript version
- `Number.isInteger()`, `Number.isFinite()`, `Number.isNaN()` static methods
- `console.warn()` and `console.error()` writing to STDERR

## [0.2.0] - 2025-06-18

### Added
- `for...of` iteration over arrays and strings
- Regular expression literals (`/pattern/flags`) and `RegExp` runtime type
- Proper `Error` objects with stack traces
- Extended `Array.prototype` methods (`concat`, `copyWithin`, `entries`, `every`, `fill`, `filter`, `find`, `findIndex`, `flat`, `flatMap`, `forEach`, `includes`, `indexOf`, `join`, `keys`, `lastIndexOf`, `map`, `pop`, `push`, `reduce`, `reduceRight`, `reverse`, `shift`, `slice`, `some`, `sort`, `splice`, `toString`, `unshift`, `values`)
- `Array.from` static method
- Explicit error messages for unsupported `let`/`const` declarations

### Changed
- Code quality improvements: style, performance, and documentation

## [0.1.0] - 2025-06-12

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
