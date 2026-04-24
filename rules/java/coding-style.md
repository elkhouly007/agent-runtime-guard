---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Java Coding Style

Java-specific coding standards.

## Formatting

- Use Google Java Format or Checkstyle with project-consistent rules.
- Enforce formatting via Spotless plugin in Maven/Gradle.
- 4-space indentation (standard Java convention).

## Naming

- Classes and interfaces: `PascalCase`.
- Methods and variables: `camelCase`.
- Constants: `UPPER_SNAKE_CASE`.
- Packages: lowercase, reverse domain: `com.company.module.feature`.
- Avoid abbreviations. `getUserById` not `getUsrById`.

## Modern Java

- Use `var` for local variables when the type is obvious from context (Java 10+).
- Records for immutable data holders (Java 16+): `record Point(int x, int y) {}`.
- Sealed classes for closed type hierarchies (Java 17+).
- Pattern matching with `instanceof` (Java 16+): `if (obj instanceof String s) { ... }`.
- Switch expressions (Java 14+): `int result = switch (day) { case MONDAY -> 1; ... };`.
- Text blocks for multiline strings (Java 15+).

## Null Handling

- Annotate with `@Nullable` and `@NonNull` (or `@Nonnull`). Use a JSR-305 or JetBrains annotations library.
- Prefer `Optional<T>` for return types that may have no value. Do not use it for method parameters or fields.
- Never return `null` from a public method that could reasonably return an empty collection. Return an empty collection instead.

## Exception Handling

- Checked exceptions for recoverable conditions that callers must handle.
- Unchecked exceptions (RuntimeException subclasses) for programming errors.
- Never swallow exceptions: catch and log at minimum. Include the original exception in the log.
- Do not catch Exception broadly unless at the top-level boundary handler.
