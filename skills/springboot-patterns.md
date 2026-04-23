# Skill: springboot-patterns

## Purpose

Apply Spring Boot best practices — project structure, layered architecture, security, testing, and performance for Java/Kotlin Spring Boot applications.

## Trigger

- Starting or reviewing a Spring Boot project
- Implementing REST APIs, services, or repositories
- Asked about Spring Boot configuration, security, or testing patterns

## Trigger

`/springboot-patterns` or `apply springboot patterns to [target]`

## Agents

- `java-reviewer` or `kotlin-reviewer` — language-specific review
- `security-reviewer` — Spring Security specifics

## Patterns

### Project Structure

```
src/main/java/com/example/
├── config/          # Security, CORS, persistence config
├── controller/      # REST controllers (thin — no business logic)
├── service/         # Business logic interfaces + implementations
├── repository/      # JPA repositories
├── domain/          # Entity classes
├── dto/             # Request/response DTOs
└── exception/       # Global exception handler
```

### Layered Architecture

- **Controller** → validates input, delegates to service, returns DTO.
- **Service** → business logic, transactions, calls repository.
- **Repository** → data access only, no business logic.
- Never call a repository directly from a controller.

### REST Controllers

```java
@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
public class OrderController {

    private final OrderService orderService;

    @PostMapping
    public ResponseEntity<OrderDto> create(@Valid @RequestBody CreateOrderRequest req) {
        return ResponseEntity.status(201).body(orderService.create(req));
    }
}
```

### Services and Transactions

```java
@Service
@Transactional(readOnly = true)
public class OrderService {

    @Transactional  // override to read-write for mutations
    public OrderDto create(CreateOrderRequest req) { ... }
}
```

- Use `@Transactional(readOnly = true)` at the class level; override for writes.
- Do not catch and swallow `RuntimeException` inside a `@Transactional` method — it will prevent rollback.

### Configuration

- Use `@ConfigurationProperties` for typed config binding — not `@Value` scattered everywhere.
- Store secrets in environment variables or Spring Cloud Config — not in `application.properties`.
- Use profiles: `application-local.yml`, `application-prod.yml`.

### Security

- Use Spring Security with `SecurityFilterChain` (not `WebSecurityConfigurerAdapter` — deprecated).
- Stateless JWT for APIs: `SessionCreationPolicy.STATELESS`.
- Use `@PreAuthorize("hasRole('ADMIN')")` on sensitive endpoints.

### Testing

```java
@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerTest {
    @Test
    void createOrder_returnsCreated() throws Exception {
        mockMvc.perform(post("/api/v1/orders").contentType(APPLICATION_JSON).content("{}"))
               .andExpect(status().isCreated());
    }
}
```

- Use `@WebMvcTest` for controller unit tests (no full context).
- Use `@DataJpaTest` for repository tests with in-memory DB.
- Use `@SpringBootTest` + `@AutoConfigureMockMvc` for integration tests.

## Safe Behavior

- Analysis only unless asked to modify code.
- Follow `rules/java/coding-style.md` and `rules/java/security.md`.
