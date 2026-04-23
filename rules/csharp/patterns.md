---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# C# Design Patterns

C#-specific patterns for modern, maintainable code.

## CQRS with MediatR

Separate read and write operations:

```csharp
// Command: changes state
public record CreateOrderCommand(UserId UserId, IReadOnlyList<OrderLine> Lines) : IRequest<OrderId>;

public class CreateOrderHandler : IRequestHandler<CreateOrderCommand, OrderId> {
    public async Task<OrderId> Handle(CreateOrderCommand cmd, CancellationToken ct) { ... }
}

// Query: reads state
public record GetOrderQuery(OrderId OrderId) : IRequest<OrderDto?>;
```

## Result Pattern

Return explicit success/failure without exceptions for expected failure modes:

```csharp
public record Result<T> {
    public bool IsSuccess { get; }
    public T? Value { get; }
    public string? Error { get; }
    public static Result<T> Success(T value) => new(true, value, null);
    public static Result<T> Failure(string error) => new(false, default, error);
}
```

## Options Pattern

Configuration with `IOptions<T>`:

```csharp
public record FeatureFlags {
    public bool EnableNewCheckout { get; init; }
    public int MaxUploadSizeMB { get; init; }
}
// In DI: services.Configure<FeatureFlags>(configuration.GetSection("FeatureFlags"));
// In service: constructor inject IOptions<FeatureFlags>
```

## Specification Pattern

Encapsulate query predicates as reusable objects:

```csharp
public abstract class Specification<T> {
    public abstract Expression<Func<T, bool>> ToExpression();
    public Specification<T> And(Specification<T> other) => new AndSpecification<T>(this, other);
}

// Usage: repository.Find(new ActiveUserSpec().And(new PremiumUserSpec()))
```
