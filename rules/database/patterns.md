---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Database Patterns

## Schema Design

- Use surrogate primary keys (`id BIGSERIAL` or `id UUID`) — avoid natural keys (email, phone, username) as PKs.
- Use `UUID` for PKs that will be exposed in APIs — avoids enumeration attacks. Use `BIGSERIAL` for internal-only tables where join performance matters.
- Every table needs `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`. Add `updated_at` for mutable rows.
- Soft-delete with a `deleted_at TIMESTAMPTZ` column when row history matters — avoid hard deletes on business data.
- Name foreign key columns as `{table_singular}_id` (e.g., `user_id`, `order_id`).
- Use `NOT NULL` by default — only allow `NULL` when absence is semantically meaningful and you have a plan for handling it.

## Migration Safety

```sql
-- BAD — locks the table for every existing row
ALTER TABLE users ADD COLUMN preferences JSONB NOT NULL DEFAULT '{}';

-- GOOD — add nullable first, then backfill, then set NOT NULL
ALTER TABLE users ADD COLUMN preferences JSONB;
UPDATE users SET preferences = '{}' WHERE preferences IS NULL;
ALTER TABLE users ALTER COLUMN preferences SET NOT NULL;
ALTER TABLE users ALTER COLUMN preferences SET DEFAULT '{}';
```

- Never add a `NOT NULL` column without a default to a table with existing rows — it will lock the table (PostgreSQL < 11) or fail.
- Migrations are irreversible in production — write a rollback migration for every migration.
- Never rename columns or tables in a single step on a live database — add the new name, migrate code, then drop the old name.
- Run `ANALYZE` after large data migrations to update query planner statistics.

## Indexing

```sql
-- Create indexes CONCURRENTLY to avoid locking in production
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- Partial index — smaller, faster for common filtered queries
CREATE INDEX CONCURRENTLY idx_orders_pending ON orders(created_at)
    WHERE status = 'pending';

-- Composite index — order matters: match query WHERE clause order
CREATE INDEX CONCURRENTLY idx_events_user_created ON events(user_id, created_at DESC);
```

- Index every foreign key column — unindexed FKs cause full table scans on JOIN and CASCADE DELETE.
- Index columns used in `WHERE`, `ORDER BY`, and `GROUP BY` for frequent queries.
- Use `EXPLAIN ANALYZE` to verify an index is being used before and after adding it.
- Drop unused indexes — they consume disk and slow writes.

## Query Safety

```sql
-- BAD — N+1 query (one query per user)
SELECT * FROM users;
-- for each user: SELECT * FROM orders WHERE user_id = $1

-- GOOD — single JOIN
SELECT u.*, o.id AS order_id, o.total
FROM users u
LEFT JOIN orders o ON o.user_id = u.id;
```

- Avoid `SELECT *` in application code — select only the columns you need.
- Avoid N+1 patterns — use JOINs, subqueries, or batch loading.
- Use parameterized queries everywhere — never string-concatenate user input into SQL.
- Set `statement_timeout` on long-running reports/analytics queries to prevent runaway locks.

## Transactions

```sql
-- Wrap multi-step operations in a transaction
BEGIN;
  INSERT INTO orders (user_id, total) VALUES ($1, $2) RETURNING id INTO v_order_id;
  INSERT INTO order_items (order_id, product_id, qty) VALUES (v_order_id, $3, $4);
COMMIT;
```

- All multi-step operations that must be atomic belong in a transaction.
- Keep transactions as short as possible — long transactions hold locks.
- Never do network calls (HTTP, email, etc.) inside a database transaction.
- Handle `SERIALIZATION_FAILURE` (error code 40001) with retry logic for serializable transactions.

## Sensitive Data

- Hash passwords with bcrypt/argon2 — never store plaintext or reversible encryption.
- Encrypt PII at rest using column-level encryption or a KMS-backed solution.
- Never log raw SQL queries that may contain PII or credentials.
- Apply row-level security (RLS) in PostgreSQL when multi-tenant data lives in a shared table.

## Connection Management

- Use a connection pool (pgBouncer, `pg.Pool`, Drizzle connection pool) — never open one connection per request.
- Set `pool_max` based on `max_connections` in PostgreSQL config — leaving headroom for admin access.
- Always close connections in `finally` blocks — leaked connections exhaust the pool.
