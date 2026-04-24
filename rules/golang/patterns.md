---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Go Design Patterns

Go-specific patterns for idiomatic, maintainable code.

## Interface Design

- Interfaces belong in the package that uses them, not the package that implements them.
- Small interfaces: prefer `io.Reader` (one method) over large interfaces with many methods.
- Accept interfaces, return concrete types. This enables callers to provide any compatible implementation.
- Compose interfaces from smaller ones: `io.ReadWriter` composes `io.Reader` and `io.Writer`.

## Error Wrapping

- Wrap errors at each boundary with context: `fmt.Errorf("operation X failed: %w", err)`.
- Unwrap with `errors.Is()` and `errors.As()`. These work through the full error chain.
- Custom error types for errors that need programmatic inspection:
  ```go
  type ValidationError struct { Field string; Message string }
  func (e *ValidationError) Error() string { return e.Field + ": " + e.Message }
  ```

## Options Pattern

For functions with many optional parameters, the options pattern scales better than boolean flags:

```go
type ServerOption func(*Server)
func WithTimeout(d time.Duration) ServerOption { return func(s *Server) { s.timeout = d } }
func NewServer(addr string, opts ...ServerOption) *Server { ... }
```

## Context Propagation

- First parameter of any function that performs I/O or long-running work should be `context.Context`.
- Never store a context in a struct. Pass it per-call.
- Use `context.WithTimeout` and `context.WithCancel` to propagate deadlines through call chains.
- Check `ctx.Err()` at the start of long-running loops to respect cancellation.

## Concurrency Patterns

- Worker pool: a fixed number of goroutines reading from a shared work channel limits concurrency.
- Pipeline: stages connected by channels. Each stage processes items and sends results downstream.
- fan-out / fan-in: distribute work to multiple goroutines, collect results through a single output channel.
