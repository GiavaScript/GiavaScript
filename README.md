# GiavaScript

[![GiavaScript CI](https://github.com/memburg/GiavaScript/actions/workflows/test.yml/badge.svg)](https://github.com/memburg/GiavaScript/actions/workflows/test.yml)

GiavaScript is a small interpreted language written in Crystal.

At the current stage, it focuses on variable handling and arithmetic inside a REPL.

## What GiavaScript Can Do Right Now

- Declare variables with `var name = value;`.
- Reassign existing variables with `name = value;`.
- Evaluate arithmetic expressions with `+`, `-`, `*`, `/`, `%`, `^`, and parentheses.
- Concatenate strings with `+` (numbers are coerced to strings when needed).
- Interpolate variables in strings with `$name` or `${name}` syntax.
- Evaluate expressions inside strings with `${...}` interpolation.
- Define functions with local variables and `return` values (including `return;` for `null`).
- Use `null` as an explicit empty value.
- Use braces for block constructs like function bodies.
- Print a variable by typing its name.
- Show an error when a variable does not exist.

Supported examples:

```txt
var a = 5;
var b = 2.5;
var message = "hello world!";
var greeting = "hello" + " world";
var label = "count: " + 5;
var value = 44;
var line = "value is $value";
var line2 = "value is ${value}";
var line3 = "sum is ${value + 6}";
var empty = null;
line3;
empty;

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
