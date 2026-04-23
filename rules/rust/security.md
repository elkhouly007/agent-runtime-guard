# Rust Security

Rust-specific security rules. Rust eliminates many classes of memory safety bugs — but not all security issues.

## Unsafe Code

- Every `unsafe` block must have a safety comment directly above it explaining the invariants it upholds.
- Minimize the scope of unsafe blocks. The smallest possible unsafe block is the safest.
- Audit every raw pointer operation: is the pointer aligned, non-null, and pointing to valid memory for the lifetime of the operation?
- `unsafe` code that is sound (does not produce undefined behavior from safe callers) must be verified to be sound, not just believed to be.
- Encapsulate unsafe in a small, well-documented module. The safe wrapper is the public API; the unsafe is the implementation.

## Input Validation

- Validate all external input at the boundary, even though Rust prevents buffer overflows.
- Integer overflow: Rust panics in debug mode but wraps in release mode. Use `checked_add`, `saturating_add`, or `wrapping_add` explicitly.
- UTF-8 validity: `str` is always valid UTF-8. Use `String::from_utf8()` with error handling when parsing bytes.

## Cryptography

- Use `ring` or `rustls` for cryptographic operations. Do not implement crypto yourself.
- `rand::rngs::OsRng` for cryptographically secure random numbers.
- `argon2` or `bcrypt` crates for password hashing.
- Secrets in memory: consider `secrecy::Secret<T>` to prevent accidental logging of sensitive values.

## Deserialization Safety

- `serde_json::from_str()` is safe for JSON. Validate the schema after parsing.
- Avoid deserializing arbitrary Rust types with `serde` from untrusted input — only deserialize into types you control.
- `bincode` deserialization from untrusted data can cause panics on malformed input. Use validation.
