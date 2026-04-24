---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Rust Design Patterns

Rust-specific patterns for safe, expressive, high-performance code.

## The Builder Pattern

For structs with many optional fields, the builder pattern provides a type-safe construction API that is checked at compile time:

```rust
let config = ServerConfig::builder()
    .bind_addr("0.0.0.0:8080")
    .max_connections(1000)
    .timeout(Duration::from_secs(30))
    .build()?;
```

## Newtype Pattern

Wrap primitives in newtypes to prevent type confusion:

```rust
struct UserId(u64);
struct OrderId(u64);
// UserId and OrderId are now distinct types — passing one where the other is needed is a compile error
```

## State Machine Types

Encode state transitions in the type system to prevent invalid state:

```rust
struct Connection<S: ConnectionState> { inner: TcpStream, state: PhantomData<S> }
impl Connection<Disconnected> {
    fn connect(self) -> Result<Connection<Connected>, Error> { ... }
}
impl Connection<Connected> {
    fn send(&mut self, data: &[u8]) -> Result<(), Error> { ... }
}
```

## Iterator Adaptors

Build data transformation pipelines with iterators:

```rust
let result: Vec<_> = data.iter()
    .filter(|item| item.is_valid())
    .map(|item| item.transform())
    .take(100)
    .collect();
```

## Error Conversion

Use the `From` trait for ergonomic error conversion:

```rust
#[derive(thiserror::Error, Debug)]
enum AppError {
    #[error("database error: {0}")]
    Database(#[from] sqlx::Error),
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
}
```

The `?` operator automatically calls `From::from()` when the error types have a conversion defined.
