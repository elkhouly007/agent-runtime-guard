# Dart Coding Style

Dart-specific coding standards following official Dart style guide.

## Formatting

- `dart format` for automatic formatting. Enforce in CI.
- `dart analyze` for static analysis. Zero warnings before committing.

## Naming

- Classes, enums, typedefs: `UpperCamelCase`.
- Variables, parameters, named parameters, methods: `lowerCamelCase`.
- Constants: `lowerCamelCase` (Dart convention — not UPPER_SNAKE_CASE).
- Library and file names: `snake_case`.
- Private identifiers: `_leadingUnderscore`.

## Type Annotations

- Annotate public API with types. Omit types for local variables when they are obvious.
- Prefer `final` over `var` for variables that are not reassigned.
- Use `late` only when the variable will definitely be initialized before use — with a comment if the initialization is non-obvious.

## Dart Idioms

- Use `??` for null coalescing and `?.` for null-safe access.
- Prefer `const` constructors for objects used as compile-time constants.
- Use `factory` constructors for caching or for constructors that can fail.
- `typedef` for complex function types: `typedef Predicate<T> = bool Function(T item)`.
- Use collection if/for in collection literals for conditionally adding elements.

## Async Patterns

- Use `async/await` over raw `Future` chaining.
- `Stream` for sequences of values over time.
- `StreamController` for creating custom streams — always close it when done.
- `unawaited()` (from `package:flutter/foundation.dart`) to explicitly mark fire-and-forget futures.
