---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Java Testing Rules

## Toolchain

- JUnit 5 (`@Test`, `@BeforeEach`, `@AfterEach`, `@ParameterizedTest`) — not JUnit 4.
- Mockito for mocking; AssertJ for fluent assertions.
- Spring Boot Test (`@SpringBootTest`, `@WebMvcTest`, `@DataJpaTest`) for integration layers.

## Test Naming

```java
// Method name: should_[expected]_when_[condition]
@Test
void should_returnUser_when_idExists() { ... }

// Or: [method]_[scenario]_[expected]
@Test
void findById_nonExistentId_throwsNotFoundException() { ... }
```

## Unit Tests

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository repository;

    @InjectMocks
    private OrderService service;

    @Test
    void createOrder_validRequest_returnsOrderDto() {
        when(repository.save(any())).thenReturn(new Order("1", "product-1"));
        OrderDto result = service.create(new CreateOrderRequest("product-1", 2));
        assertThat(result.productId()).isEqualTo("product-1");
        verify(repository).save(any());
    }
}
```

- Use `@ExtendWith(MockitoExtension.class)` — not `MockitoAnnotations.openMocks(this)`.
- Verify only meaningful interactions — not every call.
- One logical assertion per test (multiple `assertThat` lines on the same result are fine).

## Spring MVC Tests

```java
@WebMvcTest(OrderController.class)
class OrderControllerTest {

    @Autowired MockMvc mockMvc;
    @MockBean OrderService orderService;

    @Test
    void createOrder_validBody_returns201() throws Exception {
        when(orderService.create(any())).thenReturn(new OrderDto("1", "product-1"));

        mockMvc.perform(post("/api/v1/orders")
                .contentType(APPLICATION_JSON)
                .content("{\"productId\":\"product-1\",\"quantity\":2}"))
               .andExpect(status().isCreated())
               .andExpect(jsonPath("$.id").value("1"));
    }
}
```

- `@WebMvcTest` loads only the web layer — fast.
- Use `@MockBean` to stub service layer in controller tests.

## Repository Tests

```java
@DataJpaTest
class OrderRepositoryTest {

    @Autowired OrderRepository repository;

    @Test
    void findByUserId_returnsOnlyUserOrders() {
        repository.save(new Order("user-1", "product-1"));
        repository.save(new Order("user-2", "product-2"));
        assertThat(repository.findByUserId("user-1")).hasSize(1);
    }
}
```

- `@DataJpaTest` uses an in-memory H2 database by default — isolated and fast.
- Test custom queries, not Spring Data auto-generated ones.

## Parameterized Tests

```java
@ParameterizedTest
@ValueSource(strings = {"", "  ", "\t"})
void create_blankName_throwsValidationException(String name) {
    assertThatThrownBy(() -> service.create(new CreateRequest(name)))
        .isInstanceOf(ValidationException.class);
}
```

## Integration Tests

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@AutoConfigureMockMvc
class OrderIntegrationTest {
    // Full context — use sparingly, run in a separate test suite
}
```

- Keep integration tests in a separate source set or profile — they are slow.
- Use `@Testcontainers` with a real database for tests that must validate SQL behavior.

## What NOT to Test

- Auto-generated getters/setters.
- Spring Data method name queries (trust the framework).
- Configuration beans — test them through behavior.
