# Skill: Spring Boot Verification Loops

## Trigger

Use when:
- Completing a feature or bug fix before opening a PR
- Before deploying to staging or production
- After adding dependencies, migrations (Flyway/Liquibase), or actuator endpoints
- Setting up CI for a Spring Boot project
- Diagnosing startup failures or health check degradation

## Process

### 1. mvn test — Run the Test Suite

```bash
# Run all tests
mvn test

# Run a specific test class
mvn test -Dtest=OrderServiceTest

# Run a specific method
mvn test -Dtest=OrderServiceTest#placeOrder_validItems_savesAndPublishesEvent

# Run with a specific profile
mvn test -Dspring.profiles.active=test

# Skip tests (deployment only — never skip in CI)
mvn install -DskipTests
```

### 2. mvn verify — Full Build with Integration Tests

```bash
# Runs unit tests, integration tests, and all plugin checks (JaCoCo, SpotBugs, etc.)
mvn verify

# With a specific profile
mvn verify -Pintegration-tests

# Fail fast on first error
mvn verify --fail-at-end

# Output test results summary
mvn verify -Dsurefire.failIfNoSpecifiedTests=false
```

Typical `pom.xml` plugin configuration:
```xml
<build>
    <plugins>
        <!-- Surefire: unit tests -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.2.5</version>
            <configuration>
                <excludes>
                    <exclude>**/*IT.java</exclude>
                </excludes>
            </configuration>
        </plugin>

        <!-- Failsafe: integration tests (*IT.java) -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-failsafe-plugin</artifactId>
            <version>3.2.5</version>
            <executions>
                <execution>
                    <goals>
                        <goal>integration-test</goal>
                        <goal>verify</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

### 3. SpotBugs — Static Bug Analysis

```xml
<!-- pom.xml -->
<plugin>
    <groupId>com.github.spotbugs</groupId>
    <artifactId>spotbugs-maven-plugin</artifactId>
    <version>4.8.4.0</version>
    <configuration>
        <effort>Max</effort>
        <threshold>Low</threshold>
        <failOnError>true</failOnError>
        <excludeFilterFile>spotbugs-exclude.xml</excludeFilterFile>
    </configuration>
    <executions>
        <execution>
            <goals><goal>check</goal></goals>
        </execution>
    </executions>
</plugin>
```

```bash
# Run SpotBugs
mvn spotbugs:check

# Generate HTML report
mvn spotbugs:spotbugs
open target/spotbugsXml.xml
```

```xml
<!-- spotbugs-exclude.xml — exclude generated code -->
<FindBugsFilter>
    <Match>
        <Class name="~com\.example\.generated\..*" />
    </Match>
    <Match>
        <Bug pattern="EI_EXPOSE_REP,EI_EXPOSE_REP2" />
        <Class name="~com\.example\.dto\..*" />
    </Match>
</FindBugsFilter>
```

### 4. Checkstyle — Code Style Enforcement

```xml
<!-- pom.xml -->
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-checkstyle-plugin</artifactId>
    <version>3.3.1</version>
    <configuration>
        <configLocation>google_checks.xml</configLocation>
        <failsOnError>true</failsOnError>
        <includeTestSourceDirectory>true</includeTestSourceDirectory>
    </configuration>
    <executions>
        <execution>
            <goals><goal>check</goal></goals>
        </execution>
    </executions>
</plugin>
```

```bash
mvn checkstyle:check
mvn checkstyle:checkstyle   # generates HTML report in target/site/checkstyle.html
```

### 5. OWASP Dependency Check

```xml
<!-- pom.xml -->
<plugin>
    <groupId>org.owasp</groupId>
    <artifactId>dependency-check-maven</artifactId>
    <version>9.2.0</version>
    <configuration>
        <failBuildOnCVSS>7</failBuildOnCVSS>
        <suppressionFile>dependency-check-suppressions.xml</suppressionFile>
        <nvdApiKey>${env.NVD_API_KEY}</nvdApiKey>
    </configuration>
    <executions>
        <execution>
            <goals><goal>check</goal></goals>
        </execution>
    </executions>
</plugin>
```

```bash
mvn dependency-check:check

# Generate full HTML report
mvn dependency-check:aggregate
open target/dependency-check-report.html
```

### 6. Actuator Health Endpoints

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
      base-path: /actuator
  endpoint:
    health:
      show-details: when-authorized  # or 'always' for internal apps
  health:
    db:
      enabled: true
    diskspace:
      enabled: true
    redis:
      enabled: true
```

```bash
# Check health
curl -s http://localhost:8080/actuator/health | jq .

# Expected output
{
  "status": "UP",
  "components": {
    "db": {"status": "UP"},
    "diskSpace": {"status": "UP"},
    "redis": {"status": "UP"}
  }
}
```

Custom health indicator:
```java
@Component
public class ExternalApiHealthIndicator implements HealthIndicator {

    private final ExternalApiClient apiClient;

    @Override
    public Health health() {
        try {
            apiClient.ping();
            return Health.up().withDetail("external-api", "reachable").build();
        } catch (Exception e) {
            return Health.down()
                .withDetail("external-api", "unreachable")
                .withException(e)
                .build();
        }
    }
}
```

### 7. Flyway Migration Validation

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.flywaydb</groupId>
    <artifactId>flyway-core</artifactId>
</dependency>
```

```yaml
# application.yml
spring:
  flyway:
    enabled: true
    locations: classpath:db/migration
    validate-on-migrate: true
    baseline-on-migrate: false
    out-of-order: false
```

```bash
# Check migration status via Flyway Maven plugin
mvn flyway:info -Dflyway.url=${DATABASE_URL} -Dflyway.user=${DB_USER} -Dflyway.password=${DB_PASS}

# Validate checksums of applied migrations
mvn flyway:validate
```

Migration naming convention:
```
src/main/resources/db/migration/
├── V1__create_users_table.sql
├── V2__create_orders_table.sql
├── V3__add_order_status_index.sql
└── R__create_order_summary_view.sql   # repeatable migration
```

Never modify an already-applied migration — add a new one instead.

### 8. @SpringBootTest Startup Smoke Test

```java
// src/test/java/com/example/ApplicationContextTest.java
@SpringBootTest
@ActiveProfiles("test")
class ApplicationContextTest {

    @Test
    void contextLoads() {
        // Fails if any bean fails to initialize
        // This is the minimum smoke test for every Spring Boot app
    }

    @Autowired
    private OrderController orderController;

    @Test
    void orderControllerBeanIsPresent() {
        assertThat(orderController).isNotNull();
    }
}
```

### 9. Integration Test Profile

```yaml
# src/test/resources/application-test.yml
spring:
  datasource:
    url: ${TEST_DATABASE_URL:jdbc:tc:postgresql:16:///testdb}
  flyway:
    enabled: true
  jpa:
    show-sql: true

security:
  jwt:
    secret: dGVzdC1zZWNyZXQta2V5LWZvci10ZXN0aW5nLW9ubHk=
    expiration-ms: 3600000

logging:
  level:
    org.springframework.security: DEBUG
    org.hibernate.SQL: DEBUG
```

### 10. Full Pre-PR Verification Script

```bash
#!/bin/bash
set -e

echo "=== Compile ==="
mvn compile -q

echo "=== Checkstyle ==="
mvn checkstyle:check -q

echo "=== Unit Tests ==="
mvn test -q

echo "=== Integration Tests + JaCoCo ==="
mvn verify -Pintegration-tests -q

echo "=== SpotBugs ==="
mvn spotbugs:check -q

echo "=== OWASP Dependency Check ==="
mvn dependency-check:check -q

echo "=== Actuator Smoke Test ==="
mvn spring-boot:run &
APP_PID=$!
sleep 10
curl -sf http://localhost:8080/actuator/health | jq -e '.status == "UP"'
kill $APP_PID

echo "=== All checks passed ==="
```

### 11. CI Integration (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports: ["5432:5432"]

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          java-version: '21'
          distribution: 'temurin'
          cache: 'maven'

      - name: Checkstyle
        run: mvn checkstyle:check -q

      - name: Unit + Integration Tests with Coverage
        run: mvn verify -Pintegration-tests
        env:
          TEST_DATABASE_URL: jdbc:postgresql://localhost:5432/testdb
          TEST_DATABASE_USERNAME: test
          TEST_DATABASE_PASSWORD: test

      - name: SpotBugs
        run: mvn spotbugs:check -q

      - name: OWASP Dependency Check
        run: mvn dependency-check:check
        env:
          NVD_API_KEY: ${{ secrets.NVD_API_KEY }}

      - name: Upload Coverage Report
        uses: actions/upload-artifact@v4
        with:
          name: jacoco-report
          path: target/site/jacoco/
```

### 12. Gradle Equivalent Commands

```bash
# Run tests
./gradlew test

# Run verification (tests + checks)
./gradlew check

# SpotBugs
./gradlew spotbugsMain

# OWASP
./gradlew dependencyCheckAnalyze

# JaCoCo report
./gradlew jacocoTestReport jacocoTestCoverageVerification
```

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| Only running `mvn test` in CI | Misses integration tests, JaCoCo check, SpotBugs | Use `mvn verify` |
| Modifying applied Flyway migrations | Checksum mismatch, failed deployments | Always add new migration |
| Exposing all Actuator endpoints without auth | Internal data leak | Restrict with `management.endpoints.web.exposure.include` |
| H2 in-memory DB for all tests | Misses PostgreSQL behavior | TestContainers for integration tests |
| No `contextLoads()` smoke test | Startup failures not caught until runtime | Add `ApplicationContextTest` |
| `failBuildOnCVSS` threshold above 9 | Ships known high-severity CVEs | Set threshold to 7 or lower |

## Safe Behavior

- `mvn verify` (not just `mvn test`) runs in CI on every PR.
- Flyway `validate-on-migrate: true` is always enabled — mismatched checksums fail deployment.
- Actuator endpoints are restricted to internal networks in production (`management.server.port=9090`).
- JaCoCo minimum coverage threshold is enforced; build fails if coverage drops below 85%.
- OWASP dependency check runs weekly via scheduled CI job and on every PR.
- `contextLoads()` test exists in every Spring Boot project — CI catches misconfigured beans before deployment.
