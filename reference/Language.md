# Language Features

Status of core JavaScript language features in GiavaScript.

## Declarations and assignments

| Feature | Status |
| --- | --- |
| `var` declaration | Available |
| `var` without initializer | Available |
| Reassignment with `=` | Available |
| Compound assignment (`+=`, `-=`, `*=`, `/=`) | Available |
| Postfix increment and decrement (`++`, `--`) | Available |
| `let` | Not available |
| `const` | Not available |

## Expressions and operators

| Feature | Status |
| --- | --- |
| Numeric literals (`int`, `float`) | Available |
| String literals (single and double quotes) | Available |
| Arithmetic (`+`, `-`, `*`, `/`, `%`) | Available |
| Exponent operator (`^`, non-standard) | Available |
| Parenthesized expressions | Available |
| Comparisons (`<`, `>`, `<=`, `>=`) | Available |
| Equality (`==`, `!=`) | Available |
| Strict equality (`===`, `!==`) | Available |
| Logical operators (`&&`, `\|\|`, `!`) | Available |

### Equality operator semantics

- `==` and `!=` use coercive (loose) equality behavior.
- `===` and `!==` use strict (non-coercive) equality behavior.

### Logical operator semantics

- `a && b`: evaluates `a` first; if `a` is falsy, returns `a` and does not evaluate `b`; otherwise evaluates and returns `b`.
- `a || b`: evaluates `a` first; if `a` is truthy, returns `a` and does not evaluate `b`; otherwise evaluates and returns `b`.
- `!a`: evaluates `a` and returns a boolean negation (`true`/`false`).
- Precedence: `!` binds tighter than `&&`, and `&&` binds tighter than `||`.

## Functions and control flow

| Feature | Status |
| --- | --- |
| Function declarations (`function name(...) { ... }`) | Available |
| Function calls | Available |
| Returning values with `return` | Available |
| First-class function values | Available |
| `if`, `else if`, `else` | Available |
| `for (...)` loops | Available |
| `break` / `continue` inside loops | Available |
| `while` / `do...while` loops | Available |
| `switch` statements | Available |

## Values and collections

| Feature | Status |
| --- | --- |
| `null` | Available |
| `undefined` | Available |
| Array literals and indexing | Available |
| Object literals | Available |
| Dot and bracket property access | Available |
| Template literals | Available |

## Classic global functions

| Feature | Status |
| --- | --- |
| `parseInt()` | Available |
| `parseFloat()` | Available |
| `isNaN()` | Available |

Notes:
- This reflects current behavior in the interpreter and specs.
