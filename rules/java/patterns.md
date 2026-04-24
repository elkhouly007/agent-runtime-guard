---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Java Design Patterns

Java-specific patterns for modern, maintainable code.

## Dependency Injection

Prefer constructor injection over field injection in Spring components:

```java
@Service
public class OrderService {
    private final OrderRepository repository;
    private final PaymentGateway paymentGateway;

    public OrderService(OrderRepository repository, PaymentGateway paymentGateway) {
        this.repository = repository;
        this.paymentGateway = paymentGateway;
    }
}
```

Constructor injection: dependencies are explicit, the class is testable without Spring context, dependencies are immutable.

## Value Objects

Use records for immutable value objects:

```java
public record Money(BigDecimal amount, Currency currency) {
    public Money {
        Objects.requireNonNull(amount);
        Objects.requireNonNull(currency);
        if (amount.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Amount cannot be negative");
        }
    }
}
```

## Repository Pattern

Separate data access from business logic:

```java
public interface UserRepository {
    Optional<User> findById(UserId id);
    void save(User user);
    List<User> findActiveUsers();
}
```

Business logic tests use a fake or mock `UserRepository`. The real implementation uses JPA.

## Command/Query Separation

Separate commands (state-changing operations) from queries (read-only operations):
- Commands: `void placeOrder(OrderRequest request)` — returns nothing, changes state
- Queries: `List<Order> getOrdersByUser(UserId userId)` — returns data, changes nothing

## Optional Idioms

```java
// Avoid: checking and using separately
if (optional.isPresent()) { use(optional.get()); }

// Prefer: functional style
optional.ifPresent(this::use);
optional.map(this::transform).orElse(defaultValue);
optional.orElseThrow(() -> new ResourceNotFoundException("..."));
```
