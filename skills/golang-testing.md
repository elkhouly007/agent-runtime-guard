# Skill: Go Testing

## Trigger

Use when:
- Writing unit or integration tests in Go
- Structuring table-driven tests or subtests
- Testing HTTP handlers, database code, or concurrent logic
- Adding benchmarks or fuzz targets
- Configuring coverage reporting in CI

## Process

### 1. t.Run() subtests and table-driven tests

```go
package order_test

import (
    "testing"

    "github.com/example/app/order"
)

func TestCart_Total(t *testing.T) {
    t.Parallel() // safe to parallelize at the top level

    tests := []struct {
        name     string
        items    []order.Item
        discount float64
        want     float64
    }{
        {
            name:  "empty cart returns zero",
            items: nil,
            want:  0,
        },
        {
            name:     "single item no discount",
            items:    []order.Item{{Price: 10.0, Qty: 2}},
            want:     20.0,
        },
        {
            name:     "discount applied correctly",
            items:    []order.Item{{Price: 100.0, Qty: 1}},
            discount: 0.1,
            want:     90.0,
        },
    }

    for _, tc := range tests {
        tc := tc // capture range var (required pre-Go 1.22)
        t.Run(tc.name, func(t *testing.T) {
            t.Parallel()
            cart := order.NewCart(tc.items, tc.discount)
            got := cart.Total()
            if got != tc.want {
                t.Errorf("Total() = %v, want %v", got, tc.want)
            }
        })
    }
}
```

### 2. testify/assert vs stdlib

Use `testify/assert` for readable assertions; fall back to stdlib for zero-dependency packages.

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestCreateUser(t *testing.T) {
    user, err := CreateUser("alice@example.com")

    // require stops the test immediately on failure (like t.Fatal)
    require.NoError(t, err)
    require.NotNil(t, user)

    // assert continues after failure (like t.Error)
    assert.Equal(t, "alice@example.com", user.Email)
    assert.NotEmpty(t, user.ID)
    assert.WithinDuration(t, time.Now(), user.CreatedAt, time.Second)
}

// stdlib equivalent — no dependency
func TestCreateUser_Stdlib(t *testing.T) {
    user, err := CreateUser("alice@example.com")
    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if user.Email != "alice@example.com" {
        t.Errorf("Email = %q, want %q", user.Email, "alice@example.com")
    }
}
```

### 3. httptest for HTTP handlers

```go
import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "strings"
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestOrderHandler_POST(t *testing.T) {
    t.Parallel()

    handler := NewOrderHandler(newFakeOrderService())

    body := `{"item":"widget","qty":3}`
    req := httptest.NewRequest(http.MethodPost, "/orders", strings.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()

    handler.ServeHTTP(w, req)

    res := w.Result()
    require.Equal(t, http.StatusCreated, res.StatusCode)

    var got OrderResponse
    require.NoError(t, json.NewDecoder(res.Body).Decode(&got))
    assert.NotEmpty(t, got.ID)
    assert.Equal(t, "widget", got.Item)
}

// Test full router (mux)
func TestRouter_NotFound(t *testing.T) {
    router := NewRouter()
    srv := httptest.NewServer(router)
    defer srv.Close()

    resp, err := http.Get(srv.URL + "/nonexistent")
    require.NoError(t, err)
    assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}
```

### 4. sqlmock for DB tests

```go
import (
    "testing"

    "github.com/DATA-DOG/go-sqlmock"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestUserRepository_Get(t *testing.T) {
    db, mock, err := sqlmock.New()
    require.NoError(t, err)
    defer db.Close()

    rows := sqlmock.NewRows([]string{"id", "email", "created_at"}).
        AddRow("user-1", "alice@example.com", time.Now())

    mock.ExpectQuery(`SELECT id, email, created_at FROM users WHERE id = \$1`).
        WithArgs("user-1").
        WillReturnRows(rows)

    repo := NewUserRepository(db)
    user, err := repo.Get(context.Background(), "user-1")

    require.NoError(t, err)
    assert.Equal(t, "alice@example.com", user.Email)
    require.NoError(t, mock.ExpectationsWereMet())
}

func TestUserRepository_Get_NotFound(t *testing.T) {
    db, mock, err := sqlmock.New()
    require.NoError(t, err)
    defer db.Close()

    mock.ExpectQuery(`SELECT .+ FROM users WHERE id = \$1`).
        WithArgs("missing").
        WillReturnRows(sqlmock.NewRows([]string{"id", "email", "created_at"}))

    repo := NewUserRepository(db)
    _, err = repo.Get(context.Background(), "missing")

    assert.ErrorIs(t, err, ErrNotFound)
}
```

### 5. goleak for goroutine leaks

```go
import (
    "testing"
    "go.uber.org/goleak"
)

// In package_test.go — catches leaks across all tests in the package
func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}

// Per-test leak detection
func TestWorkerPool(t *testing.T) {
    defer goleak.VerifyNone(t)

    pool := NewWorkerPool(4)
    pool.Start()
    pool.Submit(func() {})
    pool.Stop() // must drain workers before test ends
}
```

### 6. Benchmarks

```go
func BenchmarkCart_Total(b *testing.B) {
    items := make([]Item, 100)
    for i := range items {
        items[i] = Item{Price: float64(i), Qty: 1}
    }
    cart := NewCart(items, 0)

    b.ResetTimer() // exclude setup from measurement
    for i := 0; i < b.N; i++ {
        _ = cart.Total()
    }
}

// Sub-benchmarks
func BenchmarkJSON(b *testing.B) {
    payload := []byte(`{"id":"1","name":"widget"}`)
    b.Run("Unmarshal", func(b *testing.B) {
        for i := 0; i < b.N; i++ {
            var m map[string]any
            _ = json.Unmarshal(payload, &m)
        }
    })
    b.Run("Decoder", func(b *testing.B) {
        for i := 0; i < b.N; i++ {
            var m map[string]any
            _ = json.NewDecoder(bytes.NewReader(payload)).Decode(&m)
        }
    })
}
```

```bash
# Run benchmarks
go test -bench=. -benchmem -benchtime=3s ./...

# Memory profiling
go test -bench=BenchmarkCart_Total -memprofile=mem.out ./...
go tool pprof mem.out
```

### 7. Fuzz testing (Go 1.18+)

```go
// File: fuzz_test.go
func FuzzParseOrder(f *testing.F) {
    // Seed corpus
    f.Add(`{"id":"1","qty":1}`)
    f.Add(`{}`)
    f.Add(`{"id":"","qty":-1}`)

    f.Fuzz(func(t *testing.T, data string) {
        // Must not panic — all errors must be returned, not panic
        order, err := ParseOrder([]byte(data))
        if err != nil {
            return // invalid input is expected
        }
        // Invariants that must always hold
        if order.ID == "" {
            t.Error("parsed order has empty ID")
        }
    })
}
```

```bash
# Run fuzzer for 60 seconds
go test -fuzz=FuzzParseOrder -fuzztime=60s ./...

# Run found corpus only (regression)
go test -run=FuzzParseOrder ./...
```

### 8. Coverage commands

```bash
# Run with coverage
go test ./... -cover

# Generate coverage profile
go test ./... -coverprofile=coverage.out -covermode=atomic

# View in terminal
go tool cover -func=coverage.out

# Open HTML report
go tool cover -html=coverage.out -o coverage.html

# Fail if below threshold (CI)
go test ./... -coverprofile=coverage.out && \
  go tool cover -func=coverage.out | awk '/^total:/ { if ($3+0 < 80) { print "Coverage below 80%"; exit 1 } }'
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| No `t.Parallel()` in independent tests | Slow test suite | Add `t.Parallel()` at top of each independent test |
| Missing `tc := tc` in range (pre-Go 1.22) | All subtests use last value | Capture `tc := tc` before `t.Run` |
| Global DB connection in tests | State bleeds between tests | Use per-test DB or transaction rollback pattern |
| `time.Sleep` in tests | Flaky | Use channels or `require.Eventually` |
| Asserting `err != nil` without message | Cryptic failure output | `require.NoError(t, err, "creating user")` |
| No cleanup with `t.Cleanup` | Resource leak | `t.Cleanup(func() { resource.Close() })` |

## Safe Behavior

- All table-driven tests use `t.Run()` with descriptive names.
- Benchmarks call `b.ResetTimer()` after setup.
- Fuzz targets never panic on any input — return errors instead.
- `goleak.VerifyTestMain` is wired into every package with goroutines.
- Coverage gate is enforced in CI; threshold is documented in `Makefile`.
- `mock.ExpectationsWereMet()` is always asserted after sqlmock tests.
