---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Go Testing Rules

## Toolchain

- Use the standard `testing` package — no external test framework required.
- `testify/assert` and `testify/require` for readable assertions.
- `testify/mock` for mocks when needed; prefer interface-based fakes over heavy mocking.
- `httptest` for HTTP handler tests.
- `pgx` + `testcontainers-go` for database integration tests.

## File and Function Naming

```go
// File: order_service_test.go (same package for white-box, _test suffix for black-box)
func TestCreateOrder_ValidInput_ReturnsOrder(t *testing.T) { ... }
func TestCreateOrder_BlankName_ReturnsError(t *testing.T) { ... }
```

## Table-Driven Tests

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"empty string", "", true},
        {"no at sign", "userexample.com", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := validateEmail(tt.input)
            if tt.wantErr {
                require.Error(t, err)
            } else {
                require.NoError(t, err)
            }
        })
    }
}
```

- Table-driven tests are idiomatic Go — use them for any function with multiple input scenarios.
- Use `t.Run` for subtests — they run independently and can be filtered.

## Interface-Based Fakes (Preferred over Mocks)

```go
// Interface definition
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
    Save(ctx context.Context, user *User) error
}

// Fake for tests
type fakeUserRepo struct {
    users map[string]*User
}

func (r *fakeUserRepo) FindByID(_ context.Context, id string) (*User, error) {
    u, ok := r.users[id]
    if !ok {
        return nil, ErrNotFound
    }
    return u, nil
}

func (r *fakeUserRepo) Save(_ context.Context, user *User) error {
    r.users[user.ID] = user
    return nil
}
```

- Define interfaces in the package that uses them — not the package that implements them.
- Hand-written fakes are simpler than generated mocks for most cases.

## HTTP Handler Tests

```go
func TestOrderHandler_Create(t *testing.T) {
    repo := &fakeOrderRepo{}
    handler := NewOrderHandler(repo)

    body := strings.NewReader(`{"product_id":"p1","quantity":2}`)
    req := httptest.NewRequest(http.MethodPost, "/orders", body)
    req.Header.Set("Content-Type", "application/json")
    rec := httptest.NewRecorder()

    handler.ServeHTTP(rec, req)

    require.Equal(t, http.StatusCreated, rec.Code)
}
```

## Parallel Tests

```go
func TestSomething(t *testing.T) {
    t.Parallel()  // mark as safe to run in parallel
    // ...
}
```

- Mark independent tests `t.Parallel()` — speeds up test runs significantly.
- Do not share mutable state between parallel subtests.

## Test Helpers

```go
func mustCreateOrder(t *testing.T, repo OrderRepository, req CreateRequest) *Order {
    t.Helper()  // marks this as a helper — errors point to the caller
    order, err := repo.Create(context.Background(), req)
    require.NoError(t, err)
    return order
}
```

- Use `t.Helper()` in helper functions so test failures show the correct call site.

## What NOT to Test

- Standard library behavior.
- Third-party library internals.
- Unexported functions directly — test them through the exported API.
