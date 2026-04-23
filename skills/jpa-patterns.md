# Skill: JPA/Hibernate Patterns

## Trigger

Use when:
- Designing JPA entities or Spring Data repositories
- Diagnosing or preventing N+1 query problems
- Configuring fetch strategies, transactions, or locking
- Choosing between `@Query`, derived methods, or Criteria API
- Tuning connection pool or pagination behavior

## Process

### 1. N+1 problem and @EntityGraph fix

The N+1 problem: loading N parent entities triggers N additional queries to load each parent's lazy collection.

```java
// Entity setup
@Entity
public class Order {
    @Id @GeneratedValue
    private Long id;

    @OneToMany(mappedBy = "order", fetch = FetchType.LAZY)
    private List<OrderItem> items = new ArrayList<>();
}

// BAD — N+1: one query for orders, N queries for items
List<Order> orders = orderRepository.findAll();
orders.forEach(o -> o.getItems().size()); // triggers N selects

// FIX 1 — @EntityGraph on repository method (join fetch in one query)
public interface OrderRepository extends JpaRepository<Order, Long> {

    @EntityGraph(attributePaths = {"items"})
    List<Order> findByStatus(OrderStatus status);

    @EntityGraph(attributePaths = {"items", "items.product"})
    Optional<Order> findWithItemsById(Long id);
}

// FIX 2 — JPQL join fetch
@Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items WHERE o.status = :status")
List<Order> findByStatusWithItems(@Param("status") OrderStatus status);

// FIX 3 — Batch fetching (reduces N+1 to ceil(N/batchSize)+1 queries)
@Entity
@BatchSize(size = 25)  // on the entity or collection
public class Order { ... }

// Note: DISTINCT in JPQL is needed to deduplicate objects after join
// Spring Data: add Pageable AFTER join fetch — they don't combine directly
```

### 2. FetchType.LAZY as default

```java
@Entity
public class User {
    @Id @GeneratedValue
    private Long id;

    private String email;

    // LAZY — default for @OneToMany and @ManyToMany; always use this
    @OneToMany(mappedBy = "user", fetch = FetchType.LAZY, cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Address> addresses = new ArrayList<>();

    // LAZY for @ManyToOne and @OneToOne (NOT the default — must be explicit)
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "org_id")
    private Organization organization;

    // EAGER is almost always wrong — avoid
    // @ManyToOne(fetch = FetchType.EAGER)  // never; loads org on every user query
}

// Rule of thumb:
// All associations are LAZY by default.
// Eagerly load only what you need, only when you need it, via @EntityGraph or JOIN FETCH.
```

### 3. @Transactional boundaries

```java
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {

    // READ-ONLY transaction — Hibernate skips dirty checking; DB can use read replica
    @Transactional(readOnly = true)
    public List<OrderSummaryDto> listOrders(OrderStatus status) {
        return orderRepository.findSummariesByStatus(status);
    }

    // WRITE transaction — default propagation is REQUIRED
    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        var order = new Order(request.userId(), request.items());
        return orderRepository.save(order);
        // flush + commit happen automatically on method exit
    }

    // Transactional boundaries must be on the Spring proxy — not on private methods
    @Transactional
    public void process(Long id) {
        // inner call to private/same-class method will NOT start a new transaction
        doProcess(id);  // OK — same transaction
    }

    private void doProcess(Long id) { /* ... */ }

    // Rollback on checked exceptions (not rolled back by default)
    @Transactional(rollbackFor = InsufficientFundsException.class)
    public void transfer(Long from, Long to, BigDecimal amount)
            throws InsufficientFundsException {
        // ...
    }
}

// Common pitfall: @Transactional on a bean called from the same class
// Solution: inject self, use AspectJ weaving, or refactor to a separate bean
```

### 4. Optimistic locking with @Version

```java
@Entity
public class Product {
    @Id @GeneratedValue
    private Long id;

    private String name;
    private int stock;

    @Version
    private Long version;  // auto-incremented on every update
}

// Hibernate adds WHERE version = :current to UPDATE statements
// Throws OptimisticLockException if another transaction updated first

@Transactional
public void decrementStock(Long productId, int qty) {
    Product p = productRepository.findById(productId)
        .orElseThrow(() -> new EntityNotFoundException("Product: " + productId));

    if (p.getStock() < qty)
        throw new InsufficientStockException(productId, qty);

    p.setStock(p.getStock() - qty);  // version bumped on flush
}

// Handle conflicts at the service boundary
try {
    orderService.placeOrder(request);
} catch (OptimisticLockingFailureException e) {
    throw new ConflictException("Order was modified concurrently; please retry");
}

// For pessimistic locking (rare, high-contention scenarios)
@Lock(LockModeType.PESSIMISTIC_WRITE)
@Query("SELECT p FROM Product p WHERE p.id = :id")
Optional<Product> findByIdForUpdate(@Param("id") Long id);
```

### 5. Query methods vs @Query vs Criteria API

| Approach | Best for |
|---|---|
| Derived methods | Simple filters on 1-2 fields |
| `@Query` JPQL | Medium complexity, fixed structure |
| `@Query` native SQL | DB-specific features, complex joins |
| Criteria API / QueryDSL | Dynamic queries, many optional filters |

```java
public interface OrderRepository extends JpaRepository<Order, Long> {

    // Derived method — Spring generates JPQL from method name
    List<Order> findByStatusAndUserId(OrderStatus status, Long userId);
    Optional<Order> findTopByUserIdOrderByCreatedAtDesc(Long userId);
    long countByStatus(OrderStatus status);

    // @Query JPQL — more readable for complex logic
    @Query("""
        SELECT o FROM Order o
        WHERE o.user.id = :userId
          AND o.createdAt >= :since
          AND o.status IN :statuses
        ORDER BY o.createdAt DESC
        """)
    List<Order> findRecentOrders(
        @Param("userId") Long userId,
        @Param("since") Instant since,
        @Param("statuses") Collection<OrderStatus> statuses
    );

    // Native query — PostgreSQL-specific
    @Query(value = """
        SELECT o.* FROM orders o
        WHERE o.user_id = :userId
          AND o.metadata @> :jsonFilter::jsonb
        """, nativeQuery = true)
    List<Order> findByJsonMetadata(
        @Param("userId") Long userId,
        @Param("jsonFilter") String jsonFilter
    );
}

// Criteria API — dynamic query (many optional filters)
public List<Order> searchOrders(OrderSearchCriteria criteria) {
    CriteriaBuilder cb = em.getCriteriaBuilder();
    CriteriaQuery<Order> cq = cb.createQuery(Order.class);
    Root<Order> order = cq.from(Order.class);

    List<Predicate> predicates = new ArrayList<>();
    if (criteria.status() != null)
        predicates.add(cb.equal(order.get("status"), criteria.status()));
    if (criteria.userId() != null)
        predicates.add(cb.equal(order.get("user").get("id"), criteria.userId()));
    if (criteria.minAmount() != null)
        predicates.add(cb.ge(order.get("total"), criteria.minAmount()));

    cq.where(predicates.toArray(new Predicate[0]));
    return em.createQuery(cq).getResultList();
}
```

### 6. DTO projections

Never return JPA entities from REST endpoints. Use projections.

```java
// Interface projection — Spring Data generates a proxy
public interface OrderSummary {
    Long getId();
    String getStatus();
    BigDecimal getTotal();
    // Nested
    UserInfo getUser();

    interface UserInfo {
        String getEmail();
    }
}

// Repository returning projection
List<OrderSummary> findByStatus(OrderStatus status);

// Class-based DTO (preferred — immutable, serializable)
public record OrderDto(Long id, String status, BigDecimal total, String userEmail) {}

@Query("""
    SELECT new com.example.dto.OrderDto(o.id, o.status, o.total, o.user.email)
    FROM Order o
    WHERE o.status = :status
    """)
List<OrderDto> findDtosByStatus(@Param("status") OrderStatus status);

// Or with @SqlResultSetMapping for native queries
```

### 7. Auditing with @CreatedDate / @LastModifiedDate

```java
// Enable auditing in Spring Boot
@Configuration
@EnableJpaAuditing
public class JpaConfig {}

// Base entity — extend all audited entities from this
@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class AuditedEntity {

    @CreatedDate
    @Column(updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    private Instant updatedAt;

    @CreatedBy
    @Column(updatable = false)
    private String createdBy;

    @LastModifiedBy
    private String updatedBy;
}

// Provide the current auditor (Spring Security integration)
@Bean
public AuditorAware<String> auditorProvider() {
    return () -> Optional.ofNullable(SecurityContextHolder.getContext())
        .map(SecurityContext::getAuthentication)
        .filter(Authentication::isAuthenticated)
        .map(Authentication::getName);
}

@Entity
public class Order extends AuditedEntity {
    @Id @GeneratedValue
    private Long id;
    // ... all audit fields inherited
}
```

### 8. Pagination with Pageable

```java
// Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    // Derived pagination
    Page<Order> findByStatus(OrderStatus status, Pageable pageable);

    // With @Query — count query must be provided for Page
    @Query(
        value     = "SELECT o FROM Order o WHERE o.user.id = :userId",
        countQuery = "SELECT COUNT(o) FROM Order o WHERE o.user.id = :userId"
    )
    Page<Order> findByUserId(@Param("userId") Long userId, Pageable pageable);

    // Slice — lighter than Page (no COUNT query)
    Slice<Order> findByStatus(OrderStatus status, Pageable pageable);
}

// Controller
@GetMapping("/orders")
public Page<OrderDto> listOrders(
    @RequestParam(defaultValue = "0") int page,
    @RequestParam(defaultValue = "20") int size,
    @RequestParam(defaultValue = "createdAt") String sortBy
) {
    // Validate sort field against allowlist to prevent injection
    var allowed = Set.of("createdAt", "total", "status");
    if (!allowed.contains(sortBy)) throw new BadRequestException("invalid sort field");

    Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, sortBy));
    return orderRepository.findAll(pageable).map(orderMapper::toDto);
}

// Warning: OFFSET pagination is O(n) — for large datasets use keyset/cursor pagination
@Query("SELECT o FROM Order o WHERE o.id > :lastId ORDER BY o.id ASC LIMIT :size")
List<Order> findNextPage(@Param("lastId") Long lastId, @Param("size") int size);
```

### 9. Connection pool tuning (HikariCP)

```yaml
# application.yml
spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/mydb
    username: ${DB_USER}
    password: ${DB_PASSWORD}
    hikari:
      pool-name: HikariPool-Main
      maximum-pool-size: 20        # (CPU cores * 2) + disk spindles; start conservative
      minimum-idle: 5              # keep warm connections; set equal to max for fixed pool
      idle-timeout: 600000         # 10 min — evict idle connections
      max-lifetime: 1800000        # 30 min — recycle connections before DB kills them
      connection-timeout: 30000    # 30s — wait for connection from pool
      keepalive-time: 60000        # 1 min — ping idle connections to keep them alive
      leak-detection-threshold: 60000  # warn if connection held > 60s (debugging only)
      connection-test-query: SELECT 1  # for drivers without isValid() support
```

```java
// Monitor pool metrics (Micrometer / Actuator)
// Expose: hikaricp.connections.active, hikaricp.connections.idle, hikaricp.connections.pending
// Alert when pending > 0 consistently (pool exhaustion)
```

## Entity Design Rules

| Rule | Rationale |
|---|---|
| All associations default to `LAZY` | Prevents unintended data loading |
| `@Version` on every write-heavy entity | Prevents lost updates |
| No bidirectional unless required | Reduces complexity; unidirectional is simpler |
| Helper methods for bidirectional sync | `order.addItem(item)` sets both sides |
| `equals`/`hashCode` based on business key or ID only | Hibernate proxies break Object defaults |
| No `cascade = CascadeType.ALL` on `@ManyToOne` | Would delete the parent when child is removed |

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| EAGER fetch on association | Loads unneeded data on every query | `LAZY` + `@EntityGraph` |
| Entity returned from REST controller | Exposes DB schema, triggers lazy loading after session | DTO projection |
| `@Transactional` on private method | Spring proxy doesn't intercept | Move to separate bean or use AspectJ |
| N+1 in service layer | Slow; hard to detect in dev | Use `@EntityGraph` or JOIN FETCH |
| Open Session In View (OSIV) | Lazy loads in view layer; uncontrolled queries | Disable OSIV; load all data in service layer |
| `findAll()` without pagination | OOM on large tables | Always paginate |
| String concat in JPQL | SQL injection if using native | Always use `@Param` |

## Safe Behavior

- OSIV is disabled (`spring.jpa.open-in-view=false`) in all production configs.
- All entity relationships are `FetchType.LAZY`; eager loading is opt-in via `@EntityGraph`.
- All write-heavy entities have `@Version` for optimistic locking.
- No JPA entity is exposed directly from a REST endpoint.
- All paginated endpoints validate sort fields against an allowlist.
- HikariCP `max-lifetime` is set below the database's `wait_timeout` / `tcp_keepalives_idle`.
