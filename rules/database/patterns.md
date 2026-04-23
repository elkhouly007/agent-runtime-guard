# Database Design Patterns

Patterns for robust, maintainable database design.

## Schema Design

- Tables represent nouns (entities), not verbs or actions.
- Every table has a surrogate primary key (`id BIGINT GENERATED ALWAYS AS IDENTITY` or UUID).
- Foreign keys are always indexed. Named constraints: `fk_orders_user_id`.
- Timestamps on every table: `created_at`, `updated_at`, NOT NULL with defaults.
- Soft deletes with `deleted_at` when hard deletes would orphan audit history.

## Normalization

- Third Normal Form (3NF) as the default target.
- Denormalize deliberately and document why (read performance, query simplification).
- Extract repeated string values into lookup tables rather than ENUMs for flexibility.

## Query Patterns

Prefer explicit over implicit:

```sql
-- Explicit column list (not SELECT *)
SELECT id, name, email FROM users WHERE active = true;

-- Explicit JOIN type
SELECT o.id, u.name
FROM orders o
INNER JOIN users u ON u.id = o.user_id
WHERE o.status = 'pending';
```

## Pagination

Use keyset pagination for large datasets instead of OFFSET:

```sql
-- Keyset: no performance cliff
SELECT id, name FROM products
WHERE id > :last_seen_id
ORDER BY id
LIMIT :page_size;

-- OFFSET: degrades at high pages
SELECT id, name FROM products ORDER BY id LIMIT 20 OFFSET 10000;
```

## Indexing Strategy

- Index columns used in WHERE, JOIN ON, and ORDER BY.
- Composite index column order: equality predicates first, range/sort last.
- Partial indexes for filtered queries:

```sql
CREATE INDEX idx_orders_pending ON orders (created_at) WHERE status = 'pending';
```

## Migrations

- One migration = one logical change. Never combine schema + data changes.
- Migrations are always forward-only. Rollback scripts are separate optional artifacts.
- New columns are nullable or have defaults to avoid locking.
- Rename in three phases: add new column → backfill → drop old column.

## Connection Management

- Use connection pools. Size to `(core_count * 2) + effective_spindle_count`.
- Set statement timeouts to prevent runaway queries.
- Separate read replicas for analytics queries.
