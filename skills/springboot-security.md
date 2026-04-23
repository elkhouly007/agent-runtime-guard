# Skill: Spring Boot Security

## Trigger

Use when:
- Securing a new or existing Spring Boot application
- Adding JWT authentication or OAuth2 resource server
- Configuring method-level security or role-based access
- Setting up CORS for a frontend SPA
- Reviewing code for OWASP vulnerabilities
- Deploying to production and hardening the security posture

## Process

### 1. Spring Security — SecurityFilterChain

Spring Security 6.x uses `SecurityFilterChain` beans (not `WebSecurityConfigurerAdapter`):

```java
// config/SecurityConfig.java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity   // enables @PreAuthorize, @PostAuthorize
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())                    // stateless JWT — disable CSRF
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers("/actuator/health").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/products/**").permitAll()
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder(12);
    }
}
```

### 2. JWT Authentication

```java
// security/JwtService.java
@Service
public class JwtService {

    @Value("${security.jwt.secret}")
    private String secretKey;

    @Value("${security.jwt.expiration-ms:3600000}")
    private long expirationMs;

    public String generateToken(UserDetails userDetails) {
        return Jwts.builder()
            .subject(userDetails.getUsername())
            .issuedAt(new Date())
            .expiration(new Date(System.currentTimeMillis() + expirationMs))
            .signWith(getSigningKey(), Jwts.SIG.HS256)
            .compact();
    }

    public String extractUsername(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    public boolean isTokenValid(String token, UserDetails userDetails) {
        final String username = extractUsername(token);
        return username.equals(userDetails.getUsername()) && !isTokenExpired(token);
    }

    private boolean isTokenExpired(String token) {
        return extractClaim(token, Claims::getExpiration).before(new Date());
    }

    private <T> T extractClaim(String token, Function<Claims, T> resolver) {
        Claims claims = Jwts.parser()
            .verifyWith(getSigningKey())
            .build()
            .parseSignedClaims(token)
            .getPayload();
        return resolver.apply(claims);
    }

    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secretKey);
        return Keys.hmacShaKeyFor(keyBytes);
    }
}
```

```java
// security/JwtAuthFilter.java
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain)
            throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }

        final String token = authHeader.substring(7);
        final String username = jwtService.extractUsername(token);

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            UserDetails user = userDetailsService.loadUserByUsername(username);
            if (jwtService.isTokenValid(token, user)) {
                UsernamePasswordAuthenticationToken authToken =
                    new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        chain.doFilter(request, response);
    }
}
```

### 3. Method-Level Security (@PreAuthorize)

```java
@Service
@RequiredArgsConstructor
public class OrderService {

    @PreAuthorize("isAuthenticated()")
    public List<Order> getMyOrders(Long userId) {
        return orderRepository.findByUserId(userId);
    }

    @PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.id")
    public Order getOrder(Long userId, Long orderId) {
        return orderRepository.findByIdAndUserId(orderId, userId)
            .orElseThrow(() -> new ResourceNotFoundException("Order not found"));
    }

    @PreAuthorize("hasAuthority('REFUND_ISSUE')")
    public void issueRefund(Long orderId, BigDecimal amount) {
        // ...
    }

    @PostAuthorize("returnObject.userId == authentication.principal.id")
    public Order findOrder(Long orderId) {
        return orderRepository.findById(orderId)
            .orElseThrow(() -> new ResourceNotFoundException("Order not found"));
    }
}
```

### 4. Password Encoding (BCrypt)

```java
// Never store plain text passwords
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new UserAlreadyExistsException("Email already registered");
        }

        User user = User.builder()
            .email(request.getEmail())
            .password(passwordEncoder.encode(request.getPassword()))  // BCrypt hash
            .role(Role.USER)
            .build();

        userRepository.save(user);
        return new AuthResponse(jwtService.generateToken(user));
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
            .orElseThrow(() -> new BadCredentialsException("Invalid credentials"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("Invalid credentials");
        }

        return new AuthResponse(jwtService.generateToken(user));
    }
}
```

### 5. CORS Configuration

```java
// config/CorsConfig.java
@Configuration
public class CorsConfig {

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of(
            "https://app.example.com",
            "https://www.example.com"
        ));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-Requested-With"));
        config.setExposedHeaders(List.of("X-Total-Count"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }
}
```

In `SecurityFilterChain`:
```java
.cors(cors -> cors.configurationSource(corsConfigurationSource))
```

### 6. CSRF (Stateful Apps)

For traditional server-side rendered apps using sessions, keep CSRF enabled:

```java
http
    .csrf(csrf -> csrf
        .csrfTokenRepository(CookieCsrfTokenRepository.withHttpOnlyFalse())
        .ignoringRequestMatchers("/api/webhooks/**")  // Webhook endpoints with HMAC auth
    )
```

For REST APIs with JWT (stateless): disable CSRF as shown in section 1.

### 7. OAuth2 Resource Server

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

```yaml
# application.yml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://auth.example.com
          jwk-set-uri: https://auth.example.com/.well-known/jwks.json
```

```java
http
    .oauth2ResourceServer(oauth2 -> oauth2
        .jwt(jwt -> jwt.jwtAuthenticationConverter(jwtAuthConverter()))
    );
```

### 8. Secrets Management — Environment Variables and Vault

```yaml
# application.yml — reference env vars, never hardcode
security:
  jwt:
    secret: ${JWT_SECRET}
    expiration-ms: ${JWT_EXPIRATION_MS:3600000}

spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USERNAME}
    password: ${DATABASE_PASSWORD}
```

Spring Vault integration:
```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-vault-config</artifactId>
</dependency>
```

```yaml
# bootstrap.yml
spring:
  cloud:
    vault:
      uri: https://vault.example.com
      authentication: KUBERNETES
      kubernetes:
        role: myapp-role
        kubernetes-path: kubernetes
```

### 9. OWASP Coverage Summary

| OWASP Risk | Spring Boot Control |
|---|---|
| A01 Broken Access Control | `@PreAuthorize`, `SecurityFilterChain` rules |
| A02 Cryptographic Failures | `BCryptPasswordEncoder(12)`, TLS, JWT HS256/RS256 |
| A03 Injection | Spring Data JPA, `@Param` in JPQL, never `String.format` in queries |
| A04 Insecure Design | Service layer, validated DTOs, no logic in controllers |
| A05 Misconfiguration | Actuator endpoints secured, debug disabled in prod |
| A07 Auth Failures | JWT expiry, stateless sessions, no plain-text passwords |
| A09 Logging | Audit logs via Spring Security events, no passwords in logs |

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| `WebSecurityConfigurerAdapter` (Spring 5 style) | Deprecated, removed in Spring 6 | Use `SecurityFilterChain` bean |
| `PasswordEncoder` with MD5/SHA1 | Trivially crackable | Use `BCryptPasswordEncoder(12)` |
| Hardcoded JWT secret in `application.yml` | Key exposure via VCS | Use env var / Vault |
| `permitAll()` on all requests, auth in controller | Bypass risk | Secure at filter chain level |
| `@PreAuthorize` without `@EnableMethodSecurity` | Annotations silently ignored | Always add annotation to config class |
| `CORS: allowedOrigins("*")` with `allowCredentials(true)` | Security violation | Enumerate exact origins |
| Returning stack traces in error responses | Information leakage | Custom `@ControllerAdvice` error handler |

## Safe Behavior

- JWT secrets are minimum 256 bits, stored in env vars or Vault — never in code or properties files.
- `BCryptPasswordEncoder` with strength 10–12 is the only acceptable password encoder.
- Actuator endpoints (`/actuator/*`) are restricted to internal networks or require admin auth.
- `@EnableMethodSecurity` is present when any `@PreAuthorize` annotations are used — verify with a test.
- CORS `allowedOrigins` enumerates exact domains — wildcard is never used with `allowCredentials(true)`.
- Run OWASP dependency check in CI before every merge to main.
