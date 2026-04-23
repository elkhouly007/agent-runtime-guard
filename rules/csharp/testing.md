---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# C# Testing Rules

## Toolchain

- xUnit for test runner — not NUnit or MSTest (xUnit is the modern default).
- Moq or NSubstitute for mocking interfaces.
- FluentAssertions for readable assertions.
- `Microsoft.AspNetCore.Mvc.Testing` for integration tests.
- Bogus or AutoFixture for test data generation.

## Test Naming

```csharp
// [Method]_[Scenario]_[ExpectedBehavior]
[Fact]
public async Task CreateOrder_ValidRequest_ReturnsCreatedOrder() { ... }

[Fact]
public async Task CreateOrder_BlankProductId_ThrowsArgumentException() { ... }
```

## Unit Tests with Moq

```csharp
public class OrderServiceTests
{
    private readonly Mock<IOrderRepository> _repoMock = new();
    private readonly OrderService _sut;

    public OrderServiceTests()
    {
        _sut = new OrderService(_repoMock.Object);
    }

    [Fact]
    public async Task CreateOrder_ValidRequest_SavesAndReturnsDto()
    {
        var order = new Order { Id = "1", ProductId = "p1" };
        _repoMock.Setup(r => r.SaveAsync(It.IsAny<Order>(), default))
                 .ReturnsAsync(order);

        var result = await _sut.CreateAsync(new CreateOrderRequest("p1", 2));

        result.ProductId.Should().Be("p1");
        _repoMock.Verify(r => r.SaveAsync(It.IsAny<Order>(), default), Times.Once);
    }
}
```

- Use `_sut` (System Under Test) as the naming convention for the class being tested.
- Use `It.IsAny<T>()` sparingly — be specific when the argument matters.

## Theory / Parameterized Tests

```csharp
[Theory]
[InlineData("")]
[InlineData("   ")]
[InlineData(null)]
public async Task CreateOrder_BlankName_ThrowsValidationException(string? name)
{
    var act = async () => await _sut.CreateAsync(new CreateOrderRequest(name!, 1));
    await act.Should().ThrowAsync<ValidationException>();
}
```

## ASP.NET Core Integration Tests

```csharp
public class OrdersEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    public OrdersEndpointTests(WebApplicationFactory<Program> factory)
    {
        _client = factory.WithWebHostBuilder(builder =>
            builder.ConfigureServices(services =>
                services.AddSingleton<IOrderRepository, FakeOrderRepository>()))
            .CreateClient();
    }

    [Fact]
    public async Task PostOrder_ValidBody_Returns201()
    {
        var response = await _client.PostAsJsonAsync("/api/v1/orders",
            new { productId = "p1", quantity = 2 });

        response.StatusCode.Should().Be(HttpStatusCode.Created);
    }
}
```

- Use `WebApplicationFactory<Program>` with `WithWebHostBuilder` to replace real services with fakes.
- `IClassFixture<T>` shares the factory across tests in the class — faster than creating it per test.

## FluentAssertions

```csharp
// Object assertions
result.Should().NotBeNull();
result.ProductId.Should().Be("p1");

// Collection assertions
orders.Should().HaveCount(3).And.Contain(o => o.Status == OrderStatus.Pending);

// Exception assertions
act.Should().ThrowAsync<ValidationException>()
   .WithMessage("*required*");
```

## Fake Repository Pattern

```csharp
internal sealed class FakeOrderRepository : IOrderRepository
{
    private readonly List<Order> _store = new();

    public Task<Order> SaveAsync(Order order, CancellationToken ct = default)
    {
        _store.Add(order);
        return Task.FromResult(order);
    }

    public Task<Order?> FindByIdAsync(string id, CancellationToken ct = default) =>
        Task.FromResult(_store.FirstOrDefault(o => o.Id == id));
}
```

## What NOT to Test

- Auto-generated EF Core migrations.
- Simple POCO property accessors.
- Framework routing and middleware behavior (trust ASP.NET Core).
