---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Rust Testing Rules

## Toolchain

- Built-in `#[test]` attribute — no external framework needed for unit tests.
- `tokio::test` for async tests.
- `rstest` for parameterized tests and fixtures.
- `mockall` for trait mocking when needed; prefer concrete fakes first.
- `assert_matches!` and `pretty_assertions` for clearer assertion output.

## Unit Tests — In Module

```rust
// Place unit tests in the same file as the code under test
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_order_with_valid_input_returns_order() {
        let order = Order::new("product-1", 2).unwrap();
        assert_eq!(order.product_id(), "product-1");
        assert_eq!(order.quantity(), 2);
    }

    #[test]
    fn create_order_with_zero_quantity_returns_error() {
        let result = Order::new("product-1", 0);
        assert!(result.is_err());
    }
}
```

- `#[cfg(test)]` ensures test code is excluded from release builds.
- `use super::*` imports the parent module — gives access to private items.

## Integration Tests — `tests/` Directory

```rust
// tests/order_flow.rs — compiled as a separate binary, only public API available
use mylib::OrderService;

#[test]
fn full_order_flow_creates_and_retrieves() {
    let service = OrderService::new_in_memory();
    let id = service.create("product-1", 2).unwrap();
    let order = service.get(id).unwrap();
    assert_eq!(order.product_id(), "product-1");
}
```

## Async Tests

```rust
#[tokio::test]
async fn fetch_user_returns_user() {
    let repo = FakeUserRepository::new();
    let service = UserService::new(repo);
    let user = service.get_user("1").await.unwrap();
    assert_eq!(user.name, "Test User");
}
```

- Use `#[tokio::test]` for async tests — not `tokio::runtime::Runtime::block_on`.
- For multi-threaded tests: `#[tokio::test(flavor = "multi_thread")]`.

## Parameterized Tests with rstest

```rust
use rstest::rstest;

#[rstest]
#[case("", false)]
#[case("  ", false)]
#[case("user@example.com", true)]
fn validate_email_cases(#[case] input: &str, #[case] expected: bool) {
    assert_eq!(validate_email(input), expected);
}
```

## Trait Fakes (Preferred over Mocks)

```rust
// Define the trait
trait UserRepository: Send + Sync {
    fn find(&self, id: &str) -> Option<User>;
}

// Fake implementation for tests
struct FakeUserRepository {
    users: HashMap<String, User>,
}

impl UserRepository for FakeUserRepository {
    fn find(&self, id: &str) -> Option<User> {
        self.users.get(id).cloned()
    }
}
```

## Error Testing

```rust
#[test]
fn not_found_returns_correct_error_variant() {
    let service = UserService::new(FakeUserRepository::empty());
    let err = service.get_user("missing").unwrap_err();
    assert!(matches!(err, AppError::NotFound(_)));
}
```

- Use `matches!` macro to assert error variants without pattern exhaustiveness issues.
- Test both `Ok` and `Err` paths for fallible functions.

## Benchmarks (Criterion)

```rust
use criterion::{criterion_group, criterion_main, Criterion};

fn bench_order_creation(c: &mut Criterion) {
    c.bench_function("create_order", |b| {
        b.iter(|| Order::new("product-1", 2))
    });
}

criterion_group!(benches, bench_order_creation);
criterion_main!(benches);
```

## What NOT to Test

- Derived trait implementations (`#[derive(Debug, Clone, PartialEq)]`).
- Compiler-guaranteed behavior (ownership, borrow rules).
- Simple getters/setters with no logic.
