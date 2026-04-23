# Skill: PostgreSQL Patterns

## Trigger

Use when optimizing PostgreSQL queries, designing indexes, investigating slow queries, configuring connection pooling, setting up partitioning, or reviewing database schema and maintenance settings.

## Pre-Optimization Checklist

- [ ] Run `EXPLAIN (ANALYZE, BUFFERS)` — never guess; read the plan.
- [ ] Check `pg_stat_statements` for the actual top slow queries in production.
- [ ] Identify table sizes and row counts before proposing schema changes.
- [ ] Confirm indexes are used (not just existing — check `pg_stat_user_indexes`).
- [ ] Understand the access pattern: OLTP (many small reads/writes) vs OLAP (few large scans).

## Process

### 1. Index Types

| Index Type | Use When | Avoid When |
|------------|----------|------------|
| B-tree (default) | Equality, range, ORDER BY, `LIKE 'prefix%'` | Low-cardinality columns (<10 distinct values) |
| GIN | `jsonb` containment (`@>`), full-text search, arrays | Write-heavy tables (GIN is slow to update) |
| GiST | Geometric types, range types, full-text (tsvector) | Exact equality lookups |
| BRIN | Very large tables sorted by natural insert order (timestamps) | Random write tables |
| Hash | Exact equality only | Range queries — hash indexes don't support them |
| Partial | Queries that always include a WHERE clause (e.g., `WHERE deleted_at IS NULL`) | Universal filters |
| Covering (`INCLUDE`) | Add extra columns to satisfy index-only scans | Wide columns — bloats the index |

```sql
-- B-tree (default): orders by created_at range
CREATE INDEX CONCURRENTLY idx_orders_created_at ON orders(created_at DESC);

-- Partial: only index active orders — excludes archived rows
CREATE INDEX CONCURRENTLY idx_orders_active
  ON orders(user_id, created_at)
  WHERE status != 'archived';

-- Covering: index-only scan for list query (no heap fetch)
CREATE INDEX CONCURRENTLY idx_users_email_covering
  ON users(email)
  INCLUDE (id, name);

-- GIN: JSONB containment queries
CREATE INDEX CONCURRENTLY idx_events_metadata_gin
  ON events USING GIN (metadata);
-- Query: SELECT * FROM events WHERE metadata @> '{"type": "click"}';

-- GIN: full-text search
CREATE INDEX CONCURRENTLY idx_articles_fts
  ON articles USING GIN (to_tsvector('english', title || ' ' || body));
-- Query: SELECT * FROM articles WHERE to_tsvector('english', title || ' ' || body) @@ plainto_tsquery('english', 'search term');

-- BRIN: huge append-only log table (billions of rows, ordered by time)
CREATE INDEX idx_logs_created_at_brin
  ON logs USING BRIN (created_at);

-- Composite: order of columns matters — put equality columns first
CREATE INDEX CONCURRENTLY idx_orders_user_status
  ON orders(user_id, status);
-- Supports: WHERE user_id = $1 AND status = $2
-- Supports: WHERE user_id = $1                 (leading prefix)
-- Does NOT support: WHERE status = $2           (non-leading)
```

### 2. EXPLAIN ANALYZE Interpretation

```sql
-- Always use these flags together
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
```

```
-- Reading the plan output:

Seq Scan on orders  (cost=0.00..15420.00 rows=500000 width=120)
                     (actual time=0.15..312.4 rows=500000 loops=1)
  Buffers: shared hit=5420 read=10000
  
-- cost=start..total    estimate before execution
-- actual time=start..end ms
-- rows=actual rows returned
-- Buffers: shared hit=from cache, read=from disk (read >> hit → cache miss)
-- Seq Scan on a large table with a selective WHERE → missing index

Index Scan using idx_orders_user_id on orders
  (cost=0.43..8.46 rows=1 width=120) (actual time=0.05..0.07 rows=1 loops=1)
  Index Cond: (user_id = 42)
  Buffers: shared hit=3
-- Good: 3 buffer hits, index used, 1 row

Bitmap Heap Scan on orders
  (cost=125.43..4832.12 rows=10000 width=120) (actual time=2.1..18.4 rows=9823 loops=1)
  Recheck Cond: (status = 'pending')
  ->  Bitmap Index Scan on idx_orders_status
       (actual time=1.8..1.8 rows=9823 loops=1)
-- Good for moderate selectivity (thousands of rows)
```

```sql
-- Detect sequential scans on large tables that should have indexes
SELECT
  relname,
  seq_scan,
  idx_scan,
  n_live_tup,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan
  AND n_live_tup > 10000
ORDER BY seq_scan DESC;
```

### 3. Query Optimization Patterns

#### Avoid SELECT *

```sql
-- Bad: fetches all columns, prevents index-only scans, wastes bandwidth
SELECT * FROM users WHERE email = $1;

-- Good: fetch only what the caller needs
SELECT id, name, email, timezone FROM users WHERE email = $1;
```

#### Avoid N+1 with JOINs or ANY

```sql
-- Bad: one query per order (N+1)
-- application code: orders.forEach(o => query('SELECT * FROM users WHERE id = $1', o.user_id))

-- Good: single JOIN
SELECT o.id, o.total, u.name, u.email
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.status = 'pending';

-- Good for IN-list lookups
SELECT id, name FROM users WHERE id = ANY($1::uuid[]);
```

#### CTEs (Common Table Expressions)

```sql
-- Use CTEs for readability and to name intermediate results
WITH recent_orders AS (
  SELECT user_id, SUM(total) AS spend
  FROM orders
  WHERE created_at >= NOW() - INTERVAL '30 days'
  GROUP BY user_id
),
top_customers AS (
  SELECT user_id, spend
  FROM recent_orders
  WHERE spend > 1000
)
SELECT u.name, u.email, tc.spend
FROM top_customers tc
JOIN users u ON u.id = tc.user_id
ORDER BY tc.spend DESC;

-- NOTE: In Postgres 12+, CTEs are NOT always optimization fences.
-- Use MATERIALIZED or NOT MATERIALIZED explicitly when needed.
WITH MATERIALIZED expensive_subquery AS (
  SELECT ... -- force materialization (computed once, stored)
)
SELECT * FROM expensive_subquery;
```

#### Window Functions

```sql
-- Running total per user
SELECT
  user_id,
  order_date,
  total,
  SUM(total) OVER (PARTITION BY user_id ORDER BY order_date) AS running_total
FROM orders;

-- Rank orders per user by amount
SELECT
  user_id,
  id AS order_id,
  total,
  RANK() OVER (PARTITION BY user_id ORDER BY total DESC) AS rank
FROM orders;

-- Get latest order per user without GROUP BY hack
SELECT DISTINCT ON (user_id) user_id, id, total, created_at
FROM orders
ORDER BY user_id, created_at DESC;
```

### 4. Connection Pooling with PgBouncer

```ini
# /etc/pgbouncer/pgbouncer.ini
[databases]
mydb = host=127.0.0.1 port=5432 dbname=mydb

[pgbouncer]
listen_port   = 6432
listen_addr   = 0.0.0.0
auth_type     = scram-sha-256
auth_file     = /etc/pgbouncer/userlist.txt
pool_mode     = transaction        # transaction pooling — most efficient for web apps
max_client_conn = 1000             # max clients connecting to PgBouncer
default_pool_size = 20             # connections per user/database pair to Postgres
reserve_pool_size = 5
reserve_pool_timeout = 3
server_idle_timeout = 600
log_connections = 0
log_disconnections = 0
```

```
Pool modes:
  session     — connection held for full client session (same as no pooling)
  transaction — connection held only during a transaction (recommended)
  statement   — connection released after each statement (can't use multi-statement transactions)

Use transaction mode for:
  - Web apps using short-lived requests
  - ORMs (Prisma, SQLAlchemy, GORM) — they work fine in transaction mode

Avoid transaction mode with:
  - SET LOCAL / advisory locks / LISTEN/NOTIFY — these require session mode
```

```sql
-- Check current connection usage in Postgres
SELECT count(*), state, wait_event_type, wait_event
FROM pg_stat_activity
GROUP BY state, wait_event_type, wait_event
ORDER BY count DESC;
```

### 5. VACUUM and Autovacuum Tuning

```sql
-- Check table bloat and vacuum stats
SELECT
  relname,
  n_live_tup,
  n_dead_tup,
  ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_pct,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 20;

-- Manual VACUUM on a heavily updated table (non-blocking)
VACUUM (VERBOSE, ANALYZE) orders;

-- VACUUM FULL reclaims disk space but locks the table — use only in maintenance window
VACUUM FULL orders;
```

```sql
-- Per-table autovacuum tuning (for high-churn tables)
ALTER TABLE orders SET (
  autovacuum_vacuum_scale_factor = 0.01,  -- vacuum at 1% dead tuples (default 20%)
  autovacuum_analyze_scale_factor = 0.005,
  autovacuum_vacuum_cost_delay = 2         -- ms — less aggressive = less I/O impact
);
```

### 6. Partitioning

```sql
-- Range partitioning: orders by month
CREATE TABLE orders (
  id          BIGINT GENERATED ALWAYS AS IDENTITY,
  user_id     UUID NOT NULL,
  total       NUMERIC(10, 2) NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2024_01 PARTITION OF orders
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- Partition pruning happens automatically when the query includes the partition key
SELECT * FROM orders WHERE created_at >= '2024-01-01' AND created_at < '2024-02-01';
-- Postgres scans only orders_2024_01

-- List partitioning: by region
CREATE TABLE events (
  id      BIGINT GENERATED ALWAYS AS IDENTITY,
  region  TEXT NOT NULL,
  data    JSONB
) PARTITION BY LIST (region);

CREATE TABLE events_us PARTITION OF events FOR VALUES IN ('us-east', 'us-west');
CREATE TABLE events_eu PARTITION OF events FOR VALUES IN ('eu-west', 'eu-central');

-- Hash partitioning: for even distribution (no natural key)
CREATE TABLE sessions (
  id       UUID PRIMARY KEY,
  user_id  UUID NOT NULL,
  data     JSONB
) PARTITION BY HASH (user_id);

CREATE TABLE sessions_0 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE sessions_1 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE sessions_2 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE sessions_3 PARTITION OF sessions FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```

### 7. JSONB Indexing

```sql
-- Containment query — GIN index
CREATE INDEX CONCURRENTLY idx_events_data_gin ON events USING GIN (data);
SELECT * FROM events WHERE data @> '{"event_type": "purchase"}';

-- Specific key access — expression index (more efficient if you always query one key)
CREATE INDEX CONCURRENTLY idx_events_event_type
  ON events ((data->>'event_type'));
SELECT * FROM events WHERE data->>'event_type' = 'purchase';

-- GIN with jsonb_path_ops (smaller index, only supports @> and @?)
CREATE INDEX CONCURRENTLY idx_events_data_path
  ON events USING GIN (data jsonb_path_ops);

-- JSONB path query
SELECT * FROM events WHERE data @? '$.tags[*] ? (@ == "vip")';
```

### 8. pg_stat_statements for Slow Queries

```sql
-- Enable the extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- In postgresql.conf:
-- shared_preload_libraries = 'pg_stat_statements'
-- pg_stat_statements.max = 10000
-- pg_stat_statements.track = all

-- Top 10 slowest queries by total time
SELECT
  LEFT(query, 120) AS query,
  calls,
  ROUND((total_exec_time / calls)::numeric, 2) AS avg_ms,
  ROUND(total_exec_time::numeric, 2) AS total_ms,
  rows,
  ROUND((100 * total_exec_time / SUM(total_exec_time) OVER ())::numeric, 2) AS pct_total
FROM pg_stat_statements
WHERE calls > 10
ORDER BY total_exec_time DESC
LIMIT 10;

-- Reset stats (after optimization, to measure improvement)
SELECT pg_stat_statements_reset();
```

### 9. Replication Basics

```
Streaming replication: primary sends WAL to standby in real time.
Logical replication:   replicate specific tables/rows — good for zero-downtime upgrades.

Promote a standby (emergency):
  pg_ctl promote -D /var/lib/postgresql/data
  -- or: touch /tmp/promote-trigger

Check replication lag:
```

```sql
-- On primary
SELECT
  client_addr,
  state,
  sent_lsn,
  write_lsn,
  flush_lsn,
  replay_lsn,
  pg_size_pretty(pg_wal_lsn_diff(sent_lsn, replay_lsn)) AS replication_lag
FROM pg_stat_replication;

-- On standby
SELECT NOW() - pg_last_xact_replay_timestamp() AS replication_delay;
```

### 10. Backup with pg_dump

```bash
# Logical backup — single database
pg_dump -Fc -d mydb -f mydb_$(date +%Y%m%d_%H%M%S).dump

# Restore
pg_restore -Fc -d mydb_new mydb_20240315_120000.dump

# Schema only
pg_dump -Fc --schema-only -d mydb -f mydb_schema.dump

# Parallel backup (multiple workers — faster for large DBs)
pg_dump -Fd -j 4 -d mydb -f mydb_dir_backup/

# Continuous WAL archiving (point-in-time recovery)
# postgresql.conf:
# wal_level = replica
# archive_mode = on
# archive_command = 'aws s3 cp %p s3://my-bucket/wal/%f'

# Test restore — always verify backups
pg_restore --list mydb.dump | head -20
createdb mydb_test && pg_restore -d mydb_test mydb.dump
psql -d mydb_test -c "SELECT COUNT(*) FROM orders;"
```

## Anti-Patterns

- **Never index every column** — indexes slow down writes and take disk space; index selectively.
- **Never use SELECT * in application code** — it breaks index-only scans and couples code to schema.
- **Never run VACUUM FULL on production without a maintenance window** — it acquires an exclusive lock.
- **Never create indexes inside a transaction** — `CONCURRENTLY` is incompatible with transactions.
- **Never ignore autovacuum warnings** — table bloat grows silently until queries become slow.
- **Never do large backfills in a single UPDATE** — batch in chunks to avoid lock escalation and WAL bloat.
- **Never rely on `count(*)` on large tables for monitoring** — use `pg_stat_user_tables.n_live_tup` instead.

## Safe Behavior

- Read-only query analysis — no schema changes without Ahmed's confirmation.
- Flags missing indexes on foreign keys, large sequential scans, and SELECT *.
- Flags autovacuum disabled or heavily tuned in ways that increase bloat.
- CRITICAL findings (data loss risk, replication lag > 60s) require Ahmed's attention.
- Does not execute DDL statements (CREATE INDEX, ALTER TABLE, DROP) on production autonomously.
