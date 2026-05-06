# JSON

Status of the JavaScript `JSON` global object in GiavaScript.

## Static methods

| Method | Status |
| --- | --- |
| `parse()` | Available |
| `stringify()` | Available |

## Notes

- `JSON` is exposed as a global object.
- `JSON.parse(string)` requires exactly one string argument.
- `JSON.parse(string)` returns runtime values (`object`, `array`, `number`, `boolean`, `null`, or `string`).
- `JSON.stringify(value)` requires exactly one argument.
- `JSON.stringify(undefined)` and `JSON.stringify(function)` return `undefined`.
- In objects, `undefined` and function values are omitted.
- In arrays, `undefined` and function values serialize as `null`.
- Non-finite numbers (`NaN`, `Infinity`, `-Infinity`) serialize as `null`.
- Circular arrays and objects raise an error.
