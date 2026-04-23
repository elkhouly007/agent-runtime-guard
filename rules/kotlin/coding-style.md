---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Kotlin Coding Style

Kotlin-specific coding standards.

## Formatting

- ktlint or Detekt with default settings. Enforce in CI.
- Official Kotlin coding conventions as the baseline: `https://kotlinlang.org/docs/coding-conventions.html`

## Naming

- Classes: `PascalCase`.
- Functions and properties: `camelCase`.
- Constants and top-level vals: `UPPER_SNAKE_CASE` or `camelCase` (choose one project-wide).
- Backing properties: `_propertyName` (underscore prefix).

## Kotlin Idioms

- Prefer `val` over `var`. Use `var` only when mutation is required.
- Use data classes for value objects. `data class User(val id: UserId, val email: Email)`.
- Use sealed classes for closed hierarchies. Exhaustive `when` expressions catch missing cases.
- Use `object` for singletons. Kotlin `object` declarations are thread-safe singletons.
- Extension functions over utility classes. `String.toEmailAddress()` over `EmailUtils.parseEmail(str)`.
- Prefer expression-style functions for single-expression bodies: `fun double(n: Int) = n * 2`.
- Use `apply`, `let`, `run`, `also`, `with` scope functions for their specific purposes:
  - `apply`: configure an object, return the same object
  - `let`: transform a value, null-check pattern
  - `run`: execute a block, return the result
  - `also`: perform a side effect, return the original
  - `with`: call multiple methods on the same object

## Null Safety

- Avoid `!!` (non-null assertion). Each `!!` is a potential `NullPointerException`.
- Use `?.let {}` for null-conditional execution.
- Provide defaults with `?: defaultValue` at the point of use rather than asserting non-null.
- Declare values as non-nullable by default. Nullable types should be the exception, not the rule.
