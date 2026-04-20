# GiavaScript

[![GiavaScript CI](https://github.com/memburg/GiavaScript/actions/workflows/test.yml/badge.svg)](https://github.com/memburg/GiavaScript/actions/workflows/test.yml)

GiavaScript is subset of JavaScript.

At the current stage, it focuses on variable handling and arithmetic inside a REPL.

## What GiavaScript Can Do Right Now

- Declare variables with `var name = value;`.
- Declare variables with `var name;` (defaults to `undefined`).
- Reassign existing variables with `name = value;`.
- Use semicolons optionally; newlines also separate statements.
- Evaluate arithmetic expressions with `+`, `-`, `*`, `/`, `%`, `^`, and parentheses.
- Concatenate strings with `+` (numbers are coerced to strings when needed).
- Use string literals with double quotes (`"text"`) or single quotes (`'text'`).
- Define functions with local variables and `return` values (including `return;` for `undefined`).
- Use `null` and `undefined` values.
- Use braces for block constructs like function bodies.
- Print a variable by typing its name.
- Show an error when a variable does not exist.

Supported examples:

```javascript
var a = 5;
var b = 2.5;
var message = "hello world!";
var greeting = 'hello' + " world";
var label = "count: " + 5;
var value = 44;
var line = "plain text";
var line2 = 'single quoted string';
var line3 = "sum text";
var empty = null;
var not_set;
line3;
empty;
not_set;

function sum_numbers(a, b) {
  return a + b + value;
}

var total = sum_numbers(1, 2);
var another_value = a;
var result = (a + value) / b;
message;
another_value;
```

## Run the REPL

```bash
crystal run src/ls_cli.cr
```

Exit with:

```txt
:quit
```

## Current Limitations

- No control flow or complex types yet.

## Development

Run tests:

```bash
crystal spec
```
