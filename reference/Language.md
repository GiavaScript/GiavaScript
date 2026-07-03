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
| `import "file.js"` | Available |
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
| `typeof` operator | Available |
| `void` operator | Available |
| Unary plus (`+`) | Available |
| Comments (`//`, `/* */`) | Available |
| Template literals | Available |

### Equality operator semantics

- `==` and `!=` use coercive (loose) equality behavior.
- `===` and `!==` use strict (non-coercive) equality behavior.

### `typeof` semantics

`typeof` returns string representations of value types:

- `"number"` for `Int32` and `Float64`
- `"string"` for `String`
- `"boolean"` for `Bool`
- `"object"` for `Array`, `Hash`, and `null`
- `"function"` for callable values (user-defined and built-in)
- `"undefined"` for `undefined` and undeclared identifiers (does not throw)

### Logical operator semantics

- `a && b`: evaluates `a` first; if `a` is falsy, returns `a` and does not evaluate `b`; otherwise evaluates and returns `b`.
- `a || b`: evaluates `a` first; if `a` is truthy, returns `a` and does not evaluate `b`; otherwise evaluates and returns `b`.
- `!a`: evaluates `a` and returns a boolean negation (`true`/`false`).
- `a ? b : c`: evaluates `a` first; if `a` is truthy, evaluates and returns `b`; otherwise evaluates and returns `c`.
- Precedence: `!` binds tighter than `&&`, `&&` binds tighter than `||`, and `||` binds tighter than `? :`.

### Spread and rest parameter semantics

- Rest parameter (`...name`) must be the last formal parameter; otherwise an error is raised.
- Rest parameters are supported in function declarations, function expressions, and arrow functions.
- Rest parameter gathers exceeding arguments into an array. If there are no exceeding arguments, the rest array is empty (`[]`).
- Spread in arrays (`[...arr]`) creates a shallow copy by iterating elements into a new array. Non-array spread values are silently ignored.
- Spread in objects (`{...obj}`) copies own properties into a new object. Later keys override earlier ones. Non-object spread values are silently ignored.
- Spread in function call arguments (`fn(...arr)`) expands an array into individual arguments. Non-array spread values are silently ignored.
- Duplicate parameter names (including rest) are rejected.

## Functions and control flow

| Feature | Status |
| --- | --- |
| Function declarations (`function name(...) { ... }`) | Available |
| Function expressions (`var f = function(...) { ... }`) | Available |
| Named function expressions (`var f = function name(...) { ... }`) | Available |
| Arrow functions (`() => expr`, `x => expr`, `() => { ... }`) | Available |
| Function calls | Available |
| Spread in call arguments (`fn(...arr)`) | Available |
| Rest parameters (`function f(a, ...rest)`, arrow functions) | Available |
| Returning values with `return` | Available |
| First-class function values | Available |
| `if`, `else if`, `else` | Available |
| C-style `for` loops (`for (init; condition; update)`) | Available |
| `for...of` loops (iterate over arrays and strings) | Available |
| `for...in` loops (iterate over object keys) | Available |
| `break` / `continue` inside loops | Available |
| `while` / `do...while` loops | Available |
| Ternary operator (`a ? b : c`) | Available |
| `switch` statements | Available |
| `throw` statements | Available |
| `try` / `catch` / `finally` | Available |

## Values and collections

| Feature | Status |
| --- | --- |
| `null` | Available |
| `undefined` | Available |
| Array literals and indexing | Available |
| Spread in arrays (`[...arr]`) | Available |
| Object literals | Available |
| Spread in objects (`{...obj}`) | Available |
| Dot and bracket property access | Available |
| Template literals | Available |

## Classic global functions

| Feature | Status |
| --- | --- |
| `parseInt()` | Available |
| `parseFloat()` | Available |
| `isNaN()` | Available |
| `readLine()` | Available |
| `Date.now()` | Available |
| `new Date()` | Available |
| `console.log()` | Available |
| `console.warn()` | Available |
| `console.error()` | Available |
| `File.read()` | Available |
| `File.readLines()` | Available |
| `File.write()` | Available |
| `File.append()` | Available |

## Notes

- This reflects the current behavior in the interpreter and specs.
- `let` and `const` declarations return explicit errors: `Error: unsupported declaration 'let'` and `Error: unsupported declaration 'const'`.
- Use `var` for variable declarations.
- Statements can be separated by newlines without requiring semicolons. A semicolon is not required when two statements are on separate lines.
