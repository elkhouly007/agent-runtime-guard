---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Java + ARG Hooks

Java-specific ARG hook considerations.

## Build Tool Commands

Java project commands that may trigger ARG:
- `mvn exec:exec` and `gradle exec` with shell commands: execute arbitrary processes
- `mvn deploy` and `gradle publish`: publish artifacts to repositories, confirm the target
- Build scripts that invoke shell with string-constructed commands

## Secret Locations in Java Projects

Java projects commonly store secrets in:
- `application.properties` or `application.yml` (database passwords, API keys)
- `.env` files loaded by libraries like `dotenv-java`
- Spring Cloud Config Server connections (may expose all environment config)
- `~/.m2/settings.xml` or `~/.gradle/gradle.properties` (repository credentials)

ARG will intercept any of these if they appear in Bash tool call inputs. Use Spring Cloud Vault, HashiCorp Vault, or AWS Secrets Manager for production secrets.

## Docker and Container Commands

Java services often run in containers. Commands that may trigger ARG:
- `docker exec` into containers with production data
- `kubectl exec` into production pods
- Database migration commands (`flyway migrate`, `liquibase update`) in non-sandbox environments

## Test Database Safety

Integration tests with real databases via TestContainers are safe — they run in isolated containers. Direct connections to shared databases from test scripts are not safe and may trigger ARG policy review.
