---
paths:
  - "**/*.rs"
last_reviewed: 2026-04-22
version_target: "Best Practices"
---
# Rust Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Rust-specific content.

## Repository Pattern with Traits

Encapsulate data access behind a trait:

```rust
pub trait OrderRepository: Send + Sync {
    fn find_by_id(&self, id: u64) -> Result<Option<Order>, StorageError>;
    fn find_all(&self) -> Result<Vec<Order>, StorageError>;
    fn save(&self, order: &Order) -> Result<Order, StorageError>;
    fn delete(&self, id: u64) -> Result<(), StorageError>;
}
```

## Service Layer

Business logic belongs in service structs. Inject dependencies via constructors:

```rust
pub struct OrderService {
    repo: Box<dyn OrderRepository>,
    payment: Box<dyn PaymentGateway>,
}

impl OrderService {
    pub fn new(repo: Box<dyn OrderRepository>, payment: Box<dyn PaymentGateway>) -> Self {
        Self { repo, payment }
    }
}
```

## Newtype Pattern for Type Safety

Prevent argument mix-ups with small wrapper types:

```rust
struct UserId(u64);
struct OrderId(u64);
```

## Enum State Machines

Model legal states explicitly and match exhaustively:

```rust
enum ConnectionState {
    Disconnected,
    Connecting { attempt: u32 },
    Connected { session_id: String },
    Failed { reason: String, retries: u32 },
}
```

Avoid `_` wildcards for business-critical enums.

## Builder Pattern

Use builders for structs with several optional parameters.

## Sealed Traits for Extensibility Control

Use a private module to seal traits when external implementations must be prevented.

## API Response Envelope

Keep API response shape consistent:

```rust
#[derive(Debug, serde::Serialize)]
#[serde(tag = "status")]
pub enum ApiResponse<T: serde::Serialize> {
    #[serde(rename = "ok")]
    Ok { data: T },
    #[serde(rename = "error")]
    Error { message: String },
}
```

## References

See skill: `rust-patterns` for broader patterns covering ownership, traits, generics, concurrency, and async.
