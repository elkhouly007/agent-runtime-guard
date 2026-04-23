---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Go Coding Style

## Error Handling

- Check every error — do not use `_` for error returns except in truly trivial cases.
- Wrap errors with context: `fmt.Errorf("operation X: %w", err)`.
- Use sentinel errors for known conditions; custom types for rich error context.
- Do not both log and return the same error — choose one.
- Prefer returning errors over panicking, except for truly unrecoverable situations.

```go
// BAD — discarded error
data, _ := json.Marshal(payload)

// GOOD
data, err := json.Marshal(payload)
if err != nil {
    return fmt.Errorf("marshal payload: %w", err)
}

// Custom error type for rich context
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %s", e.Field, e.Message)
}

// Sentinel error
var ErrNotFound = errors.New("not found")

// Check with errors.Is
if errors.Is(err, ErrNotFound) {
    // handle not found
}
```

## Code Organization

- Follow the standard Go project layout (`cmd/`, `internal/`, `pkg/`).
- Package names are lowercase, short, and descriptive (no underscores).
- Exported identifiers have doc comments.
- `internal/` for packages not intended to be imported externally.

```
myapp/
  cmd/
    server/
      main.go
  internal/
    auth/
    storage/
  pkg/
    validator/
```

## Functions

- `context.Context` is the first parameter of every function that does I/O.
- Return early on error — avoid deeply nested error handling.
- Accept interfaces, return concrete types (for library code).

```go
// BAD — no context, nested errors
func GetUser(id string) (*User, error) {
    row, err := db.QueryRow(...)
    if err == nil {
        user, err := scanUser(row)
        if err == nil {
            return user, nil
        }
        return nil, err
    }
    return nil, err
}

// GOOD — context first, early returns
func GetUser(ctx context.Context, id string) (*User, error) {
    row, err := db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = $1", id)
    if err != nil {
        return nil, fmt.Errorf("query user %s: %w", id, err)
    }
    user, err := scanUser(row)
    if err != nil {
        return nil, fmt.Errorf("scan user %s: %w", id, err)
    }
    return user, nil
}
```

## Naming

- Short names for local variables with small scope (`i`, `n`, `err`).
- Longer, descriptive names for package-level identifiers.
- Acronyms are all caps: `URL`, `HTTP`, `ID` — not `Url`, `Http`, `Id`.
- Getters are `Name()`, not `GetName()`.

```go
// BAD
func GetUserID() string { ... }
type HttpClient struct { ... }

// GOOD
func UserID() string { ... }
type HTTPClient struct { ... }
```

## Concurrency

- Prefer channels over shared memory; prefer mutexes for protecting simple state.
- Always handle goroutine lifecycle — ensure goroutines can be stopped.
- Use `sync.WaitGroup` to wait for goroutine completion.
- Never start a goroutine without knowing how it will stop.

```go
// Worker pool pattern
func processItems(ctx context.Context, items []Item) error {
    var wg sync.WaitGroup
    errCh := make(chan error, len(items))

    for _, item := range items {
        wg.Add(1)
        go func(it Item) {
            defer wg.Done()
            if err := process(ctx, it); err != nil {
                errCh <- err
            }
        }(item)
    }

    wg.Wait()
    close(errCh)

    if err := <-errCh; err != nil {
        return err
    }
    return nil
}
```

## Style

- Run `gofmt` or `goimports` — all code must be formatted.
- Use `golangci-lint` with a project config.
- Keep functions focused — if a function needs a comment to explain its sections, split it.
- Avoid `init()` — it makes testing harder.

## Imports

- Group: standard library, external packages, internal packages (separated by blank lines).
- Use `goimports` to manage imports automatically.

```go
import (
    "context"
    "fmt"

    "github.com/pkg/errors"
    "go.uber.org/zap"

    "myapp/internal/auth"
)
```

## Testing

- Files end in `_test.go`, functions start with `Test`.
- Use table-driven tests for multiple input/output cases.
- `go test -race` must pass — run with the race detector in CI.
- Use `testify` or standard `testing` assertions — be consistent within a project.

```go
func TestCalculateTotal(t *testing.T) {
    tests := []struct {
        name     string
        items    []Item
        expected float64
    }{
        {"empty cart", []Item{}, 0},
        {"single item", []Item{{Price: 10, Qty: 2}}, 20},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := CalculateTotal(tt.items)
            assert.Equal(t, tt.expected, got)
        })
    }
}
```

## Tooling

```bash
# Format
gofmt -w ./...
goimports -w ./...

# Lint
golangci-lint run

# Tests with race detector
go test -race ./...

# Coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Vulnerability check
govulncheck ./...
```
