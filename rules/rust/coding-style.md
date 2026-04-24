---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Rust Coding Style

Rust-specific coding standards. Rust has strong tooling-enforced conventions.

## Formatting

- `rustfmt` with default settings. All code formatted before commit.
- `clippy` with `#[warn(clippy::all)]` at minimum. Address all clippy lints — most indicate real issues.
- Use `cargo fmt -- --check` in CI to enforce formatting.

## Naming

- Types, traits, enums: `PascalCase`.
- Functions, methods, variables, modules: `snake_case`.
- Constants and statics: `UPPER_SNAKE_CASE`.
- Type parameters: single uppercase letter (`T`, `E`) or descriptive `PascalCase` for complex bounds.
- Lifetime parameters: short lowercase names: `'a`, `'buf`, `'conn`.

## Ownership Clarity

- Function signatures should make ownership intent explicit: take by value when you need to own it, borrow when you only need to read, mutably borrow when you need to modify.
- Avoid unnecessary clones. A clone is a performance cost and often indicates an ownership design problem.
- Return owned types from constructors and factory functions. Return references from accessors.
- Use `Cow<str>` when a function sometimes borrows and sometimes owns.

## Error Handling

- Return `Result<T, E>` from all fallible operations. Do not use `Option<T>` to signal errors.
- Use `?` for early error propagation. Long chains of `match` on errors are noise.
- Custom error types: implement `std::error::Error` and `Display`. Use `thiserror` for ergonomic derivation.
- `unwrap()` and `expect()` are acceptable in tests and in startup code where failure is unrecoverable.
- In production code paths, prefer error propagation with context over `unwrap()`.

## Module Organization

- Modules map to files or directories. One concept per module.
- `pub use` in `lib.rs` to create a clean public API. Internal structure is an implementation detail.
- `pub(crate)` for items used within the crate but not part of the public API.
