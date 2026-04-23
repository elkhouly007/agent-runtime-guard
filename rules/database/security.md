---
last_reviewed: 2026-04-20
version_target: "PostgreSQL 16, MySQL 8, SQLite 3.45"
upstream_ref: "source-README.md"
---

# Database Security

## SQL Injection Prevention

**Always use parameterized queries or prepared statements. Never concatenate user input into SQL.**

```sql
-- BAD — string concatenation: SQL injection risk
query = "SELECT * FROM users WHERE email = '" + user_input + "'";
-- Attacker input: ' OR '1'='1 — returns all rows

-- GOOD — parameterized (PostgreSQL $N style)
SELECT * FROM users WHERE email = $1;
-- Pass [user_input] as parameter array

-- GOOD — named parameters (SQLAlchemy / Python)
session.execute(
    text("SELECT * FROM users WHERE email = :email"),
    {"email": user_input}
)

-- GOOD — ORM (avoids raw SQL entirely)
User.objects.filter(email=user_input)        # Django
User.query.filter_by(email=user_input).first()  # SQLAlchemy
```

```go
// BAD — Go: fmt.Sprintf into query
query := fmt.Sprintf("SELECT * FROM users WHERE id = %s", userID)
db.Query(query)

// GOOD — Go: parameterized
db.QueryRow("SELECT * FROM users WHERE id = $1", userID)
```

```java
// BAD — Java: concatenation
String sql = "SELECT * FROM users WHERE email = '" + email + "'";
stmt.execute(sql);

// GOOD — Java: PreparedStatement
PreparedStatement ps = conn.prepareStatement(
    "SELECT * FROM users WHERE email = ?"
);
ps.setString(1, email);
ps.executeQuery();
```

## Connection Security

```yaml
# BAD — plaintext password in config file committed to repo
database:
  host: db.prod.internal
  password: s3cr3tpassword

# GOOD — environment variable reference
database:
  host: ${DB_HOST}
  password: ${DB_PASSWORD}
  sslmode: require          # always require TLS in production
```

- Never commit connection strings to source control.
- Use `sslmode=require` (PostgreSQL) or `ssl=true` (MySQL) for all production connections.
- Rotate database passwords on schedule and immediately after any exposure.
- Use separate credentials per service — never share a single DB user across multiple apps.

## Privilege Minimization

```sql
-- BAD — application uses superuser or owner account
GRANT ALL PRIVILEGES ON DATABASE myapp TO app_user;

-- GOOD — minimum required permissions only
GRANT SELECT, INSERT, UPDATE ON users, orders, products TO app_user;
GRANT DELETE ON sessions TO app_user;   -- only tables that need DELETE
-- Never grant DROP, TRUNCATE, CREATE, or ALTER to the application user

-- GOOD — read-only replica user
CREATE USER readonly_user WITH PASSWORD '...';
GRANT CONNECT ON DATABASE myapp TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

- Application database user must NEVER have `CREATE`, `DROP`, `ALTER`, or `TRUNCATE` privileges.
- Migration scripts should run as a separate privileged migration user, not the app user.
- Use separate read-only users for analytics and reporting queries.

## Migration Safety

```sql
-- BAD — irreversible migration with no rollback plan
DROP COLUMN user_ssn;  -- data is permanently gone

-- GOOD — soft-delete pattern: deprecate first, drop later
ALTER TABLE users RENAME COLUMN user_ssn TO _deprecated_user_ssn;
-- Release, verify no code reads it, then drop in a later migration

-- BAD — blocking NOT NULL addition on a large table
ALTER TABLE events ADD COLUMN processed BOOLEAN NOT NULL DEFAULT FALSE;
-- This rewrites every row and locks the table

-- GOOD — add nullable, backfill, then constrain
ALTER TABLE events ADD COLUMN processed BOOLEAN;
UPDATE events SET processed = FALSE WHERE processed IS NULL;   -- in batches if large
ALTER TABLE events ALTER COLUMN processed SET NOT NULL;
ALTER TABLE events ALTER COLUMN processed SET DEFAULT FALSE;
```

- Every migration must have a tested rollback migration.
- Never run destructive migrations (DROP COLUMN, DROP TABLE) directly — rename first, monitor, then drop.
- Batch large UPDATE/DELETE operations to avoid lock escalation: `WHERE id BETWEEN X AND Y`.
- Test migrations against a production-size data snapshot before running in production.

## Secrets in Backups and Logs

```sql
-- BAD — logging sensitive values
SET log_min_duration_statement = 0;  -- logs ALL queries including parameter values
-- PostgreSQL will log: SELECT * FROM users WHERE password = 'actualpassword'

-- GOOD — log only slow queries, and mask parameters
SET log_min_duration_statement = 1000;   -- log queries > 1s only
-- Use pg_stat_statements for aggregated stats without parameter values
```

- Ensure database backups are encrypted at rest.
- Restrict access to backup files — they contain all data including hashed passwords.
- Audit log access: enable `pgaudit` (PostgreSQL) or MySQL's audit log for compliance.

## Tooling Commands

```bash
# PostgreSQL: check for public schema exposure
psql -c "\dn+"

# PostgreSQL: audit user privileges
psql -c "\du"
psql -c "SELECT grantee, privilege_type FROM information_schema.role_table_grants WHERE table_name='users';"

# Check for SQL injection patterns in codebase
grep -rn "query.*+.*request\|execute.*+.*param\|format.*SELECT" src/

# SQLite: check for unencrypted sensitive columns
sqlite3 db.sqlite3 ".schema" | grep -i "password\|secret\|token\|ssn"

# MySQL: list accounts with excessive privileges
SELECT user, host, Super_priv, Grant_priv FROM mysql.user WHERE Super_priv='Y' OR Grant_priv='Y';
```

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| String concatenation in SQL | SQL injection | Parameterized queries |
| Superuser as app DB user | Full DB compromise | Principle of least privilege |
| Plaintext passwords in config | Credential exposure | Environment variables + vault |
| No `sslmode=require` | MITM on DB connection | Enforce TLS |
| Irreversible migrations | Data loss | Rename-then-drop pattern |
| Logging all query params | Secrets in logs | Log only slow queries |
| Shared DB credentials across services | Lateral movement | One credential per service |
| No backup encryption | Data breach via backup | Encrypt at rest |
