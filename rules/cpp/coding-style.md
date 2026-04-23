---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# C++ Coding Style

Modern C++ (C++17 and later) coding standards.

## Formatting

- Use clang-format with a project `.clang-format` config. Consistency is more important than personal preference.
- Google Style or LLVM style as base configurations. Choose one and enforce it in CI.

## Naming

- Classes and structs: `PascalCase`.
- Functions and methods: `snake_case` (following STL convention) or `camelCase` (following Google style) — pick one project-wide.
- Member variables: `m_name` or `name_` (trailing underscore). Be consistent.
- Constants: `kConstantName` or `UPPER_SNAKE_CASE`.
- Template parameters: `T`, `U`, or descriptive `TEntity`.

## Resource Management (RAII)

- Every resource must be managed by an RAII wrapper. No naked `new`/`delete` in application code.
- `std::unique_ptr<T>` for exclusive ownership.
- `std::shared_ptr<T>` for shared ownership (use sparingly — prefer unique ownership).
- `std::lock_guard` or `std::unique_lock` for mutex management.
- File handles: wrap in a class with RAII semantics or use `std::fstream`.

## Modern C++ Features

- `auto` for type deduction when the type is obvious from the right-hand side.
- Range-based for loops: `for (const auto& item : container)`.
- Structured bindings: `auto [key, value] = *map.find(k)`.
- `std::optional<T>` for optional values. `std::variant<T, U>` for sum types.
- `constexpr` for compile-time computations.
- `[[nodiscard]]` on functions whose return value should not be ignored.

## Const Correctness

- Mark methods `const` when they do not modify the object.
- `const` parameters for values that should not be modified within the function.
- `const` local variables by default. `const auto result = compute()`.
