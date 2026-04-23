---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# C# Coding Style

## Modern C# Features

- Enable nullable reference types: `<Nullable>enable</Nullable>` in `.csproj`.
- Use `record` types for immutable data objects (C# 9+).
- Use `record struct` for small immutable value types.
- Pattern matching with `switch` expressions over `if/else` chains.
- `using` declarations (C# 8+) over `using` blocks for cleaner code.
- `required` modifier for mandatory properties (C# 11+).

```csharp
// record — immutable, value equality, deconstruct
public record User(string Id, string Name, string Email);

// record struct — small value type
public readonly record struct Point(double X, double Y);

// required properties (C# 11)
public class CreateOrderRequest {
    public required string ProductId { get; init; }
    public required int Quantity { get; init; }
}

// switch expression over if/else chain
string GetLabel(OrderStatus status) => status switch {
    OrderStatus.Pending => "Awaiting payment",
    OrderStatus.Paid => "Processing",
    OrderStatus.Shipped => "On the way",
    OrderStatus.Delivered => "Complete",
    _ => throw new ArgumentOutOfRangeException(nameof(status))
};

// using declaration (C# 8+)
using var stream = File.OpenRead(path);  // disposed at end of scope
```

## Naming Conventions

- PascalCase: classes, methods, properties, events, namespaces.
- camelCase: local variables, method parameters.
- `_camelCase`: private fields (common convention).
- `I`-prefix for interfaces: `IUserRepository`.
- Async methods end with `Async`: `GetUserAsync`.

```csharp
public class OrderService {                    // PascalCase class
    private readonly IOrderRepository _repo;  // _camelCase private field

    public async Task<Order> GetOrderAsync(   // PascalCase method + Async suffix
        string orderId,                       // camelCase param
        CancellationToken cancellationToken = default) {

        var order = await _repo.FindAsync(orderId, cancellationToken);
        return order;
    }
}
```

## Null Handling

- Nullable reference types enabled — treat `?` annotations seriously.
- `ArgumentNullException.ThrowIfNull(param)` at method entry for required parameters.
- `??` for null coalescing, `?.` for null-conditional access.
- Avoid `!` (null-forgiving operator) — fix the underlying nullability instead.

```csharp
// GOOD — nullable annotations + guard
public string GetDisplayName(User? user) {
    ArgumentNullException.ThrowIfNull(user);
    return user.Profile?.DisplayName ?? user.Email;
}

// Pattern matching null check
if (order is { Status: OrderStatus.Paid, Items.Count: > 0 }) {
    process(order);
}

// BAD — null forgiving without justification
var name = user!.Name;  // crashes if user is null

// GOOD — prove it's not null
if (user is not null) {
    var name = user.Name;  // compiler knows it's non-null
}
```

## Async

- `async Task` not `async void` (except event handlers).
- `await` all async calls — never `.Result` or `.Wait()`.
- Pass `CancellationToken` through all async call chains.
- `ConfigureAwait(false)` in library code.

```csharp
// BAD — deadlock in UI/ASP.NET sync context
public User GetUser(string id) {
    return _repo.GetUserAsync(id).Result;  // blocks, deadlocks
}

// GOOD
public async Task<User?> GetUserAsync(string id, CancellationToken ct = default) {
    return await _repo.GetUserAsync(id, ct);
}

// BAD — fire and forget, exceptions lost
async void LoadData() {
    await FetchAsync();
}

// GOOD — explicit Task, exceptions propagate
async Task LoadDataAsync(CancellationToken ct = default) {
    await FetchAsync(ct);
}
```

## LINQ

```csharp
// BAD — multiple enumeration
IEnumerable<User> users = GetActiveUsers();
var count = users.Count();      // first evaluation
var first = users.First();      // second evaluation (re-queries DB if EF!)

// GOOD — materialize once
var users = GetActiveUsers().ToList();

// BAD — deferred execution surprises
var query = dbContext.Users.Where(u => u.IsActive);
dbContext.Database.ExecuteSql(...);  // context state changes
var result = query.ToList();  // result may differ from expected

// GOOD — materialize before side effects
var activeUsers = dbContext.Users.Where(u => u.IsActive).ToList();
```

## IDisposable

```csharp
// BAD — resource not disposed
var connection = new SqlConnection(connStr);
connection.Open();
// if exception → connection never closed

// GOOD — using declaration
using var connection = new SqlConnection(connStr);
await connection.OpenAsync(ct);

// GOOD — await using for async disposables
await using var stream = File.OpenRead(path);
```

## Code Quality

- One class per file (with the same name as the file).
- `sealed` on classes not designed for inheritance.
- `readonly` fields where possible.
- XML doc comments on all public members.
- Run `dotnet format` for consistent style.

## Tooling

```bash
# Build and check
dotnet build /p:TreatWarningsAsErrors=true

# Format
dotnet format

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage"

# Check for vulnerable packages
dotnet list package --vulnerable

# Nullable check
dotnet build /p:Nullable=enable
```

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `Task.Result` / `.Wait()` | `await` properly |
| `async void` (non-event) | `async Task` |
| Missing `CancellationToken` in I/O | Add `CancellationToken ct = default` |
| `IEnumerable` enumerated twice | `.ToList()` once |
| Null-forgiving `!` | Fix nullability or add guard |
| Mutable `class` for data | `record` type |
| `using { }` block | `using var` declaration (C# 8+) |
