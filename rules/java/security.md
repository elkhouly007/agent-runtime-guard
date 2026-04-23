---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Java Security Rules

## OWASP Coverage

| OWASP Category | Java Risk | Fix |
|---|---|---|
| A01 Broken Access Control | Missing `@PreAuthorize` on sensitive endpoints | Annotate every method; deny by default |
| A02 Cryptographic Failures | MD5/SHA-1 for passwords; `Random` for tokens | BCrypt + `SecureRandom` |
| A03 Injection | String-concatenated SQL or JPQL | `PreparedStatement` / named parameters |
| A04 Insecure Design | Business logic bypass via parameter tampering | Validate on the server; never trust client state |
| A05 Security Misconfiguration | CSRF disabled; actuator endpoints exposed | Enable CSRF; restrict actuator to internal network |
| A08 Insecure Deserialization | `ObjectInputStream` with untrusted data | Use JSON; apply `ObjectInputFilter` |
| A06 Vulnerable Components | Outdated Spring Boot / transitive deps | `dependency-check:check` in CI |

---

## Input Validation

Validate at the controller boundary with Bean Validation — never in the service layer alone.

```java
// BAD — raw parameter bound directly to domain logic, no validation
@PostMapping("/users")
public ResponseEntity<User> create(@RequestBody Map<String, Object> body) {
    String name = (String) body.get("name");   // untyped, unvalidated
    return ResponseEntity.ok(userService.create(name));
}

// GOOD — typed DTO with Bean Validation, controller stays thin
public record CreateUserRequest(
    @NotBlank @Size(max = 100) String name,
    @Email @NotBlank String email,
    @NotNull Role role
) {}

@PostMapping("/users")
public ResponseEntity<User> create(@Valid @RequestBody CreateUserRequest req) {
    return ResponseEntity.status(201).body(userService.create(req));
}
```

- Reject oversized payloads at the server level (`spring.servlet.multipart.max-file-size`).
- Use allowlists for enum-like values — reject anything not in the set.
- Sanitize HTML output with OWASP Java HTML Sanitizer if user content is rendered.

---

## SQL Injection Prevention

```java
// BAD — SQL injection via concatenation
String query = "SELECT * FROM users WHERE name = '" + name + "'";
Statement stmt = conn.createStatement();
ResultSet rs = stmt.executeQuery(query);

// BAD — format string is equally unsafe
String query = String.format("SELECT * FROM users WHERE role = '%s'", role);

// GOOD — PreparedStatement with positional parameter
String sql = "SELECT * FROM users WHERE name = ?";
try (PreparedStatement stmt = conn.prepareStatement(sql)) {
    stmt.setString(1, name);
    ResultSet rs = stmt.executeQuery();
    // ...
}

// GOOD — JPA named parameter (prevents injection in JPQL too)
TypedQuery<User> query = em.createQuery(
    "SELECT u FROM User u WHERE u.email = :email", User.class
);
query.setParameter("email", email);
List<User> users = query.getResultList();

// GOOD — Spring Data JPA (safest; generated SQL is parameterized)
List<User> users = userRepository.findByEmail(email);
```

Never build SQL or JPQL with `String.format`, `+` concatenation, or `String.join` with user input.

---

## Deserialization

```java
// BAD — ObjectInputStream accepts any class; gadget chains can RCE
ObjectInputStream ois = new ObjectInputStream(inputStream);
Object obj = ois.readObject();   // arbitrary code execution risk

// GOOD — ObjectInputFilter allowlist (Java 9+)
ObjectInputStream ois = new ObjectInputStream(inputStream);
ois.setObjectInputFilter(info -> {
    Class<?> cls = info.serialClass();
    if (cls == null) return ObjectInputFilter.Status.UNDECIDED;
    if (cls == MyExpectedClass.class) return ObjectInputFilter.Status.ALLOWED;
    return ObjectInputFilter.Status.REJECTED;
});

// BEST — use JSON with explicit type mapping; avoid Java serialization entirely
ObjectMapper mapper = new ObjectMapper();
mapper.activateDefaultTyping(
    mapper.getPolymorphicTypeValidator(),
    ObjectMapper.DefaultTyping.NONE   // disables polymorphic type handling
);
MyDto dto = mapper.readValue(jsonInput, MyDto.class);
```

---

## Cryptography

```java
// BAD — MD5 for passwords; broken hash, no salt
String hashed = DigestUtils.md5Hex(password);

// BAD — SHA-1 is also broken for passwords
MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
byte[] hash = sha1.digest(password.getBytes());

// GOOD — BCrypt via Spring Security (work factor auto-tuned)
PasswordEncoder encoder = new BCryptPasswordEncoder(12);  // cost factor 12
String hashed = encoder.encode(rawPassword);
boolean matches = encoder.matches(rawPassword, hashed);

// BAD — java.util.Random for tokens (predictable)
String token = Integer.toHexString(new Random().nextInt());

// GOOD — SecureRandom for cryptographic tokens
byte[] tokenBytes = new byte[32];
new SecureRandom().nextBytes(tokenBytes);
String token = Base64.getUrlEncoder().withoutPadding().encodeToString(tokenBytes);
```

- Never store secrets in `application.properties` committed to version control.
- Load from environment variables or a secrets manager (Vault, AWS Secrets Manager).
- Use AWS SDK / GCP Secret Manager client libraries for cloud deployments.

---

## Spring Boot Security

```java
// BAD — CSRF disabled, all paths open, session not configured
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http.csrf().disable()
        .authorizeHttpRequests(auth -> auth.anyRequest().permitAll());
    return http.build();
}

// GOOD — CSRF on for browser clients; method-level authorization; stateless for APIs
@Bean
public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    http
        .csrf(csrf -> csrf
            .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
        )
        .sessionManagement(session -> session
            .sessionCreationPolicy(SessionCreationPolicy.STATELESS)  // for REST APIs
        )
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/public/**").permitAll()
            .requestMatchers("/actuator/health").permitAll()
            .requestMatchers("/actuator/**").hasRole("ADMIN")
            .anyRequest().authenticated()
        )
        .oauth2ResourceServer(oauth2 -> oauth2.jwt(Customizer.withDefaults()));
    return http.build();
}

// Method-level security — deny by default, allow explicitly
@PreAuthorize("hasRole('ADMIN')")
public void deleteUser(Long userId) { ... }

@PreAuthorize("hasRole('USER') and #userId == authentication.principal.id")
public UserProfile getProfile(Long userId) { ... }
```

- Enable `@EnableMethodSecurity` on your `@Configuration` class.
- Validate and allowlist redirect URLs — open redirect lets attackers phish via your domain.
- Set `Strict-Transport-Security`, `X-Content-Type-Options`, `X-Frame-Options` headers.

---

## File Operations

```java
// BAD — path traversal: ../../etc/passwd
Path file = Paths.get("/app/uploads/" + filename);
byte[] data = Files.readAllBytes(file);

// GOOD — canonicalize and verify inside base directory
Path base = Path.of("/app/uploads").toRealPath();
Path requested = base.resolve(filename).normalize();
if (!requested.startsWith(base)) {
    throw new SecurityException("Path traversal attempt: " + filename);
}
byte[] data = Files.readAllBytes(requested);

// Validate file type by magic bytes, not extension
byte[] header = Arrays.copyOf(data, 4);
if (!Arrays.equals(header, new byte[]{(byte)0xFF, (byte)0xD8, (byte)0xFF, (byte)0xE0})) {
    throw new IllegalArgumentException("File is not a JPEG");
}
```

- Limit upload size with `spring.servlet.multipart.max-file-size=10MB`.
- Never execute uploaded files.

---

## Dependency Scanning

```bash
# OWASP Dependency-Check — scan for CVEs in Maven dependencies
mvn org.owasp:dependency-check-maven:check

# Fail the build if CVSS score >= 7 (high severity)
mvn dependency-check:check -DfailBuildOnCVSS=7

# Gradle equivalent
./gradlew dependencyCheckAnalyze

# List dependency tree to audit transitive deps
mvn dependency:tree

# Check for updates (spotting outdated, potentially vulnerable versions)
mvn versions:display-dependency-updates
```

Run `dependency-check:check` in CI on every PR. Fail the build on CVSS ≥ 7.

---

## Anti-Patterns

| Anti-pattern | Risk | Fix |
|---|---|---|
| String-concatenated SQL | SQL injection → data breach | `PreparedStatement` / named params |
| `ObjectInputStream` without filter | Remote code execution via gadget chain | Use JSON; add `ObjectInputFilter` allowlist |
| `csrf().disable()` on browser app | CSRF attacks against authenticated users | Enable CSRF with `CookieCsrfTokenRepository` |
| MD5/SHA-1 for passwords | Rainbow table cracking | BCrypt with cost factor ≥ 10 |
| `java.util.Random` for tokens | Predictable; session hijacking | `SecureRandom` + 256-bit entropy |
| Secrets in `application.properties` | Credentials in version control | Environment variables / Vault |
| `anyRequest().permitAll()` | All endpoints exposed without auth | Deny by default; explicit `permitAll` allowlist |
| Missing `@Valid` on `@RequestBody` | Bean Validation annotations ignored silently | Always pair `@Valid` with `@RequestBody` |
| Path traversal in file upload | Arbitrary file read/write | Canonicalize and verify path against base dir |
| Actuator endpoints exposed publicly | System info leak; `/shutdown` DoS | Restrict `/actuator/**` to `ADMIN` role |
