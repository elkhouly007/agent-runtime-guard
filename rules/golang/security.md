---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Go Security Rules

## OWASP Coverage

| OWASP Category | Go Risk | Fix |
|---|---|---|
| A03 Injection | `fmt.Sprintf` in SQL or shell commands | Parameterized queries; separate `exec.Command` args |
| A02 Cryptographic Failures | `math/rand`; MD5/SHA-1 passwords | `crypto/rand`; bcrypt/argon2 |
| A01 Broken Access Control | Missing middleware authorization | JWT/session validation on every protected route |
| A05 Misconfiguration | No timeouts on `http.Server`; `TLSConfig` defaults | Set `ReadTimeout`, `WriteTimeout`; enforce TLS 1.2+ |
| A06 Vulnerable Components | Unpinned modules | Pin in `go.mod`; `govulncheck ./...` in CI |
| A07 Auth Failures | Weak session tokens; no rate limiting | `crypto/rand` tokens; rate-limit auth routes |

---

## Input Validation

```go
// BAD — raw string passed into business logic without validation
func createUser(w http.ResponseWriter, r *http.Request) {
    name := r.FormValue("name")  // unvalidated, could be empty or 10MB
    db.Exec("INSERT INTO users (name) VALUES (?)", name)
}

// GOOD — validate at the boundary with a library
import "github.com/go-playground/validator/v10"

type CreateUserRequest struct {
    Name  string `json:"name"  validate:"required,min=1,max=100"`
    Email string `json:"email" validate:"required,email"`
    Role  string `json:"role"  validate:"required,oneof=admin viewer editor"`
}

var validate = validator.New()

func createUser(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        http.Error(w, "invalid JSON", http.StatusBadRequest)
        return
    }
    if err := validate.Struct(req); err != nil {
        http.Error(w, err.Error(), http.StatusUnprocessableEntity)
        return
    }
    // safe to use req now
}
```

- Set `r.Body = http.MaxBytesReader(w, r.Body, 1<<20)` to cap request body at 1 MB.
- Reject unknown JSON fields with `decoder.DisallowUnknownFields()`.

---

## SQL Injection Prevention

```go
// BAD — SQL injection via fmt.Sprintf
query := fmt.Sprintf("SELECT * FROM users WHERE name = '%s'", name)
rows, err := db.Query(query)

// BAD — string concatenation
query := "SELECT * FROM orders WHERE status = '" + status + "'"

// GOOD — parameterized query (database/sql)
rows, err := db.QueryContext(ctx, "SELECT * FROM users WHERE name = $1", name)
if err != nil {
    return fmt.Errorf("query users by name: %w", err)
}
defer rows.Close()

// GOOD — sqlx named params (more readable for multiple params)
type Filter struct{ Status string }
rows, err := sqlx.NamedQueryContext(ctx, db,
    "SELECT * FROM orders WHERE status = :status",
    Filter{Status: status},
)
```

Never use `fmt.Sprintf`, `+`, or `strings.Join` to construct SQL. Use `$1/$2` (PostgreSQL) or `?` (MySQL/SQLite) placeholders.

---

## Command Injection

```go
// BAD — shell=true with user input → arbitrary command execution
cmd := exec.Command("sh", "-c", "convert "+userInput)

// BAD — concatenation into the command string
cmd := exec.Command("bash", "-c", fmt.Sprintf("ffmpeg -i %s out.mp4", filename))

// GOOD — pass arguments as separate strings; no shell involved
filename := filepath.Clean(userInput)
cmd := exec.Command("ffmpeg", "-i", filename, "out.mp4")
cmd.Dir = "/tmp/safe-workdir"  // restrict working directory
output, err := cmd.Output()
```

Never pass `"sh", "-c"` with user-controlled strings. Each argument must be a separate string in `exec.Command`.

---

## Path Traversal

```go
// BAD — ../../etc/passwd bypasses naive prefix check
safePath := "/app/uploads/" + userInput
content, err := os.ReadFile(safePath)

// GOOD — resolve to real path and verify prefix
const baseDir = "/app/uploads"

func safeOpen(userInput string) (*os.File, error) {
    requested := filepath.Join(baseDir, userInput)
    clean := filepath.Clean(requested)
    // filepath.EvalSymlinks resolves symlinks that could escape the base
    real, err := filepath.EvalSymlinks(clean)
    if err != nil {
        return nil, fmt.Errorf("resolving path: %w", err)
    }
    if !strings.HasPrefix(real, baseDir+string(os.PathSeparator)) {
        return nil, errors.New("path traversal attempt detected")
    }
    return os.Open(real)
}
```

---

## Cryptography

```go
// BAD — math/rand is predictable; not cryptographically secure
token := strconv.Itoa(rand.Intn(1000000))

// BAD — MD5 for passwords (broken; trivially crackable)
hash := md5.Sum([]byte(password))

// GOOD — crypto/rand for tokens (256-bit entropy)
import "crypto/rand"
import "encoding/base64"

func generateToken() (string, error) {
    b := make([]byte, 32)
    if _, err := rand.Read(b); err != nil {
        return "", fmt.Errorf("generating random token: %w", err)
    }
    return base64.URLEncoding.EncodeToString(b), nil
}

// GOOD — bcrypt for passwords
import "golang.org/x/crypto/bcrypt"

func hashPassword(password string) (string, error) {
    hashed, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(hashed), err
}

func checkPassword(hashed, password string) bool {
    return bcrypt.CompareHashAndPassword([]byte(hashed), []byte(password)) == nil
}
```

- Use `bcrypt.DefaultCost` (10) or higher — tune so hashing takes ~100ms on your hardware.
- TLS minimum version: 1.2; prefer 1.3.

---

## HTTP Security

```go
// BAD — no timeouts; server hangs under slow-loris attacks
srv := &http.Server{Addr: ":8080", Handler: router}

// GOOD — explicit timeouts on every server
srv := &http.Server{
    Addr:         ":8080",
    Handler:      router,
    ReadTimeout:  5 * time.Second,
    WriteTimeout: 10 * time.Second,
    IdleTimeout:  120 * time.Second,
    TLSConfig: &tls.Config{
        MinVersion: tls.VersionTLS12,
        CipherSuites: []uint16{
            tls.TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,
            tls.TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,
        },
    },
}

// Security headers middleware
func securityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("X-Content-Type-Options", "nosniff")
        w.Header().Set("X-Frame-Options", "DENY")
        w.Header().Set("Content-Security-Policy", "default-src 'self'")
        w.Header().Set("Strict-Transport-Security", "max-age=63072000; includeSubDomains")
        next.ServeHTTP(w, r)
    })
}

// Rate limiting on auth endpoints (golang.org/x/time/rate)
var authLimiter = rate.NewLimiter(rate.Every(time.Second), 5)  // 5 req/s

func loginHandler(w http.ResponseWriter, r *http.Request) {
    if !authLimiter.Allow() {
        http.Error(w, "too many requests", http.StatusTooManyRequests)
        return
    }
    // handle login
}
```

---

## Secrets Management

```go
// BAD — hardcoded secret in source
const dbPassword = "super-secret-password"

// BAD — secret in a config file committed to the repo
// config.yaml: db_password: super-secret-password

// GOOD — load from environment at startup; fail fast if missing
func mustGetenv(key string) string {
    val := os.Getenv(key)
    if val == "" {
        log.Fatalf("required environment variable %q is not set", key)
    }
    return val
}

func main() {
    cfg := Config{
        DBPassword: mustGetenv("DB_PASSWORD"),
        JWTSecret:  mustGetenv("JWT_SECRET"),
        APIKey:     mustGetenv("EXTERNAL_API_KEY"),
    }
    // ...
}

// Never log secret values
log.Printf("connecting to DB as user %s", cfg.DBUser)  // OK
// log.Printf("password: %s", cfg.DBPassword)          // NEVER
```

---

## Dependency Scanning

```bash
# govulncheck — official Go vulnerability scanner (checks transitive deps too)
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# List all direct and transitive dependencies
go list -m all

# Check for available updates
go list -m -u all

# Verify module checksums (detects tampering)
go mod verify

# Tidy to remove unused deps that increase attack surface
go mod tidy
```

Run `govulncheck ./...` in CI on every PR. Fail on any HIGH or CRITICAL finding.

---

## Anti-Patterns

| Anti-pattern | Risk | Fix |
|---|---|---|
| `fmt.Sprintf` in SQL query | SQL injection | `db.QueryContext` with `$1` parameters |
| `exec.Command("sh", "-c", input)` | Command injection | Separate args in `exec.Command`; no shell |
| `math/rand` for secrets/tokens | Predictable tokens; session hijacking | `crypto/rand` + base64 URL encoding |
| MD5/SHA-1 for passwords | Rainbow table cracking in minutes | bcrypt with `DefaultCost` ≥ 10 |
| `http.Server{}` without timeouts | Slow-loris DoS; connection leak | `ReadTimeout`, `WriteTimeout`, `IdleTimeout` |
| Hardcoded secrets in source | Credentials in version control | `os.Getenv` + fail-fast at startup |
| Path join without `EvalSymlinks` | Symlink-based path traversal | Resolve symlinks; verify `HasPrefix(real, base)` |
| No `MaxBytesReader` on body | Memory exhaustion (multi-GB body) | `http.MaxBytesReader(w, r.Body, 1<<20)` |
| Logging secret values | Secrets in log aggregation / SIEM | Log only non-sensitive identifiers |
| Unpinned `go.sum` | Supply-chain substitution attack | Commit `go.sum`; run `go mod verify` in CI |
