# LennaScript

LennaScript is a small interpreted language written in Crystal.

At the current stage, it focuses on variable handling and arithmetic inside a REPL.

## What LennaScript Can Do Right Now

- Declare variables with integer or float values.
- Assign one variable from another variable.
- Evaluate arithmetic expressions with `+`, `-`, `*`, `/`, `%`, `^`, and parentheses.
- Print a variable by typing its name.
- Show an error when a variable does not exist.

Supported examples:

```txt
$a = 5;
$b = 2.5;
$value = 44;
$another_value = $a;
$result = ($a + $value) / $b;
$another_value
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

- No functions, control flow, or complex types yet.

## Development

Run tests:

```bash
crystal spec
```
