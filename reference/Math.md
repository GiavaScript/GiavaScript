# Math

Status of the JavaScript `Math` global object in GiavaScript.

| Member | Kind | Status |
| --- | --- | --- |
| `E` | Static property | Available |
| `LN10` | Static property | Available |
| `LN2` | Static property | Available |
| `LOG10E` | Static property | Available |
| `LOG2E` | Static property | Available |
| `PI` | Static property | Available |
| `SQRT1_2` | Static property | Available |
| `SQRT2` | Static property | Available |
| `abs()` | Static method | Available |
| `sqrt()` | Static method | Available |
| `acos()` | Static method | Available |
| `acosh()` | Static method | Available |
| `asin()` | Static method | Available |
| `asinh()` | Static method | Available |
| `atan()` | Static method | Available |
| `atan2()` | Static method | Available |
| `atanh()` | Static method | Available |
| `cbrt()` | Static method | Available |
| `ceil()` | Static method | Available |
| `clz32()` | Static method | Available |
| `cos()` | Static method | Available |
| `cosh()` | Static method | Available |
| `exp()` | Static method | Available |
| `expm1()` | Static method | Available |
| `f16round()` | Static method | Available |
| `floor()` | Static method | Available |
| `fround()` | Static method | Available |
| `hypot()` | Static method | Available |
| `imul()` | Static method | Available |
| `log()` | Static method | Available |
| `log10()` | Static method | Available |
| `log1p()` | Static method | Available |
| `log2()` | Static method | Available |
| `max()` | Static method | Available |
| `min()` | Static method | Available |
| `pow()` | Static method | Available |
| `random()` | Static method | Available |
| `round()` | Static method | Available |
| `sign()` | Static method | Available |
| `sin()` | Static method | Available |
| `sinh()` | Static method | Available |
| `sumPrecise()` | Static method | Available |
| `tan()` | Static method | Available |
| `tanh()` | Static method | Available |
| `trunc()` | Static method | Available |

## Notes

- `Math.random()` returns a pseudo-random number in the range `[0, 1)`.
- `Math.random()` is not cryptographically secure.
- `Math.max()` with zero arguments returns `-Infinity`. `Math.min()` with zero arguments returns `Infinity`.
- All Math methods that accept numeric arguments coerce non-numeric values to numbers. Invalid coercions produce `NaN` or `Infinity` as appropriate.
