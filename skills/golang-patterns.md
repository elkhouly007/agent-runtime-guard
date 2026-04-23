# Skill: Go Patterns

## Trigger

Use when:
- Designing Go packages or interfaces
- Handling errors, context propagation, or concurrency
- Reviewing Go code for idiomatic style
- Preventing goroutine leaks or resource mismanagement
- Choosing between embedding, composition, or interface design

## Process

### 1. Interface design — small and composable

Go interfaces describe behavior, not identity. Keep them small.

```go
// Bad — too broad, hard to mock, violates interface segregation
type Storage interface {
    Get(id string) ([]byte, error)
    Put(id string, data []byte) error
    Delete(id string) error
    List(prefix string) ([]string, error)
    Stats() StorageStats
    Close() error
}

// Good — split by use case; compose where needed
type Getter interface {
    Get(ctx context.Context, id string) ([]byte, error)
}

type Putter interface {
    Put(ctx context.Context, id string, data []byte) error
}

type ReadWriter interface {
    Getter
    Putter
}

// io.Reader, io.Writer, io.Closer are the gold standard
// Accept interfaces, return concrete types
func Process(r io.Reader) (*Result, error) { /* ... */ }
```

### 2. Error wrapping with fmt.Errorf and %w

```go
import (
    "errors"
    "fmt"
)

// Wrap to add context — caller can still unwrap
func loadConfig(path string) (*Config, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("loadConfig: reading %q: %w", path, err)
    }
    // ...
}

// Sentinel errors for expected conditions
var ErrNotFound = errors.New("not found")

func FindUser(id string) (*User, error) {
    u, ok := store[id]
    if !ok {
        return nil, fmt.Errorf("FindUser %q: %w", id, ErrNotFound)
    }
    return u, nil
}

// Caller unwraps
err := FindUser("x")
if errors.Is(err, ErrNotFound) {
    // handle not-found specifically
}

// Custom error types for rich context
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error: field %q: %s", e.Field, e.Message)
}

var ve *ValidationError
if errors.As(err, &ve) {
    log.Printf("invalid field: %s", ve.Field)
}
```

### 3. Context propagation

Always propagate `context.Context` as the first parameter. Never store it in a struct.

```go
// Correct — context first, always
func FetchOrder(ctx context.Context, id string) (*Order, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet,
        "/orders/"+id, nil)
    if err != nil {
        return nil, fmt.Errorf("FetchOrder: %w", err)
    }
    resp, err := http.DefaultClient.Do(req)
    // ...
}

// Timeouts and cancellation
func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel() // always defer cancel — even if ctx expires, frees resources

    order, err := FetchOrder(ctx, "order-123")
    if err != nil {
        if errors.Is(err, context.DeadlineExceeded) {
            log.Println("timed out")
        }
    }
}

// Context values — only for request-scoped metadata (trace ID, user ID)
type contextKey string

const traceIDKey contextKey = "traceID"

func WithTraceID(ctx context.Context, id string) context.Context {
    return context.WithValue(ctx, traceIDKey, id)
}

func TraceIDFromContext(ctx context.Context) (string, bool) {
    id, ok := ctx.Value(traceIDKey).(string)
    return id, ok
}
```

### 4. sync.WaitGroup and channels

```go
import "sync"

// WaitGroup — wait for a fixed set of goroutines
func processAll(items []Item) error {
    var wg sync.WaitGroup
    errs := make(chan error, len(items)) // buffered to avoid goroutine leak

    for _, item := range items {
        wg.Add(1)
        go func(it Item) {
            defer wg.Done()
            if err := process(it); err != nil {
                errs <- err
            }
        }(item) // capture loop variable — or use range variable in Go 1.22+
    }

    wg.Wait()
    close(errs)

    for err := range errs {
        return err // return first error
    }
    return nil
}

// Channel patterns
func generate(ctx context.Context, values []int) <-chan int {
    out := make(chan int)
    go func() {
        defer close(out) // always close the sender side
        for _, v := range values {
            select {
            case out <- v:
            case <-ctx.Done():
                return // exit on cancellation
            }
        }
    }()
    return out
}
```

### 5. Struct embedding

```go
// Embed for promotion — not for inheritance simulation
type Logger struct {
    level string
}

func (l *Logger) Log(msg string) {
    fmt.Printf("[%s] %s\n", l.level, msg)
}

type Service struct {
    Logger // promoted — service.Log() works directly
    db *sql.DB
}

// Embed interfaces to satisfy larger interfaces cheaply
type ReadOnlyStore struct {
    Getter // only implement what you need; others panic automatically
}
```

### 6. Functional options pattern

```go
// Avoid long constructors with boolean flags or N optional parameters
type Server struct {
    addr    string
    timeout time.Duration
    tls     bool
    maxConn int
}

type Option func(*Server)

func WithTimeout(d time.Duration) Option {
    return func(s *Server) { s.timeout = d }
}

func WithTLS() Option {
    return func(s *Server) { s.tls = true }
}

func WithMaxConnections(n int) Option {
    return func(s *Server) { s.maxConn = n }
}

func NewServer(addr string, opts ...Option) *Server {
    s := &Server{
        addr:    addr,
        timeout: 30 * time.Second, // sensible defaults
        maxConn: 100,
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage is clean and self-documenting
srv := NewServer(":8080",
    WithTimeout(10*time.Second),
    WithTLS(),
    WithMaxConnections(500),
)
```

### 7. defer for cleanup

```go
// Always pair resource acquisition with defer
func readFile(path string) ([]byte, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer f.Close() // runs even if Read panics

    return io.ReadAll(f)
}

// defer with named returns for error wrapping
func openDB(dsn string) (db *sql.DB, err error) {
    db, err = sql.Open("postgres", dsn)
    if err != nil {
        return nil, fmt.Errorf("openDB: %w", err)
    }
    defer func() {
        if err != nil {
            db.Close()
            db = nil
        }
    }()

    if err = db.Ping(); err != nil {
        return nil, fmt.Errorf("openDB: ping: %w", err)
    }
    return db, nil
}
```

### 8. Goroutine leak prevention

```go
// Every goroutine must have an exit path
func startWorker(ctx context.Context, jobs <-chan Job) {
    go func() {
        for {
            select {
            case job, ok := <-jobs:
                if !ok {
                    return // channel closed — clean exit
                }
                handle(job)
            case <-ctx.Done():
                return // cancellation — clean exit
            }
        }
    }()
}

// Use goleak in tests to catch leaks
// import "go.uber.org/goleak"
// func TestMain(m *testing.M) {
//     goleak.VerifyTestMain(m)
// }
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `init()` with side effects | Implicit, untestable, order-dependent | Move to explicit `Setup()` or constructor |
| Storing `context.Context` in struct | Context is request-scoped, not object-scoped | Pass as parameter |
| Returning `interface{}` or `any` | Loses type safety | Return concrete types |
| Ignoring errors with `_` | Silent failures | Handle or explicitly log every error |
| Unbuffered channel with no receiver | Goroutine leak | Use buffered channel or select with done |
| `go func()` without WaitGroup or done signal | Leaks if main exits | Track all goroutines |
| Copying `sync.Mutex` | Breaks locking invariants | Always use pointer to mutex |

## Safe Behavior

- All exported functions that do I/O accept `context.Context` as first parameter.
- All errors are wrapped with `fmt.Errorf("%w")` and never swallowed silently.
- Every goroutine has a documented exit condition.
- `defer cancel()` always follows `context.WithCancel/WithTimeout`.
- `init()` functions are banned from production packages — use constructors.
- Interface definitions live in the consumer package, not the producer package.
