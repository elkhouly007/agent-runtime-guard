---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Kotlin Testing Rules

## Toolchain

- JUnit 5 with Kotlin extensions (`kotlin-test`, `@Test`).
- MockK for Kotlin-native mocking — not Mockito (which doesn't handle Kotlin's `final` classes well without plugins).
- AssertK or `kotlin.test` assertions.
- Kotest for property-based testing and readable test DSL (optional but powerful).

## Test Naming

```kotlin
// Backtick names for readability
@Test
fun `should return user when id exists`() { ... }

@Test
fun `create order with blank name throws ValidationException`() { ... }
```

## Unit Tests with MockK

```kotlin
class OrderServiceTest {

    private val repository = mockk<OrderRepository>()
    private val service = OrderService(repository)

    @Test
    fun `create order returns saved order DTO`() {
        val order = Order(id = "1", productId = "p1")
        every { repository.save(any()) } returns order

        val result = service.create(CreateOrderRequest("p1", quantity = 2))

        assertThat(result.productId).isEqualTo("p1")
        verify { repository.save(any()) }
    }
}
```

- Use `every { }` for stubbing, `verify { }` for verifying calls.
- Use `coEvery { }` and `coVerify { }` for `suspend` functions.

## Coroutine Tests

```kotlin
class AsyncServiceTest {

    @Test
    fun `fetch user completes successfully`() = runTest {
        val repo = mockk<UserRepository>()
        coEvery { repo.fetchUser("1") } returns User("1", "Ahmed")

        val result = UserService(repo).getUser("1")

        assertThat(result.name).isEqualTo("Ahmed")
    }
}
```

- Use `runTest` from `kotlinx-coroutines-test` — not `runBlocking`.
- `runTest` skips artificial delays and controls virtual time.

## Spring Boot Tests (Kotlin)

```kotlin
@WebMvcTest(OrderController::class)
class OrderControllerTest {

    @Autowired lateinit var mockMvc: MockMvc
    @MockkBean lateinit var orderService: OrderService  // from springmockk library

    @Test
    fun `POST orders returns 201`() {
        every { orderService.create(any()) } returns OrderDto("1", "p1")

        mockMvc.perform(post("/api/v1/orders")
            .contentType(MediaType.APPLICATION_JSON)
            .content("""{"productId":"p1","quantity":2}"""))
            .andExpect(status().isCreated)
    }
}
```

- Use `springmockk` library for `@MockkBean` — replaces `@MockBean` (Mockito) in Spring tests.

## Data Classes in Tests

```kotlin
// Use copy() for creating test variants without full construction
val base = Order(id = "1", productId = "p1", quantity = 2, status = PENDING)
val shipped = base.copy(status = SHIPPED)
```

- Data classes make test setup concise — use `copy()` to create variants.

## Parameterized Tests

```kotlin
@ParameterizedTest
@ValueSource(strings = ["", "  ", "\t"])
fun `blank name throws ValidationException`(name: String) {
    assertThrows<ValidationException> { service.create(CreateRequest(name)) }
}
```

## What NOT to Test

- Auto-generated `equals`, `hashCode`, `copy` on data classes.
- Property accessors.
- Trivial delegating constructors.
