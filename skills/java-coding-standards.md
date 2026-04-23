# Skill: Java Coding Standards

## Trigger

Use when:
- Writing or reviewing Java 17+ code
- Choosing between records, sealed classes, or traditional POJOs
- Applying modern Java features (pattern matching, switch expressions, var)
- Designing exception handling strategies
- Evaluating Lombok usage trade-offs

## Process

### 1. Records (Java 16+)

Use records for immutable data carriers. They auto-generate constructor, accessors, `equals`, `hashCode`, and `toString`.

```java
// Bad — verbose POJO for a pure data holder
public final class Point {
    private final double x;
    private final double y;
    public Point(double x, double y) { this.x = x; this.y = y; }
    public double x() { return x; }
    public double y() { return y; }
    // equals, hashCode, toString...
}

// Good — record
public record Point(double x, double y) {
    // Compact canonical constructor for validation
    public Point {
        if (Double.isNaN(x) || Double.isNaN(y))
            throw new IllegalArgumentException("coordinates must not be NaN");
    }

    // Custom methods are allowed
    public double distanceTo(Point other) {
        double dx = this.x - other.x;
        double dy = this.y - other.y;
        return Math.sqrt(dx * dx + dy * dy);
    }
}

// Records work with sealed interfaces
public sealed interface Shape permits Circle, Rectangle {
    double area();
}

public record Circle(Point center, double radius) implements Shape {
    public double area() { return Math.PI * radius * radius; }
}

public record Rectangle(Point topLeft, double width, double height) implements Shape {
    public double area() { return width * height; }
}
```

### 2. Sealed classes (Java 17+)

```java
// Sealed hierarchy — exhaustive, compiler-enforced
public sealed interface Result<T>
    permits Result.Success, Result.Failure {

    record Success<T>(T value) implements Result<T> {}
    record Failure<T>(String message, Throwable cause) implements Result<T> {}

    static <T> Result<T> of(Supplier<T> supplier) {
        try {
            return new Success<>(supplier.get());
        } catch (Exception e) {
            return new Failure<>(e.getMessage(), e);
        }
    }
}

// Usage — switch is exhaustive, no default needed
Result<Order> result = orderService.create(request);
String message = switch (result) {
    case Result.Success<Order> s -> "Order created: " + s.value().id();
    case Result.Failure<Order> f -> "Error: " + f.message();
};
```

### 3. Pattern matching instanceof (Java 16+)

```java
// Bad — explicit cast after instanceof
if (obj instanceof String) {
    String s = (String) obj;
    System.out.println(s.length());
}

// Good — pattern matching
if (obj instanceof String s) {
    System.out.println(s.length());  // s is scoped to this block
}

// Combined with guards (Java 21+)
if (obj instanceof String s && s.length() > 10) {
    System.out.println("Long string: " + s);
}

// In switch (Java 21 — stable)
String describe(Object obj) {
    return switch (obj) {
        case Integer i when i < 0 -> "negative int: " + i;
        case Integer i            -> "positive int: " + i;
        case String s             -> "string of length " + s.length();
        case null                 -> "null";
        default                   -> "other: " + obj.getClass().getSimpleName();
    };
}
```

### 4. Switch expressions (Java 14+)

```java
// Old switch — fall-through bugs, no value
int days;
switch (month) {
    case FEBRUARY: days = 28; break;
    case APRIL: case JUNE: case SEPTEMBER: case NOVEMBER: days = 30; break;
    default: days = 31;
}

// Switch expression — exhaustive, no fall-through, returns value
int days = switch (month) {
    case FEBRUARY -> 28;
    case APRIL, JUNE, SEPTEMBER, NOVEMBER -> 30;
    default -> 31;
};

// With yield for multi-statement cases
String label = switch (status) {
    case PENDING -> "Pending";
    case ACTIVE -> {
        log.info("Active order");
        yield "Active";
    }
    case CANCELLED -> "Cancelled";
};
```

### 5. Optional — usage rules

```java
import java.util.Optional;

// Optional is for return values only — never for parameters or fields
// Bad
public void process(Optional<String> name) { }  // NEVER — use overloading
private Optional<String> cachedName;            // NEVER — use null or sentinel

// Good — return type
public Optional<User> findById(String id) {
    return userRepository.findById(id);  // returns Optional
}

// Correct Optional usage
findById("user-1")
    .map(User::email)
    .filter(email -> email.endsWith("@company.com"))
    .ifPresent(email -> sendNotification(email));

// orElse vs orElseGet — orElseGet is lazy (prefer when default is expensive)
String name = findById("user-1")
    .map(User::name)
    .orElseGet(() -> loadDefaultName());  // only called if empty

// orElseThrow — throw on missing (preferred over .get())
User user = findById("user-1")
    .orElseThrow(() -> new EntityNotFoundException("User not found: user-1"));

// Bad — Optional.get() without isPresent()
Optional<User> opt = findById("x");
User u = opt.get();  // NoSuchElementException — NEVER do this
```

### 6. Stream API best practices

```java
import java.util.stream.*;
import java.util.List;

List<Order> orders = getOrders();

// Filter, map, collect — basic pipeline
List<String> activeOrderIds = orders.stream()
    .filter(o -> o.status() == Status.ACTIVE)
    .map(Order::id)
    .toList();  // Java 16+ unmodifiable list

// Collectors
Map<Status, List<Order>> byStatus = orders.stream()
    .collect(Collectors.groupingBy(Order::status));

Map<Status, Long> countByStatus = orders.stream()
    .collect(Collectors.groupingBy(Order::status, Collectors.counting()));

// flatMap — flatten nested collections
List<Item> allItems = orders.stream()
    .flatMap(o -> o.items().stream())
    .toList();

// Avoid: long chains with side effects
orders.stream()
    .peek(o -> log.debug("processing " + o.id()))  // avoid peek in production
    .forEach(this::process);

// Prefer: collect to list, then iterate
List<Order> toProcess = orders.stream()
    .filter(this::shouldProcess)
    .toList();
toProcess.forEach(this::process);

// Parallel streams — only for CPU-bound, large datasets, no shared state
long count = largeDataset.parallelStream()
    .filter(expensiveFilter)
    .count();
```

### 7. var usage (Java 10+)

```java
// Good — obvious type from right side
var users = new ArrayList<User>();
var config = Map.of("host", "localhost", "port", 8080);
var entry = userRepository.findById("1");  // clear: returns Optional<User>

// Bad — type not obvious from right side
var x = process(data);      // what does process() return?
var result = mapper.map(o); // ambiguous

// In for loops — always good
for (var user : userList) {
    sendEmail(user);
}

// Bad — with diamond operator (loses type info)
var list = new ArrayList<>();  // ArrayList<Object> — NEVER
```

### 8. Exception handling — checked vs unchecked

```java
// Checked exceptions — recoverable, caller must handle
public class InsufficientFundsException extends Exception {
    private final double shortfall;
    public InsufficientFundsException(double shortfall) {
        super("Insufficient funds. Shortfall: " + shortfall);
        this.shortfall = shortfall;
    }
    public double shortfall() { return shortfall; }
}

// Unchecked exceptions — programming errors, infrastructure failures
public class OrderNotFoundException extends RuntimeException {
    public OrderNotFoundException(String id) {
        super("Order not found: " + id);
    }
}

// Rules:
// - Use checked for recoverable conditions (insufficient funds, file not found in user-controlled path)
// - Use unchecked for programming errors (null, illegal state, not found in fixed data)
// - Never catch Exception or Throwable without rethrowing or logging at ERROR

// Translating checked to unchecked at boundaries
try {
    return Files.readString(Path.of(configPath));
} catch (IOException e) {
    throw new UncheckedIOException("Failed to read config: " + configPath, e);
}
```

### 9. Builder pattern

```java
// Immutable object with Builder — use when > 3-4 constructor parameters
public final class HttpRequest {
    private final String method;
    private final URI uri;
    private final Map<String, String> headers;
    private final Duration timeout;

    private HttpRequest(Builder builder) {
        this.method  = Objects.requireNonNull(builder.method, "method");
        this.uri     = Objects.requireNonNull(builder.uri, "uri");
        this.headers = Map.copyOf(builder.headers);
        this.timeout = builder.timeout;
    }

    public static Builder builder() { return new Builder(); }

    public static final class Builder {
        private String method = "GET";
        private URI uri;
        private final Map<String, String> headers = new LinkedHashMap<>();
        private Duration timeout = Duration.ofSeconds(30);

        public Builder method(String method) { this.method = method; return this; }
        public Builder uri(URI uri)          { this.uri = uri; return this; }
        public Builder header(String k, String v) { headers.put(k, v); return this; }
        public Builder timeout(Duration t)   { this.timeout = t; return this; }

        public HttpRequest build()           { return new HttpRequest(this); }
    }
}

// Usage
var request = HttpRequest.builder()
    .method("POST")
    .uri(URI.create("https://api.example.com/orders"))
    .header("Content-Type", "application/json")
    .timeout(Duration.ofSeconds(10))
    .build();
```

### 10. Lombok trade-offs

| Lombok feature | Recommendation |
|---|---|
| `@Data` | Avoid on domain objects — generates mutable `setters` and `equals` by ID fields only |
| `@Value` | Acceptable for simple immutable DTOs; prefer records (Java 16+) |
| `@Builder` | Acceptable; generates builder; prefer manual builder for complex validation |
| `@Slf4j` | Acceptable; purely boilerplate reduction |
| `@RequiredArgsConstructor` | Acceptable for Spring injection |
| `@SneakyThrows` | Avoid — hides checked exception contract from callers |
| `@EqualsAndHashCode` | Danger on JPA entities — use only ID field, or avoid entirely |

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| Mutable public fields | Breaks encapsulation | `private final` fields with accessors |
| `catch (Exception e) {}` empty catch | Swallows failures silently | Always log or rethrow |
| `Optional.get()` without check | `NoSuchElementException` | `orElseThrow()` with descriptive message |
| `new ArrayList<>()` returned from API | Caller can mutate internal list | Return `List.copyOf()` or `Collections.unmodifiableList()` |
| `instanceof` with explicit cast | Verbose, error-prone | Pattern matching `instanceof X x` |
| `String` concatenation in loops | `O(n²)` memory | `StringBuilder` or `String.join` |
| Static utility classes with state | Untestable | Inject as beans |

## Safe Behavior

- All data carrier classes use `record` (Java 16+) unless mutability is required.
- `Optional` is never used as a method parameter or field type.
- Checked exceptions are only declared when the caller can realistically recover.
- `switch` expressions are used over `switch` statements for value-returning switches.
- All returned collections are unmodifiable copies from public API methods.
- `var` is only used when the type is obvious from the same line.
