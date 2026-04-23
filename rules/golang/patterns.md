---
paths:
  - "**/*.go"
  - "**/go.mod"
  - "**/go.sum"
last_reviewed: 2026-04-22
version_target: "Best Practices"
---
# Go Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Go-specific content.

## Functional Options

Use functional options for constructors that have several optional settings:

```go
type Option func(*Server)

func WithPort(port int) Option {
    return func(s *Server) { s.port = port }
}

func NewServer(opts ...Option) *Server {
    s := &Server{port: 8080}
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

## Small Interfaces

Define interfaces where they are used, not where they are implemented. Keep them narrow.

## Dependency Injection

Use constructor functions to inject dependencies:

```go
func NewUserService(repo UserRepository, logger Logger) *UserService {
    return &UserService{repo: repo, logger: logger}
}
```

## Explicit Context Flow

Pass `context.Context` explicitly through request and I/O boundaries. Do not hide it in globals or structs without need.

## Error Wrapping

Wrap errors with context using `%w` so callers can inspect root causes with `errors.Is` and `errors.As`.

## References

See skill: `golang-patterns` for broader Go patterns including concurrency, error handling, and package organization.
