---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Database Security

Security rules for database design and access.

## Parameterized Queries

Never interpolate values into SQL strings. Always use parameterized queries or ORMs that handle this:

```sql
-- Application layer (pseudocode)
-- BAD: "SELECT * FROM users WHERE email = '" + email + "'"
-- GOOD: prepare("SELECT * FROM users WHERE email = $1"), [email]
```

## Least-Privilege Access

- Application accounts have only the permissions they need: SELECT/INSERT/UPDATE on specific tables.
- No application account has DDL privileges (CREATE, DROP, ALTER) in production.
- Separate read-only accounts for reporting and analytics.
- Service accounts, not personal developer accounts, connect to production.

## Credential Management

- Database passwords in a secrets manager (Vault, AWS Secrets Manager). Rotate on schedule.
- Connection strings never in application source code or version control.
- Environment variables for connection details, with secrets injected at deploy time.

## Encryption

- Encryption at rest: enable tablespace/filesystem encryption for sensitive databases.
- Encryption in transit: TLS connections required between application and database.
- Column-level encryption for PII fields using application-layer encryption before storage (not just DB-layer).

## Sensitive Data

- Hash passwords with a proper KDF (Argon2id, bcrypt) before storing. Never store plaintext passwords.
- Mask or truncate PII in logs, query logs, and error messages.
- Classify columns: public, internal, confidential, restricted. Apply controls accordingly.

## Audit Logging

- Log all authentication events: success and failure.
- Log all DDL changes in production.
- Log access to sensitive tables (payment data, health records, credentials).
- Audit logs written to a separate store not accessible from the application account.

## Injection Defense in Stored Procedures

- Stored procedures using dynamic SQL must still use `EXECUTE ... USING` with parameters.
- Validate input type and length before constructing dynamic queries.
