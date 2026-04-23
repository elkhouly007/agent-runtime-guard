# Java Security

Java-specific security rules.

## SQL Injection Prevention

- Always use `PreparedStatement` or `NamedParameterJdbcTemplate`. Never build SQL strings with string concatenation.
- With JPA/Hibernate: use JPQL with parameters, not native queries with string building.
- With Spring Data JPA: `@Query` annotations with `:parameter` placeholders are safe.

## Deserialization Safety

- Java object deserialization (`ObjectInputStream`) of untrusted data is critically dangerous — it executes arbitrary code.
- Implement `ObjectInputFilter` to whitelist only safe classes when deserialization is unavoidable.
- Prefer JSON (Jackson, Gson) or Protobuf over Java serialization for external data exchange.
- Jackson: disable `FAIL_ON_UNKNOWN_PROPERTIES` carefully — it can hide unexpected field injection.

## Authentication and Authorization

- Use a security framework (Spring Security, Apache Shiro) rather than implementing auth from scratch.
- Hash passwords with bcrypt, argon2, or PBKDF2. `MessageDigest.getInstance("MD5")` is not a password hash.
- CSRF protection enabled on all form-handling endpoints.
- Method-level security (`@PreAuthorize`) in addition to URL-level security.

## Dependency Security

- OWASP Dependency-Check plugin in Maven/Gradle CI pipeline.
- `dependabot` or `renovate` for automated dependency updates.
- Review transitive dependencies. The deepest vulnerability is often in a transitive dependency.

## Sensitive Data

- `char[]` instead of `String` for passwords in memory (Strings are immutable and persist in the heap).
- `Arrays.fill(password, '\0')` to zero out password arrays after use.
- Never log `HttpServletRequest` objects — they contain headers, cookies, and request bodies.
