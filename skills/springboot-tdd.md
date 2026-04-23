# Skill: Spring Boot TDD

## Trigger

Use when:
- Writing new Spring Boot controllers, services, repositories, or jobs
- Fixing a bug — the bug itself is a missing test
- Adding REST API endpoints to a Spring Boot application
- Setting up the test infrastructure for a new project
- Any feature where the expected behavior can be stated before writing code

## The TDD Cycle (Spring Boot-Adapted)

```
RED    → Write a failing @Test (assertThrows, status().isForbidden(), assertThat().isEmpty())
GREEN  → Write minimum @RestController / @Service / @Repository code to make it pass
REFACTOR → Clean up, extract helpers, run full suite to confirm green
repeat
```

**Never skip RED.** Confirm the failure message before writing implementation.

## Process

### 1. Choosing the Right Test Slice

| Annotation | Loads | DB | Use When |
|---|---|---|---|
| `@SpringBootTest` | Full context | Real or TestContainers | Integration tests, full stack |
| `@WebMvcTest` | Web layer only | None | Controller + security tests |
| `@DataJpaTest` | JPA + DB only | Embedded H2 or TestContainers | Repository / query tests |
| `@JsonTest` | Jackson only | None | JSON serialization/deserialization |
| Plain JUnit 5 | Nothing | None | Pure service / utility logic |

### 2. @WebMvcTest — Controller Tests with MockMvc

```java
// src/test/java/com/example/controller/OrderControllerTest.java
@WebMvcTest(OrderController.class)
@Import(SecurityConfig.class)
class OrderControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderService orderService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private UserDetailsService userDetailsService;

    @Test
    void getOrders_unauthenticated_returns401() throws Exception {
        mockMvc.perform(get("/api/orders"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(username = "user@example.com", roles = "USER")
    void getOrders_authenticated_returns200WithOrderList() throws Exception {
        List<OrderDto> orders = List.of(
            new OrderDto(1L, "pending", 2500L),
            new OrderDto(2L, "complete", 1000L)
        );
        given(orderService.getOrdersForUser("user@example.com")).willReturn(orders);

        mockMvc.perform(get("/api/orders").contentType(MediaType.APPLICATION_JSON))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(2)))
            .andExpect(jsonPath("$[0].status").value("pending"))
            .andExpect(jsonPath("$[0].total").value(2500));
    }

    @Test
    @WithMockUser(roles = "USER")
    void placeOrder_invalidBody_returns422() throws Exception {
        String body = """
            {"items": []}
            """;

        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content(body))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.errors.items").exists());
    }
}
```

### 3. @DataJpaTest — Repository Tests

```java
// src/test/java/com/example/repository/OrderRepositoryTest.java
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)  // use TestContainers
class OrderRepositoryTest {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private TestEntityManager entityManager;

    @Test
    void findByUserIdAndStatus_returnsPendingOrdersOnly() {
        User user = entityManager.persist(new User("alice@example.com", "hash", Role.USER));
        entityManager.persist(new Order(user, "pending", 1000L));
        entityManager.persist(new Order(user, "complete", 2000L));
        entityManager.persist(new Order(user, "pending", 3000L));
        entityManager.flush();

        List<Order> pending = orderRepository.findByUserIdAndStatus(user.getId(), "pending");

        assertThat(pending).hasSize(2);
        assertThat(pending).allMatch(o -> o.getStatus().equals("pending"));
    }

    @Test
    void findByUserId_withNoOrders_returnsEmptyList() {
        List<Order> result = orderRepository.findByUserId(999L);
        assertThat(result).isEmpty();
    }
}
```

### 4. TestContainers for Real Database

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>junit-jupiter</artifactId>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>postgresql</artifactId>
    <scope>test</scope>
</dependency>
```

```java
// src/test/java/com/example/AbstractIntegrationTest.java
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
public abstract class AbstractIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }
}
```

Full integration test:
```java
class OrderIntegrationTest extends AbstractIntegrationTest {

    @Autowired
    private TestRestTemplate restTemplate;

    @Autowired
    private OrderRepository orderRepository;

    @Test
    void placeOrder_fullStack_persistsAndReturns201() {
        String token = loginAndGetToken("user@example.com", "password");
        HttpHeaders headers = new HttpHeaders();
        headers.setBearerAuth(token);

        PlaceOrderRequest body = new PlaceOrderRequest(
            List.of(new OrderItem(1L, 2, 1500L)),
            "123 Main St"
        );

        ResponseEntity<OrderDto> response = restTemplate.exchange(
            "/api/orders",
            HttpMethod.POST,
            new HttpEntity<>(body, headers),
            OrderDto.class
        );

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        assertThat(response.getBody().getStatus()).isEqualTo("pending");
        assertThat(orderRepository.count()).isEqualTo(1);
    }
}
```

### 5. Mockito for Service Layer

```java
// src/test/java/com/example/service/OrderServiceTest.java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;

    @Mock
    private ApplicationEventPublisher eventPublisher;

    @InjectMocks
    private OrderService orderService;

    @Test
    void placeOrder_validItems_savesAndPublishesEvent() {
        User user = new User(1L, "alice@example.com");
        List<OrderItemDto> items = List.of(new OrderItemDto(1L, 2, 1500L));
        Order savedOrder = new Order(1L, user, "pending", 3000L);

        given(orderRepository.save(any(Order.class))).willReturn(savedOrder);

        OrderDto result = orderService.placeOrder(user, items, "123 Main St");

        assertThat(result.getStatus()).isEqualTo("pending");
        assertThat(result.getTotal()).isEqualTo(3000L);
        verify(orderRepository).save(any(Order.class));
        verify(eventPublisher).publishEvent(any(OrderPlacedEvent.class));
    }

    @Test
    void cancelOrder_completedOrder_throwsIllegalStateException() {
        Order completedOrder = new Order(1L, null, "complete", 1000L);
        given(orderRepository.findById(1L)).willReturn(Optional.of(completedOrder));

        assertThatThrownBy(() -> orderService.cancelOrder(1L))
            .isInstanceOf(IllegalStateException.class)
            .hasMessageContaining("Cannot cancel a completed order");
    }
}
```

### 6. @Transactional Test Rollback

```java
// Tests annotated with @Transactional roll back automatically after each test
@SpringBootTest
@Transactional
class OrderPersistenceTest {

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private UserRepository userRepository;

    @Test
    void order_savedWithUser_cascadeLoadsCorrectly() {
        User user = userRepository.save(new User("bob@example.com", "hash", Role.USER));
        Order order = orderRepository.save(new Order(user, "pending", 5000L));

        Order found = orderRepository.findById(order.getId()).orElseThrow();
        assertThat(found.getUser().getEmail()).isEqualTo("bob@example.com");
        // Data rolled back after test — no cleanup needed
    }
}
```

### 7. AssertJ Assertions

```java
// Prefer AssertJ over JUnit's assert* — richer failure messages
import static org.assertj.core.api.Assertions.*;

// Collections
assertThat(orders).hasSize(3)
                  .extracting(Order::getStatus)
                  .containsOnly("pending");

// Exceptions
assertThatThrownBy(() -> service.cancelOrder(completedOrderId))
    .isInstanceOf(IllegalStateException.class)
    .hasMessageContaining("Cannot cancel");

// Optional
assertThat(repository.findByEmail("unknown@example.com")).isEmpty();

// Object fields
assertThat(order)
    .hasFieldOrPropertyWithValue("status", "pending")
    .hasFieldOrPropertyWithValue("total", 3000L);
```

### 8. Coverage with JaCoCo

```xml
<!-- pom.xml -->
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.12</version>
    <executions>
        <execution>
            <goals><goal>prepare-agent</goal></goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>verify</phase>
            <goals><goal>report</goal></goals>
        </execution>
        <execution>
            <id>check</id>
            <goals><goal>check</goal></goals>
            <configuration>
                <rules>
                    <rule>
                        <element>BUNDLE</element>
                        <limits>
                            <limit>
                                <counter>LINE</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.85</minimum>
                            </limit>
                        </limits>
                    </rule>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
```

```bash
mvn verify                        # runs tests + coverage check
mvn jacoco:report                 # generate HTML report in target/site/jacoco/
open target/site/jacoco/index.html
```

## Test Naming Convention

| Bad | Good |
|-----|------|
| `testOrder()` | `placeOrder_validItems_savesAndPublishesEvent()` |
| `testCancel()` | `cancelOrder_completedOrder_throwsIllegalStateException()` |
| `testGetOrders()` | `getOrders_unauthenticated_returns401()` |
| `testRepo()` | `findByUserIdAndStatus_returnsPendingOrdersOnly()` |

Use `methodUnderTest_scenario_expectedOutcome` — readable as a specification.

## Anti-Patterns

- `@SpringBootTest` for every test — loads full context each time; use slices when possible.
- `@MockBean` in `@SpringBootTest` when `@WebMvcTest` would suffice — slower and fragile.
- H2 as the only test DB — misses PostgreSQL-specific behavior; use TestContainers for integration tests.
- Not verifying `verify(mock, never())` — unchecked side effects.
- Testing private methods directly — sign to extract to a separate class instead.
- Missing `@Transactional` on integration tests — leaves data that pollutes subsequent tests.
- Writing tests after implementation — confirmation tests, not behavior specs.

## Safe Behavior

- RED step is mandatory: run the test, confirm it fails with the right error before writing implementation.
- `@WebMvcTest` for controller tests, `@DataJpaTest` for repository tests — avoid `@SpringBootTest` for unit work.
- TestContainers is used for any test that touches DB-specific behavior (JSON columns, window functions, etc.).
- JaCoCo minimum line coverage of 85% enforced at `mvn verify` — build fails if threshold is not met.
- Tests run in CI on every PR — failures block merge.
- Flaky tests are fixed immediately — never marked `@Disabled` without a tracked issue.
