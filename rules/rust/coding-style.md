---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Rust Coding Style

## Ownership and Borrowing

- Pass references (`&T` or `&mut T`) unless the function needs to own the value.
- Avoid unnecessary `.clone()` — it is a cost that should be justified.
- Prefer `&str` over `String` for function parameters that only read strings.
- Keep lifetimes as simple as possible; if they become complex, reconsider the design.

```rust
// BAD — unnecessary clone
fn print_name(name: String) { println!("{}", name); }
let s = String::from("Ahmed");
print_name(s.clone()); // clone not needed

// GOOD
fn print_name(name: &str) { println!("{}", name); }
print_name(&s); // borrow, no clone

// BAD — takes ownership unnecessarily
fn get_length(s: String) -> usize { s.len() }

// GOOD
fn get_length(s: &str) -> usize { s.len() }
```

## Error Handling

- Use `?` for error propagation in functions that return `Result`.
- No `.unwrap()` or `.expect()` in library code — only in tests or with a documented reason.
- Use `thiserror` for library error types; `anyhow` for application error handling.
- Distinguish recoverable errors (`Result<T, E>`) from programming bugs (`panic!`).

```rust
// Library error type with thiserror
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
    #[error("not found: {0}")]
    NotFound(String),
}

// Application error handling with anyhow
use anyhow::{Context, Result};

fn load_config(path: &Path) -> Result<Config> {
    let content = fs::read_to_string(path)
        .with_context(|| format!("failed to read config from {}", path.display()))?;
    toml::from_str(&content).context("invalid config format")
}
```

## Unsafe Code

- Every `unsafe` block must have a `// SAFETY:` comment explaining the invariant upheld.
- Minimize the scope of `unsafe` blocks.
- Prefer safe abstractions over raw `unsafe` code where possible.
- `unsafe` in public APIs requires strong justification and review.

```rust
// GOOD — minimal scope, documented invariant
fn get_element(ptr: *const i32, len: usize, idx: usize) -> i32 {
    // SAFETY: caller guarantees ptr points to a valid slice of `len` elements
    // and idx < len
    unsafe { *ptr.add(idx) }
}
```

## API Design

- Implement `Debug` for all public types.
- Implement `Clone` where it makes semantic sense.
- Use the builder pattern for structs with many optional fields.
- Newtype pattern for domain types that wrap primitives (e.g., `UserId(u64)`).
- `Display` for user-facing output; `Debug` for developer diagnostics.

```rust
// Newtype pattern
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct UserId(u64);

impl UserId {
    pub fn new(id: u64) -> Self { Self(id) }
    pub fn value(&self) -> u64 { self.0 }
}

// Builder pattern
#[derive(Default)]
pub struct RequestBuilder {
    url: Option<String>,
    timeout_secs: u64,
    retries: u32,
}

impl RequestBuilder {
    pub fn url(mut self, url: impl Into<String>) -> Self {
        self.url = Some(url.into());
        self
    }
    pub fn timeout(mut self, secs: u64) -> Self { self.timeout_secs = secs; self }
    pub fn build(self) -> Result<Request, BuildError> { /* ... */ }
}
```

## Performance

- Avoid allocating in hot loops — reuse buffers.
- Prefer iterators over manual index loops.
- Profile with `cargo flamegraph` or `perf` before optimizing.
- `Vec::with_capacity` when the size is known in advance.

```rust
// BAD — allocates per iteration
for item in items {
    let s = format!("item: {}", item);
    process(&s);
}

// GOOD — reuse buffer
let mut buf = String::new();
for item in items {
    buf.clear();
    write!(&mut buf, "item: {}", item).unwrap();
    process(&buf);
}

// Vec with known capacity
let mut results = Vec::with_capacity(items.len());
```

## Style

- `cargo fmt` must pass.
- `cargo clippy -- -D warnings` must pass.
- Module structure should mirror the domain, not the type hierarchy.
- Keep modules focused — a module that grows beyond 200-300 lines should be reviewed.

## Tooling

```bash
# Format
cargo fmt

# Lint (all warnings as errors)
cargo clippy -- -D warnings

# Tests
cargo test

# Tests with coverage (requires cargo-tarpaulin)
cargo tarpaulin --out Html

# Security audit
cargo audit

# Profile binary
cargo flamegraph --bin my_app
```

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `.unwrap()` in library code | Return `Result`, use `?` |
| `String` param for read-only use | Use `&str` |
| Unnecessary `.clone()` | Pass reference instead |
| `unsafe` without `// SAFETY:` | Document the invariant |
| Manual index loops | Use iterators |
| Panic for recoverable errors | Return `Result<T, E>` |
