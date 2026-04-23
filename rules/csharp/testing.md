# C# Testing

C#-specific testing standards.

## Framework

- xUnit for unit and integration tests (preferred in .NET ecosystem).
- Moq or NSubstitute for mocking.
- FluentAssertions for readable assertion syntax.
- Testcontainers-dotnet for integration tests with real databases.
- ASP.NET Core `WebApplicationFactory<T>` for integration testing HTTP endpoints.

## Test Structure

- Test class naming: `UserServiceTests` for testing `UserService`.
- Test method naming: `GetUser_WhenUserNotFound_ReturnsNull` or `Should_ReturnError_When_TokenExpired`.
- Use `[Theory]` with `[InlineData]` or `[MemberData]` for parameterized tests.

```csharp
[Theory]
[InlineData("", "Email is required")]
[InlineData("notanemail", "Invalid email format")]
public void Validate_InvalidEmail_ReturnsError(string email, string expectedMessage) {
    var result = validator.Validate(new CreateUserRequest { Email = email });
    result.Errors.Should().ContainSingle(e => e.ErrorMessage == expectedMessage);
}
```

## Async Testing

- `async Task` return type for async test methods (not `async void`).
- Do not use `.Wait()` or `.Result` in tests.
- `CancellationToken` in tests: use `CancellationToken.None` or `TestContext.Current.CancellationToken`.

## Integration Tests

- `WebApplicationFactory<Program>` for testing ASP.NET controllers with real routing and middleware.
- Testcontainers for database integration: spin up a real database in a container per test run.
- Reset database state between tests: use transactions rolled back in `Dispose()` or reset via SQL.
