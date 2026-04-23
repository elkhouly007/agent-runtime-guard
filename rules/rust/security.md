---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Rust Security Rules

## OWASP Coverage Map

| OWASP Item | Section Below |
|------------|---------------|
| A01 Broken Access Control | Auth & Authorization |
| A02 Cryptographic Failures | Cryptography |
| A03 Injection | SQL / Command Injection |
| A04 Insecure Design | Memory Safety, unsafe |
| A05 Security Misconfiguration | HTTP Security, TLS |
| A06 Vulnerable Components | Dependencies |
| A07 Auth Failures | Auth & Authorization |
| A08 Software Integrity Failures | Dependencies |
| A09 Logging Failures | Error Handling, Secrets |
| A10 SSRF | Input Validation, HTTP |

---

## Memory Safety

- Rust's ownership model prevents most memory safety bugs at compile time — do not use `unsafe` to bypass it.
- Minimize `unsafe` blocks: use only when interfacing with C FFI or hardware.
- Document every `unsafe` block with a `// SAFETY:` comment explaining the invariant being upheld.
- Never use `unsafe` to avoid borrow checker errors — restructure the code instead.
- Prefer `Box`, `Rc`, `Arc` over raw pointers.

**BAD — undocumented unsafe:**
```rust
unsafe {
    let ptr = some_raw_pointer();
    *ptr = 42;  // no safety invariant documented
}
```

**GOOD — justified and documented unsafe:**
```rust
// SAFETY: `ptr` comes from Box::into_raw and has not been freed yet.
// This is the only place ownership is reclaimed.
unsafe {
    let _ = Box::from_raw(ptr);
}
```

---

## Input Validation

- Validate all inputs at the boundary: HTTP handlers, CLI argument parsers, file readers.
- Use strong types to encode constraints — prefer `NonZeroU32` over `u32` when zero is invalid.
- **Parse, don't validate:** transform unvalidated input into typed values early; reject at the boundary.
- Limit string and collection lengths before allocating.

**BAD — validate-and-continue:**
```rust
fn process(name: &str) {
    if name.is_empty() { return; }
    // name is still &str — constraint not encoded in type
    store_user(name);
}
```

**GOOD — parse into validated type:**
```rust
struct Username(String);

impl Username {
    fn parse(s: &str) -> Result<Self, &'static str> {
        if s.is_empty() || s.len() > 64 { return Err("invalid username"); }
        Ok(Username(s.to_owned()))
    }
}
fn process(raw: &str) -> Result<(), &'static str> {
    let name = Username::parse(raw)?;
    store_user(name);
    Ok(())
}
```

---

## SQL Injection Prevention

**BAD — SQL injection via format!:**
```rust
let query = format!("SELECT * FROM users WHERE name = '{}'", name);
sqlx::query(&query).fetch_one(&pool).await?;
```

**GOOD — parameterized query (sqlx):**
```rust
let user = sqlx::query_as!(User,
    "SELECT * FROM users WHERE name = $1", name
).fetch_one(&pool).await?;
```

**GOOD — diesel ORM:**
```rust
use schema::users::dsl::*;
let results = users
    .filter(username.eq(&name))
    .load::<User>(&mut conn)?;
```

Never build SQL with `format!` or string concatenation.

---

## Path Traversal

**BAD — path traversal:**
```rust
let path = format!("/data/uploads/{}", user_filename);
let contents = std::fs::read(&path)?;  // traversal: "../../etc/passwd"
```

**GOOD — canonicalize and prefix-check:**
```rust
use std::path::{Path, PathBuf};

fn safe_path(base: &Path, user_input: &str) -> Result<PathBuf, &'static str> {
    let requested = base.join(user_input);
    let canonical = requested.canonicalize().map_err(|_| "invalid path")?;
    if !canonical.starts_with(base) {
        return Err("path traversal detected");
    }
    Ok(canonical)
}
```

---

## Command Injection

**BAD — shell injection via std::process:**
```rust
std::process::Command::new("sh")
    .arg("-c")
    .arg(format!("ls {}", user_dir))  // injection via user_dir
    .output()?;
```

**GOOD — pass arguments separately, no shell expansion:**
```rust
std::process::Command::new("ls")
    .arg(&user_dir)   // separate arg — no shell interpolation
    .output()?;
```

---

## Serialization / Deserialization

- Use `serde` with explicit type definitions — never deserialize into `serde_json::Value` for untrusted data unless you validate immediately after.
- Limit deserialized payload sizes to prevent memory exhaustion.
- Use `#[serde(deny_unknown_fields)]` on structs that handle external input.

**BAD — unbounded deserialization:**
```rust
let payload: serde_json::Value = serde_json::from_str(&body)?;
// accepts any JSON of any depth/size
```

**GOOD — typed + bounded:**
```rust
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct CreateUser {
    #[serde(deserialize_with = "bounded_string")]
    username: String,
    email:    String,
}
// enforce max body size in the web framework layer (e.g., axum::extract::DefaultBodyLimit)
```

---

## Cryptography

- Use `ring`, `rustls`, or `argon2` — not custom cryptography.
- Password hashing: use `argon2` or `bcrypt` — never SHA-1 or MD5.
- Random values: use `rand::rngs::OsRng` or `ring::rand::SystemRandom` — not `rand::thread_rng()` for secrets.
- TLS: use `rustls` — minimum TLS 1.2, prefer 1.3.

**BAD — MD5 for passwords:**
```rust
use md5;
let hash = format!("{:x}", md5::compute(password));
```

**GOOD — Argon2 password hashing:**
```rust
use argon2::{Argon2, PasswordHasher, password_hash::SaltString, password_hash::rand_core::OsRng};

let salt = SaltString::generate(&mut OsRng);
let argon2 = Argon2::default();
let hash = argon2.hash_password(password.as_bytes(), &salt)?.to_string();
```

**GOOD — secure random token:**
```rust
use rand::{rngs::OsRng, RngCore};

let mut token = [0u8; 32];
OsRng.fill_bytes(&mut token);
let token_hex = hex::encode(token);
```

---

## Authentication and Authorization

- Use middleware-level auth guards — not manual `if user.is_admin()` checks scattered across handlers.
- Validate JWTs with a trusted library (`jsonwebtoken` crate); verify `exp`, `iss`, `aud`.
- Re-authenticate for sensitive operations (password change, account deletion, payment).

**BAD — JWT without validation:**
```rust
// Decodes without verifying signature
let claims: Claims = serde_json::from_str(&base64::decode(&parts[1])?)?;
```

**GOOD — full JWT verification:**
```rust
use jsonwebtoken::{decode, DecodingKey, Validation, Algorithm};

let token_data = decode::<Claims>(
    &token,
    &DecodingKey::from_secret(secret.as_ref()),
    &Validation::new(Algorithm::HS256),
)?;
// token_data.claims.exp is automatically checked
```

---

## Error Handling

- Never expose internal error details or stack traces to external callers.
- Use `thiserror` for library errors, `anyhow` for application errors.
- Log errors server-side; return generic messages to the client.
- Do not use `.unwrap()` or `.expect()` on inputs from external data — use `?` or proper error handling.

**BAD — leak internal error:**
```rust
let result = db.query(...).unwrap(); // panics on error with full stack trace
```

**GOOD — propagate and sanitize:**
```rust
let result = db.query(...).map_err(|e| {
    tracing::error!("DB error: {e}");
    AppError::Internal  // generic error to client
})?;
```

---

## Secrets

- Load secrets from environment variables at startup — not from config files in the repo.
- Use the `secrecy` crate to wrap secret values so they are not accidentally logged or printed.
- Validate required secrets at startup; fail fast with a clear error if missing.

**GOOD — secrecy crate:**
```rust
use secrecy::{Secret, ExposeSecret};

struct Config {
    db_password: Secret<String>,
}

// Won't print password even accidentally via {:?}
let pwd = config.db_password.expose_secret();
```

---

## HTTP Security (Axum / Actix-web)

- Set security headers: `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Content-Security-Policy`.
- Validate `Content-Type` on all POST/PUT endpoints.
- Rate-limit authentication and sensitive endpoints (`tower-governor` or similar).
- Use HTTPS in production — configure TLS in the server or a reverse proxy.

**GOOD — security headers middleware (tower/axum):**
```rust
use tower_http::set_header::SetResponseHeaderLayer;
use axum::http::{HeaderName, HeaderValue};

let app = Router::new()
    .layer(SetResponseHeaderLayer::overriding(
        HeaderName::from_static("x-content-type-options"),
        HeaderValue::from_static("nosniff"),
    ))
    .layer(SetResponseHeaderLayer::overriding(
        HeaderName::from_static("x-frame-options"),
        HeaderValue::from_static("DENY"),
    ));
```

---

## Dependencies

- Run `cargo audit` in CI to check for known vulnerabilities.
- Use `cargo deny` to enforce license and advisory policies.
- Pin versions in `Cargo.lock` and commit it for applications (not libraries).
- Review changelogs before upgrading security-sensitive crates (`rustls`, `ring`, `tokio`).

**Tooling commands:**
```bash
cargo audit                        # check for known CVEs
cargo deny check advisories        # advisory policy check
cargo clippy -- -D warnings        # lint as errors
cargo test --all-features           # full test suite
cargo +nightly fuzz run <target>   # fuzz a parser
```

---

## Anti-Patterns Table

| Anti-Pattern | Why It's Dangerous | Fix |
|-------------|-------------------|-----|
| `unsafe` without `// SAFETY:` | Reviewer cannot verify invariant | Add safety comment |
| `.unwrap()` on external input | Panics in production | Use `?` or `map_err` |
| `format!()` in SQL | SQL injection | Use query parameters |
| `rand::thread_rng()` for secrets | Predictable in some contexts | Use `OsRng` |
| `serde_json::Value` for untrusted input | No schema enforcement | Use typed structs with `deny_unknown_fields` |
| `system()` with user input | Command injection | Use `Command::new` with separate args |
| MD5/SHA-1 for passwords | Trivially cracked | Use Argon2 or bcrypt |
| Logging raw error details to HTTP response | Information leakage | Log server-side, return generic message |
