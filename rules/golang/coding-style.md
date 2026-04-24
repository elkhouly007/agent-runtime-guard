---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Go Coding Style

Go-specific coding standards. Go has strong conventions enforced by tooling.

## Formatting

- `gofmt` is non-negotiable. All Go code must be formatted by gofmt before commit.
- `goimports` is preferred over gofmt — it also manages imports.
- `golangci-lint` with the `staticcheck` and `errcheck` linters enabled.

## Naming

- Package names: lowercase single word. `auth`, not `authPackage` or `auth_pkg`.
- Exported identifiers: `PascalCase`. Unexported: `camelCase`.
- Interfaces: often noun ending in `-er` for single-method interfaces: `Reader`, `Writer`, `Stringer`.
- Error variables: `ErrNotFound`, `ErrInvalidInput` (exported); `errTimeout` (unexported).
- Avoid stuttering: `http.HTTPClient` is wrong; `http.Client` is correct.

## Error Handling

- Check every error return. Never assign to `_` without explicit justification in a comment.
- Wrap errors with context: `fmt.Errorf("failed to open config: %w", err)`.
- Return errors to the caller unless you can handle them completely at this level.
- Sentinel errors for expected conditions: `var ErrNotFound = errors.New("not found")`.
- Custom error types for errors that callers need to inspect programmatically.

## Package Design

- Small packages with clear responsibilities. One package per concept.
- Internal packages (`internal/`) for code that should not be imported outside the module.
- Avoid cyclic imports — they indicate a design problem.
- `init()` functions: use sparingly. Side effects in `init()` make packages hard to test.

## Concurrency

- Use channels for communication between goroutines; use mutexes for protecting shared state.
- Every goroutine must have a clear ownership model: who is responsible for it completing and for handling its errors?
- Always propagate `context.Context` for cancellation. Every long-running operation should respect context.
