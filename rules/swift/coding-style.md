---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Swift Coding Style

Swift-specific coding standards following Swift API Design Guidelines.

## Formatting

- SwiftFormat and SwiftLint for formatting and linting. Enforce in CI.
- Follow the official Swift API Design Guidelines: `https://swift.org/documentation/api-design-guidelines/`

## Naming

- Types and protocols: `UpperCamelCase`.
- Functions, methods, properties, variables: `lowerCamelCase`.
- Acronyms: all caps if at the start or end; mixed case in the middle: `URLSession`, `userURL`, `parseURL`.
- Name for clarity at the call site: `dismiss(animated: true)` not `dismiss(true)`.
- Boolean properties: prefix with `is`, `has`, `can`, `should`.

## Swift Idioms

- `let` over `var` by default. Use `var` only when mutation is required.
- Optionals over sentinel values. `nil` is explicit; `-1` as "no value" is not.
- Guard-early: `guard let user = user else { return }` over deep nesting.
- `defer` for cleanup that must happen regardless of control flow.
- Computed properties for derived values. Avoid redundant stored state.
- Use `struct` for value types, `class` for reference types with identity semantics.
- Protocol-oriented programming: design against protocols, not concrete types.

## Error Handling

- `throw` and `try` for recoverable errors. `fatalError` only for programmer errors that should never happen.
- Typed errors with enums: `enum NetworkError: Error { case timeout, notFound, serverError(Int) }`.
- `Result<T, E>` for async operations where exceptions are not appropriate.
