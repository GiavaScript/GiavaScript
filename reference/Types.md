# Type Methods and Properties

Status of built-in methods and properties on GiavaScript runtime types.

## String

| Member | Kind | Status |
| --- | --- | --- |
| `length` | Instance property | Available |
| `at()` | Instance method | Available |
| `charAt()` | Instance method | Available |
| `charCodeAt()` | Instance method | Available |
| `codePointAt()` | Instance method | Available |
| `concat()` | Instance method | Available |
| `endsWith()` | Instance method | Available |
| `fromCharCode()` | Static method | Available |
| `includes()` | Instance method | Available |
| `indexOf()` | Instance method | Available |
| `isWellFormed()` | Instance method | Available |
| `lastIndexOf()` | Instance method | Available |
| `localeCompare()` | Instance method | Available |
| `match()` | Instance method | Available |
| `matchAll()` | Instance method | Available |
| `padEnd()` | Instance method | Available |
| `padStart()` | Instance method | Available |
| `repeat()` | Instance method | Available |
| `replace()` | Instance method | Available |
| `replaceAll()` | Instance method | Available |
| `search()` | Instance method | Available |
| `slice()` | Instance method | Available |
| `split()` | Instance method | Available |
| `startsWith()` | Instance method | Available |
| `substr()` | Instance method | Not available |
| `substring()` | Instance method | Available |
| `toLocaleLowerCase()` | Instance method | Available |
| `toLocaleUpperCase()` | Instance method | Available |
| `toLowerCase()` | Instance method | Available |
| `toString()` | Instance method | Available |
| `toUpperCase()` | Instance method | Available |
| `toWellFormed()` | Instance method | Available |
| `trim()` | Instance method | Available |
| `trimEnd()` | Instance method | Available |
| `trimStart()` | Instance method | Available |
| `valueOf()` | Instance method | Available |

## Number

| Member | Kind | Status |
| --- | --- | --- |
| `toString()` | Instance method | Available |

## Array

| Member | Kind | Status |
| --- | --- | --- |
| `from()` | Static method | Available |
| `fromAsync()` | Static method | Not available |
| `isArray()` | Static method | Available |
| `of()` | Static method | Available |
| `length` | Instance property | Available |
| `at()` | Instance method | Available |
| `concat()` | Instance method | Available |
| `copyWithin()` | Instance method | Available |
| `entries()` | Instance method | Available |
| `every()` | Instance method | Available |
| `fill()` | Instance method | Available |
| `filter()` | Instance method | Available |
| `find()` | Instance method | Available |
| `findIndex()` | Instance method | Available |
| `findLast()` | Instance method | Available |
| `findLastIndex()` | Instance method | Available |
| `flat()` | Instance method | Available |
| `flatMap()` | Instance method | Available |
| `forEach()` | Instance method | Available |
| `includes()` | Instance method | Available |
| `indexOf()` | Instance method | Available |
| `join()` | Instance method | Available |
| `keys()` | Instance method | Available |
| `lastIndexOf()` | Instance method | Available |
| `map()` | Instance method | Available |
| `pop()` | Instance method | Available |
| `push()` | Instance method | Available |
| `reduce()` | Instance method | Available |
| `reduceRight()` | Instance method | Available |
| `reverse()` | Instance method | Available |
| `shift()` | Instance method | Available |
| `slice()` | Instance method | Available |
| `some()` | Instance method | Available |
| `sort()` | Instance method | Available |
| `splice()` | Instance method | Available |
| `toLocaleString()` | Instance method | Not available |
| `toReversed()` | Instance method | Not available |
| `toSorted()` | Instance method | Not available |
| `toSpliced()` | Instance method | Not available |
| `toString()` | Instance method | Available |
| `unshift()` | Instance method | Available |
| `values()` | Instance method | Available |
| `with()` | Instance method | Not available |

### Array callback argument behavior

- In array methods that accept callbacks, JavaScript-compatible argument normalization applies to user-defined function expressions and references to function declarations.
- Extra callback arguments are ignored.
- Missing callback arguments are passed as `undefined`.

## Object

| Member | Kind | Status |
| --- | --- | --- |
| `assign()` | Static method | Available |
| `entries()` | Static method | Available |
| `hasOwn()` | Static method | Available |
| `keys()` | Static method | Available |
| `toString()` | Instance method | Available |
| `values()` | Static method | Available |

## Boolean

| Member | Kind | Status |
| --- | --- | --- |
| `toString()` | Instance method | Available |

## Date

| Member | Kind | Status |
| --- | --- | --- |
| `getTime()` | Instance method | Available |
| `toString()` | Instance method | Available |

### Date notes

- In Node.js, `Date.prototype.toString()` usually prints a locale/timezone representation.
- In GiavaScript, `Date.prototype.toString()` returns a UTC ISO-like string (`YYYY-MM-DDTHH:mm:ss.SSSZ`) by design.

## Error

| Member | Kind | Status |
| --- | --- | --- |
| `Error()` | Constructor | Available |
| `message` | Instance property | Available |
| `name` | Instance property | Available |
| `stack` | Instance property | Available |
| `toString()` | Instance method | Available |
| `TypeError()` | Constructor | Available |
| `ReferenceError()` | Constructor | Available |
| `SyntaxError()` | Constructor | Available |

### Error notes

- `new Error("message")` creates an error object with the given message.
- `name` defaults to `"Error"`. Subtypes use their constructor name.
- `stack` returns a string representation of the call stack.
- `toString()` returns `"name: message"`.
- Error objects can be thrown with `throw` and caught with `try/catch`.
- Raw value throws continue to work alongside Error objects.

## Notes

- This reflects the current behavior in the interpreter and specs.
