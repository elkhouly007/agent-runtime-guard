---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Go Testing

Go-specific testing standards.

## Framework

- `testing` package (standard library) for unit tests.
- `testify/assert` and `testify/require` for assertion helpers. `require` stops the test on first failure; `assert` continues.
- `testify/mock` or `gomock` for interface mocking.
- `net/http/httptest` for HTTP handler testing.

## Test Structure

- Test files: `foo_test.go` in the same package as `foo.go`.
- Black-box tests (testing exported API only): use `package foo_test` (package name with `_test` suffix).
- White-box tests (testing internals): use `package foo` (same package).
- Table-driven tests are idiomatic Go. Use a slice of test cases with `name`, `input`, and `expected` fields.

## Table-Driven Tests

```go
tests := []struct {
    name     string
    input    string
    expected string
    wantErr  bool
}{
    {"valid input", "foo", "FOO", false},
    {"empty input", "", "", true},
}
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        // test body
    })
}
```

## What to Test

- Test exported behavior, not implementation details.
- Test error paths. Go error handling is explicit; test every error case.
- Test concurrent code with `-race` flag: `go test -race ./...`
- Benchmark hot paths: `func BenchmarkXxx(b *testing.B) { for i := 0; i < b.N; i++ { ... } }`

## Test Helpers

- Helper functions: call `t.Helper()` as the first line so failures report the caller's line number.
- Use `t.Cleanup()` for teardown instead of deferred calls (works correctly with t.Parallel()).
- `t.Parallel()` for tests that do not share state. Parallel tests find race conditions.
