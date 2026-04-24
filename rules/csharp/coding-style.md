---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# C# Coding Style

C#-specific coding standards. Follow Microsoft's coding conventions.

## Formatting

- Use the `.editorconfig` and Roslyn analyzers. `dotnet format` enforces formatting in CI.
- StyleCop or Roslyn analyzers (`Microsoft.CodeAnalysis.NetAnalyzers`) for additional rules.

## Naming

- Classes, methods, properties: `PascalCase`.
- Local variables, parameters: `camelCase`.
- Private fields: `_camelCase` (underscore prefix).
- Interfaces: `IPascalCase`.
- Constants: `PascalCase` (not UPPER_SNAKE_CASE — follow C# convention).
- Async methods: suffix with `Async`. `GetUserAsync()`, not `GetUser()`.

## Modern C# Features

- Use `var` for local variables when the type is clear from the right-hand side.
- Null-conditional operators: `user?.Address?.City` over explicit null checks.
- Null-coalescing: `name ?? "Unknown"`.
- String interpolation: `$"Hello, {name}"` over `string.Format`.
- Records for immutable data: `public record User(Guid Id, string Email);`.
- Pattern matching: `if (obj is User { Role: "admin" } user) { ... }`.
- Top-level statements and minimal API for new ASP.NET projects.

## Async/Await

- Methods that perform I/O should be async. Async all the way down.
- Suffix async methods with `Async`.
- Never `Task.Wait()` or `.Result` in ASP.NET code — causes deadlocks.
- `ConfigureAwait(false)` in library code that does not need to resume on the original context.
- `CancellationToken` as the last parameter of every async method that performs I/O.
