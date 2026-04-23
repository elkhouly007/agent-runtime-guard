---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Kotlin Security Rules

## OWASP Coverage Map

| OWASP Item | Section Below |
|------------|---------------|
| A01 Broken Access Control | Auth & Authorization |
| A02 Cryptographic Failures | Cryptography |
| A03 Injection | SQL / Command Injection |
| A04 Insecure Design | Null Safety, Deserialization |
| A05 Security Misconfiguration | Spring Boot Security |
| A06 Vulnerable Components | Dependencies |
| A07 Auth Failures | Auth & Authorization, JWT |
| A08 Software Integrity Failures | Deserialization |
| A09 Logging Failures | Secrets, Logging |
| A10 SSRF | Input Validation, HTTP Clients |

---

## Input Validation

- Validate all inputs at controller/handler boundaries using Bean Validation (`@Valid`, `@NotNull`, `@Size`, `@Pattern`).
- Use data classes with validated DTOs — never bind raw request parameters to domain objects.
- Leverage Kotlin's type system: use non-nullable types to enforce required fields at compile time.
- Reject unexpected or oversized input early; do not silently ignore unknown fields.

**BAD — raw parameter binding:**
```kotlin
@PostMapping("/user")
fun createUser(@RequestParam name: String, @RequestParam email: String) {
    // no validation — name can be "", email can be "'; DROP TABLE users;--"
    userService.create(name, email)
}
```

**GOOD — validated DTO:**
```kotlin
data class CreateUserRequest(
    @field:NotBlank @field:Size(max = 64)
    val name: String,

    @field:Email @field:NotBlank
    val email: String
)

@PostMapping("/user")
fun createUser(@RequestBody @Valid request: CreateUserRequest): ResponseEntity<*> {
    return ResponseEntity.ok(userService.create(request))
}
```

---

## SQL Injection Prevention

**BAD — string interpolation in SQL:**
```kotlin
val query = "SELECT * FROM users WHERE name = '${name}'"
jdbcTemplate.queryForList(query)
```

**GOOD — parameterized query (JDBC / JdbcTemplate):**
```kotlin
val user = jdbcTemplate.queryForObject(
    "SELECT * FROM users WHERE name = ?",
    arrayOf(name),
    UserRowMapper()
)
```

**GOOD — Exposed ORM:**
```kotlin
Users.select { Users.name eq name }.firstOrNull()
```

**GOOD — Spring Data JPA:**
```kotlin
@Query("SELECT u FROM User u WHERE u.name = :name")
fun findByName(@Param("name") name: String): User?
```

Never use string interpolation (`${}`) or `String.format` to build SQL.

---

## Deserialization

- Never deserialize untrusted data with Java `ObjectInputStream` — it allows arbitrary code execution via gadget chains.
- Use `kotlinx.serialization` or Jackson with explicit type mapping and no `TypeNameHandling.ALL`.
- If Java serialization is unavoidable, use `ObjectInputFilter` to allowlist expected classes.
- Limit deserialized payload sizes.

**BAD — unsafe Java deserialization:**
```kotlin
val ois = ObjectInputStream(inputStream)
val obj = ois.readObject()  // remote code execution risk
```

**GOOD — kotlinx.serialization:**
```kotlin
@Serializable
data class Payload(val userId: Long, val action: String)

val payload = Json.decodeFromString<Payload>(jsonString)
```

**GOOD — ObjectInputFilter if Java serialization is required:**
```kotlin
val filter = ObjectInputFilter.Config.createFilter(
    "com.example.SafeClass;java.lang.String;!*"
)
ObjectInputFilter.Config.setSerialFilter(filter)
```

---

## Cryptography

- Password hashing: use BCrypt (`spring-security-crypto`) — never MD5 or SHA-1.
- Random values: use `SecureRandom`, not `Random` or `kotlin.random.Random`.
- Do not implement custom cryptographic algorithms.
- Minimum TLS: 1.2 in production; prefer 1.3.

**BAD — weak hashing:**
```kotlin
val hash = MessageDigest.getInstance("MD5")
    .digest(password.toByteArray())
    .joinToString("") { "%02x".format(it) }
```

**GOOD — BCrypt:**
```kotlin
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder

val encoder = BCryptPasswordEncoder(12)
val hash = encoder.encode(password)
val matches = encoder.matches(rawPassword, hash)
```

**GOOD — secure random token:**
```kotlin
import java.security.SecureRandom
import java.util.Base64

fun generateToken(byteLength: Int = 32): String {
    val bytes = ByteArray(byteLength)
    SecureRandom().nextBytes(bytes)
    return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
}
```

---

## Authentication and Authorization

- Use Spring Security's `@PreAuthorize`, `@PostAuthorize`, or method-level security.
- Validate and verify JWTs — check `exp`, `iss`, `aud`, and signature.
- Stateless APIs: use `SessionCreationPolicy.STATELESS` and JWT or OAuth2.
- Re-authenticate for sensitive operations.

**BAD — JWT without signature verification:**
```kotlin
val parts = token.split(".")
val payload = String(Base64.decode(parts[1]))
val claims = Json.decodeFromString<Claims>(payload)
// signature never verified — forgeable
```

**GOOD — Spring Security + JJWT:**
```kotlin
val claims = Jwts.parserBuilder()
    .setSigningKey(secretKey)
    .build()
    .parseClaimsJws(token)
    .body
// throws if signature invalid or token expired
```

**GOOD — Spring Security config:**
```kotlin
@Configuration
class SecurityConfig : WebSecurityConfigurerAdapter() {
    override fun configure(http: HttpSecurity) {
        http
            .csrf().disable()  // stateless API — use CSRF tokens for browser forms
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .authorizeRequests()
            .antMatchers("/api/public/**").permitAll()
            .anyRequest().authenticated()
    }
}
```

---

## Open Redirect

**BAD — unvalidated redirect:**
```kotlin
@GetMapping("/redirect")
fun redirect(@RequestParam url: String): RedirectView {
    return RedirectView(url)  // attacker can redirect to malicious site
}
```

**GOOD — allowlist of redirect targets:**
```kotlin
val ALLOWED_HOSTS = setOf("example.com", "app.example.com")

@GetMapping("/redirect")
fun redirect(@RequestParam url: String): RedirectView {
    val host = URI(url).host ?: throw ResponseStatusException(HttpStatus.BAD_REQUEST)
    if (host !in ALLOWED_HOSTS) throw ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid redirect")
    return RedirectView(url)
}
```

---

## Coroutines and Concurrency

- Never share mutable state across coroutines without synchronization — use `Mutex` or `StateFlow`.
- Avoid `GlobalScope` — use structured concurrency with scoped coroutines.
- Cancel coroutines properly; resource cleanup should happen in `finally` or `use {}` blocks.

**BAD — shared mutable state:**
```kotlin
var counter = 0
repeat(1000) {
    GlobalScope.launch { counter++ }  // race condition
}
```

**GOOD — atomic or Mutex:**
```kotlin
val counter = AtomicInteger(0)
// or
val mutex = Mutex()
var counter = 0
repeat(1000) {
    launch { mutex.withLock { counter++ } }
}
```

---

## Null Safety

- Do not use `!!` (non-null assertion) on data derived from external input — it throws NPE at runtime.
- Use `?.let`, `?:`, or explicit null checks at system boundaries.
- Treat nullable return values from Java APIs as potentially null — do not force-unwrap.

**BAD — force unwrap:**
```kotlin
val user = userRepository.findById(id)!!  // NPE if not found
```

**GOOD — safe handling:**
```kotlin
val user = userRepository.findById(id)
    ?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "User not found")
```

---

## File Operations

- Validate file paths against a base directory before any operation.
- Validate file types by content (magic bytes), not just extension.
- Limit uploaded file sizes.

**BAD — path traversal:**
```kotlin
val file = File("/uploads/${filename}")  // "../../etc/passwd" traversal
```

**GOOD — canonicalize and check prefix:**
```kotlin
val base = File("/uploads").canonicalFile
val target = File(base, filename).canonicalFile
if (!target.path.startsWith(base.path + File.separator)) {
    throw SecurityException("Path traversal detected")
}
```

---

## Logging Security

- Never log passwords, tokens, credit card numbers, or PII.
- Use structured logging (SLF4J + Logback/Log4j2) — avoid string concatenation in log statements.
- Sanitize user input before logging to prevent log injection (remove newlines).

**BAD — logging secrets:**
```kotlin
logger.info("Login attempt: user=$username password=$password")
```

**GOOD — log only safe fields:**
```kotlin
logger.info("Login attempt: user={}", username)  // SLF4J parameterized
```

---

## Dependencies

- Run `mvn dependency-check:check` or `gradle dependencyCheckAnalyze` (OWASP) in CI.
- Keep Spring Boot, Kotlin stdlib, and security libraries updated — security patches are frequent.
- Use `gradle dependencyUpdates` or Renovate to track outdated dependencies.

**Tooling commands:**
```bash
./gradlew dependencyCheckAnalyze     # OWASP dependency check
./gradlew test                       # run test suite
./gradlew detekt                     # static analysis (Kotlin)
./mvnw versions:display-dependency-updates
```

---

## Anti-Patterns Table

| Anti-Pattern | Why It's Dangerous | Fix |
|-------------|-------------------|-----|
| `"SELECT ... WHERE x = '${x}'"` | SQL injection | Use parameterized queries |
| `ObjectInputStream.readObject()` | Remote code execution | Use kotlinx.serialization |
| `!!` on external data | NPE at runtime | Use `?: throw ...` |
| `Random()` for tokens | Predictable | Use `SecureRandom` |
| MD5/SHA-1 for passwords | Trivially cracked | Use BCrypt with cost ≥ 10 |
| Logging passwords or tokens | Credential leakage in logs | Log only non-sensitive identifiers |
| `RedirectView(userUrl)` without validation | Open redirect | Use host allowlist |
| `GlobalScope.launch` | Unstructured concurrency, leaks | Use scoped coroutines |
| `TypeNameHandling.ALL` in Jackson | Deserialization attack | Use explicit type mapping |
| JWT decoded but signature not verified | Forgeable tokens | Always verify with signing key |
