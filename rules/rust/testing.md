---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Rust Testing

Rust-specific testing standards.

## Framework

- Built-in test framework with `#[test]` attribute for unit tests.
- `#[cfg(test)]` module for test-only code co-located with the implementation.
- Integration tests in the `tests/` directory for testing the public API.
- `proptest` or `quickcheck` for property-based testing.
- `criterion` for benchmarks with statistical significance.

## Test Structure

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_behavior_under_condition() {
        // Arrange
        let input = ...;
        // Act
        let result = function_under_test(input);
        // Assert
        assert_eq!(result, expected);
    }
}
```

- Test names use `snake_case` and describe the behavior and condition.
- Each test has a single logical assertion. Multiple assertions are acceptable when they describe the same outcome.

## Property-Based Testing

Property-based tests find edge cases you did not think to test:

```rust
proptest! {
    #[test]
    fn test_parse_round_trips(s in "\\PC*") {
        let parsed = parse(&s);
        prop_assume!(parsed.is_ok());
        assert_eq!(serialize(parsed.unwrap()), s);
    }
}
```

## Error Testing

- Test that fallible functions return the correct error types.
- Use `assert!(result.is_err())` and then inspect the error variant.
- `#[should_panic(expected = "message")]` for panics that are expected behavior.

## Performance Tests

- `criterion` for micro-benchmarks. Run with `cargo bench`.
- `cargo test --release` to verify correctness under release optimizations.
- Use `black_box()` to prevent the optimizer from eliding benchmark computations.
