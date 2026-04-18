# LennaScript

LennaScript is a small interpreted language written in Crystal.

At the current stage, it focuses on variable handling and arithmetic inside a REPL.

## What LennaScript Can Do Right Now

- Declare variables with integer, float, or string values.
- Assign one variable from another variable.
- Evaluate arithmetic expressions with `+`, `-`, `*`, `/`, `%`, `^`, and parentheses.
- Concatenate strings with `+` (numbers are coerced to strings when needed).
- Interpolate variables in strings with `$name` or `${name}` syntax.
- Evaluate expressions inside strings with `${...}` interpolation.
- Define functions with local variables and `return` values (including `return;` for void).
- End non-function statements with semicolons (`;`).
- Print a variable by typing its name.
- Show an error when a variable does not exist.

Supported examples:

```txt
$a = 5;
$b = 2.5;
$message = "hello world!";
$greeting = "hello" + " world";
$label = "count: " + 5;
$value = 44;
$line = "value is $value";
$line2 = "value is ${value}";
$line3 = "sum is ${$value + 6}";

fun sum_numbers($a, $b)
  return $a + $b + $value;
end

$total = sum_numbers(1, 2);
$another_value = $a;
$result = ($a + $value) / $b;
$message;
$another_value;
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
