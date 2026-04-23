# Kotlin Testing

Kotlin-specific testing standards.

## Framework

- JUnit 5 with Kotlin extensions (`kotlin-test-junit5`).
- MockK for mocking — it understands Kotlin's final-by-default and coroutines.
- Kotest as an alternative for a Kotlin-first testing DSL.
- Turbine for testing Kotlin Flows.
- kotlinx-coroutines-test for coroutine testing.

## Coroutine Testing

```kotlin
@Test
fun `emits loading then result`() = runTest {
    val flow = repository.getUserFlow(userId)
    val results = flow.take(2).toList()
    assertEquals(LoadingState, results[0])
    assertEquals(SuccessState(user), results[1])
}
```

- Use `runTest` (from `kotlinx-coroutines-test`) for coroutine tests. It controls virtual time.
- `TestCoroutineDispatcher` (or `UnconfinedTestDispatcher`) for immediate coroutine execution.
- `advanceUntilIdle()` to run all pending coroutines in virtual time.

## MockK Usage

```kotlin
val mockService = mockk<UserService>()
every { mockService.findById(userId) } returns user
coEvery { mockService.findByIdAsync(userId) } returns user  // for suspend functions
verify { mockService.findById(userId) }
coVerify { mockService.findByIdAsync(userId) }  // for suspend functions
```

## Kotlin Test Conventions

- Use backtick-quoted test names: `` `returns 404 when user not found` ``.
- Use `@Nested` inner classes to group tests by scenario.
- `shouldNotBeNull()` extension from kotlin-test for null assertions.
- `shouldThrow<ExceptionType> { ... }` for exception testing.
