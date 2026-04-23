---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Java Coding Style

## Null Safety

- Use `Optional<T>` for values that may be absent — never return `null` from public APIs.
- Annotate with `@NonNull` / `@Nullable` on all public method parameters and return types.
- Validate constructor and method parameters with `Objects.requireNonNull()`.

```java
// BAD
public User findUser(String id) { return null; }

// GOOD
public Optional<User> findUser(String id) {
    return Optional.ofNullable(repository.find(id));
}

// BAD
public void process(String name) { /* no check */ }

// GOOD
public void process(@NonNull String name) {
    Objects.requireNonNull(name, "name must not be null");
}
```

## Immutability

- Prefer immutable objects — use `final` fields and no setters.
- Use `Collections.unmodifiableList()` or Guava's `ImmutableList` for returned collections.
- Value objects (Money, Name, Id) should be immutable.

```java
// BAD — mutable, leaks internal state
public List<String> getTags() { return tags; }

// GOOD
public List<String> getTags() { return Collections.unmodifiableList(tags); }

// GOOD — Java record (Java 16+)
public record Money(BigDecimal amount, Currency currency) {}
```

## Error Handling

- Catch specific exception types — never `catch (Exception e)` unless re-throwing.
- Use try-with-resources for all `Closeable` resources.
- Never swallow exceptions with empty catch blocks.
- Checked exceptions for recoverable conditions; unchecked for programming errors.

```java
// BAD
try { doSomething(); } catch (Exception e) {}

// GOOD
try (InputStream in = Files.newInputStream(path)) {
    process(in);
} catch (IOException e) {
    throw new DataReadException("Failed to read " + path, e);
}
```

## Class Design

- Single Responsibility: one class does one thing.
- Classes over 300 lines should be reviewed for decomposition.
- Favor composition over inheritance.
- Interfaces for behavioral contracts; abstract classes only when shared implementation is needed.
- `final` on classes not designed for extension.

## Code Style

- Use `final` for local variables and parameters that are not reassigned.
- Methods over 30 lines are candidates for extraction.
- All public classes and methods have Javadoc.
- No `System.out.println` in production code — use a logger (SLF4J + Logback/Log4j).

```java
// BAD
System.out.println("Processing order: " + orderId);

// GOOD
private static final Logger log = LoggerFactory.getLogger(OrderService.class);
log.info("Processing order: {}", orderId);
```

## Modern Java

- Use records for simple data carriers (Java 16+).
- Use `var` for local variables where the type is obvious from the right-hand side.
- Use `instanceof` pattern matching instead of explicit casts (Java 16+).
- Use text blocks for multi-line strings (Java 15+).
- Streams for collection transformations — but profile for large datasets.

```java
// Pattern matching (Java 16+)
if (shape instanceof Circle c) {
    return Math.PI * c.radius() * c.radius();
}

// Text block (Java 15+)
String query = """
    SELECT id, name
    FROM users
    WHERE active = true
    """;

// Streams
List<String> activeNames = users.stream()
    .filter(User::isActive)
    .map(User::getName)
    .sorted()
    .toList(); // Java 16+
```

## Tooling

```bash
# Check style (Google/Sun Java style)
mvn checkstyle:check

# Static analysis
mvn spotbugs:check

# Run tests with coverage
mvn test jacoco:report

# Dependency vulnerability scan
mvn dependency-check:check
```

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `catch (Exception e) {}` | Catch specific type, log or rethrow |
| Returning `null` from public API | Return `Optional<T>` |
| `public List<X> getItems()` returning mutable | Wrap in `unmodifiableList()` |
| `System.out.println` | Use SLF4J logger |
| Inheritance for code reuse | Favor composition |
| Mutable static state | Avoid or use thread-safe containers |
