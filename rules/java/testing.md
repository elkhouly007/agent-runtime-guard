# Java Testing

Java-specific testing standards.

## Framework

- JUnit 5 for unit and integration tests.
- Mockito for mocking.
- AssertJ for fluent assertions.
- TestContainers for integration tests with real databases, message queues, and other services.
- Spring Boot Test (`@SpringBootTest`) for full-context Spring integration tests.

## Test Structure

- One test class per production class. `AuthService` tested by `AuthServiceTest`.
- Use `@Nested` classes to group related tests under a common context.
- Test method naming: `shouldReturnEmptyOptional_whenUserNotFound()` or `when_userNotFound_returns_emptyOptional()`.
- Use `@DisplayName` for human-readable test descriptions in test reports.

## Mocking

- Mock at the service layer boundary: repositories are mocked in service tests; external APIs are mocked in service tests.
- `@Mock` with `@InjectMocks` for pure unit tests.
- `@MockBean` for Spring context tests where the bean needs to be replaced with a mock.
- Verify interactions sparingly — `verify(mock).method()` should be used for command operations (side effects), not for query operations.

## Parameterized Tests

```java
@ParameterizedTest
@MethodSource("invalidInputProvider")
void shouldRejectInvalidInput(String input, String expectedMessage) {
    assertThatThrownBy(() -> service.process(input))
        .isInstanceOf(ValidationException.class)
        .hasMessageContaining(expectedMessage);
}
```

## Integration Tests

- TestContainers for database integration tests. Use a real database, not H2 in-memory.
- `@Transactional` on test classes to roll back database changes after each test.
- Test the real HTTP layer with `MockMvc` or `WebTestClient` rather than calling service methods directly in controller tests.
