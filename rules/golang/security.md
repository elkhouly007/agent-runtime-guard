# Go Security

Go-specific security rules extending the common security rules.

## Injection Prevention

- Use parameterized queries with `database/sql`. Never construct SQL by string concatenation.
- `exec.Command()` with a list of arguments, never a single shell string.
- `exec.Command("bash", "-c", userInput)` is command injection. Never do this.
- HTML templates: use `html/template`, not `text/template`. `html/template` auto-escapes.

## Cryptography

- Use `crypto/rand` for all cryptographically secure random values. `math/rand` is not cryptographically secure.
- `crypto/tls` for TLS. Minimum TLS version 1.2; prefer 1.3.
- `golang.org/x/crypto` for password hashing (argon2, bcrypt). Never use MD5 or SHA-1 for passwords.
- `crypto/subtle.ConstantTimeCompare()` for secret comparison to prevent timing attacks.

## HTTP Security

- Set timeouts on all `http.Client` and `http.Server` instances. The default is no timeout — a server with no timeout can be held open by slow clients.
- Validate `Content-Type` on incoming requests that parse a body.
- Set secure headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Content-Security-Policy`.
- `net/http`'s `ServeFile` and `StripPrefix` are safe for serving static files. Avoid path manipulation around them.

## Memory Safety in CGO

- CGo safety: Go's memory safety guarantees do not apply inside CGo calls. Treat CGo code with C-level scrutiny.
- Avoid CGo when a pure-Go alternative exists.
- Any memory allocated in C must be freed in C. Go's garbage collector does not track C allocations.

## Sensitive Data

- Use `crypto/memguard` or `os.Clearenv()` patterns for secrets that should not survive longer than needed.
- Avoid logging `http.Request` objects directly — they often contain headers, cookies, and form data.
- Use `log/slog` with structured logging and explicitly log only the fields you intend to log.
