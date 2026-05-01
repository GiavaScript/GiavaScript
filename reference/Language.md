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
| Strict equality (`===`, `!==`) | Not available |
| Logical operators (`&&`, `\|\|`, `!`) | Not available |

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
| `while` / `do...while` loops | Not available |
| `switch` statements | Not available |

## Values and collections

| Feature | Status |
| --- | --- |
| `null` | Available |
| `undefined` | Available |
| Array literals and indexing | Available |
| Object literals | Available |
| Dot and bracket property access | Available |
| Template literals | Not available |

Notes:
- This reflects current behavior in the interpreter and specs.
