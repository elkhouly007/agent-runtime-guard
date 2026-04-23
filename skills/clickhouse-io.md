# Skill: ClickHouse IO

## Trigger

Use when designing ClickHouse schemas, writing analytics queries, building data pipelines into ClickHouse, optimizing query performance, setting up materialized views, or integrating ClickHouse with Kafka or S3.

## Pre-Query Checklist

- [ ] Confirm the table engine is correct for the access pattern (MergeTree family).
- [ ] Understand the ORDER BY (sort key) and how queries filter against it.
- [ ] Check that queries include partition pruning conditions.
- [ ] Use PREWHERE instead of WHERE for heavy filtering on non-index columns.
- [ ] Test INSERT batch size — avoid inserting one row at a time.

## Process

### 1. MergeTree Engine Family

| Engine | When to Use | Key Feature |
|--------|-------------|-------------|
| `MergeTree` | Base OLAP table, no deduplication | Fastest inserts, no guarantees |
| `ReplacingMergeTree` | Upsert / latest-value semantics | Deduplicates on merge by ORDER BY key |
| `SummingMergeTree` | Pre-aggregated summaries | Sums numeric columns with same ORDER BY |
| `AggregatingMergeTree` | Complex pre-aggregation | Stores AggregateFunction states |
| `CollapsingMergeTree` | Mutable rows via sign column | Collapses old + new pairs |
| `ReplicatedMergeTree` | HA — replicates across nodes | Uses ZooKeeper/Keeper |

#### MergeTree — Base Table

```sql
CREATE TABLE events
(
    event_date   Date,
    event_time   DateTime64(3, 'UTC'),
    user_id      UInt64,
    session_id   String,
    event_type   LowCardinality(String),    -- LowCardinality for <10k distinct values
    page         String,
    metadata     String,                    -- use String; parse in queries with JSONExtract
    revenue      Nullable(Decimal(10, 2))
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)           -- monthly partitions
ORDER BY (event_type, user_id, event_time)  -- sort key: equality columns first
SETTINGS index_granularity = 8192;         -- default: 8192 rows per granule
```

#### ReplacingMergeTree — Latest-Value Upsert

```sql
-- Deduplicates rows with the same ORDER BY key on background merge.
-- Always use FINAL or argMax() in queries to get latest values.

CREATE TABLE user_profiles
(
    user_id     UInt64,
    updated_at  DateTime64(3, 'UTC'),
    name        String,
    email       String,
    plan        LowCardinality(String),
    version     UInt64                     -- used as version column
)
ENGINE = ReplacingMergeTree(version)       -- keeps the row with the highest version
PARTITION BY toYYYYMM(toDate(updated_at))
ORDER BY user_id;

-- Query with FINAL (forces deduplication at query time)
SELECT user_id, name, email, plan
FROM user_profiles FINAL
WHERE user_id = 42;

-- Faster alternative: argMax (no FINAL, query-time aggregation)
SELECT
    user_id,
    argMax(name,  updated_at) AS name,
    argMax(email, updated_at) AS email,
    argMax(plan,  updated_at) AS plan
FROM user_profiles
WHERE user_id = 42
GROUP BY user_id;
```

#### AggregatingMergeTree — Pre-Aggregation

```sql
-- State is stored as AggregateFunction type
CREATE TABLE daily_revenue_agg
(
    event_date     Date,
    product_id     UInt32,
    revenue_state  AggregateFunction(sum, Decimal(10, 2)),
    orders_state   AggregateFunction(count, UInt64)
)
ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (event_date, product_id);

-- Populate via INSERT SELECT using *State combinators
INSERT INTO daily_revenue_agg
SELECT
    toDate(event_time) AS event_date,
    product_id,
    sumState(revenue)   AS revenue_state,
    countState()        AS orders_state
FROM orders
GROUP BY event_date, product_id;

-- Query using *Merge combinators
SELECT
    event_date,
    product_id,
    sumMerge(revenue_state)  AS total_revenue,
    countMerge(orders_state) AS total_orders
FROM daily_revenue_agg
WHERE event_date >= today() - 30
GROUP BY event_date, product_id
ORDER BY event_date, total_revenue DESC;
```

### 2. Primary Key vs ORDER BY (Sort Key)

```sql
-- In ClickHouse these are DIFFERENT — easy to confuse.

-- ORDER BY (sort key): determines physical sort order on disk.
--   All columns used for primary index construction.
--   Must be a prefix of the ORDER BY expression.

-- PRIMARY KEY: determines the sparse primary index (subset of ORDER BY).
--   By default, PRIMARY KEY = ORDER BY.
--   Can set a shorter PRIMARY KEY to reduce index memory.

CREATE TABLE page_views
(
    site_id    UInt32,
    page_url   String,
    event_date Date,
    user_id    UInt64,
    duration   UInt32
)
ENGINE = MergeTree()
PARTITION BY toYYYYMM(event_date)
ORDER BY (site_id, event_date, page_url, user_id)  -- full sort key
PRIMARY KEY (site_id, event_date);                  -- shorter primary index

-- Queries filtering on (site_id) or (site_id, event_date) use the primary index.
-- Queries additionally filtering on page_url benefit from sort order (range scan).
-- Queries filtering ONLY on page_url → full table scan — add secondary index if needed.
```

```sql
-- Secondary (data skipping) indexes
ALTER TABLE page_views ADD INDEX idx_page_url page_url TYPE bloom_filter(0.01) GRANULARITY 4;
ALTER TABLE page_views MATERIALIZE INDEX idx_page_url;
```

### 3. Partition Pruning

```sql
-- Partition pruning only fires when the query references the partition expression column.
-- PARTITION BY toYYYYMM(event_date) → filter must include event_date.

-- PRUNING fires (reads only 2024-01 and 2024-02 parts):
SELECT count() FROM events
WHERE event_date >= '2024-01-01' AND event_date < '2024-03-01';

-- NO PRUNING (event_time is not the partition column):
SELECT count() FROM events
WHERE event_time >= '2024-01-01 00:00:00' AND event_time < '2024-03-01 00:00:00';

-- Check what partitions exist and their sizes
SELECT
    partition,
    name,
    rows,
    formatReadableSize(bytes_on_disk) AS size_on_disk,
    active
FROM system.parts
WHERE table = 'events' AND database = 'analytics' AND active
ORDER BY partition DESC
LIMIT 20;
```

### 4. Materialized Views for Pre-Aggregation

```sql
-- Materialized views in ClickHouse are INSERT triggers — they fire on each INSERT
-- to the source table and write to the target table.

-- Source table
CREATE TABLE raw_events
(
    event_time   DateTime64(3, 'UTC'),
    user_id      UInt64,
    event_type   LowCardinality(String),
    revenue      Nullable(Decimal(10, 2))
)
ENGINE = MergeTree()
PARTITION BY toDate(event_time)
ORDER BY (event_type, user_id, event_time);

-- Target table (AggregatingMergeTree)
CREATE TABLE hourly_revenue
(
    hour             DateTime,
    event_type       LowCardinality(String),
    revenue_state    AggregateFunction(sum, Decimal(10, 2)),
    event_count_state AggregateFunction(count, UInt64)
)
ENGINE = AggregatingMergeTree()
PARTITION BY toYYYYMM(hour)
ORDER BY (hour, event_type);

-- Materialized view (INSERT trigger)
CREATE MATERIALIZED VIEW mv_hourly_revenue
TO hourly_revenue        -- explicit target table (preferred over implicit .inner table)
AS
SELECT
    toStartOfHour(event_time) AS hour,
    event_type,
    sumState(revenue)         AS revenue_state,
    countState()              AS event_count_state
FROM raw_events
GROUP BY hour, event_type;

-- Query
SELECT
    hour,
    event_type,
    sumMerge(revenue_state)       AS total_revenue,
    countMerge(event_count_state) AS total_events
FROM hourly_revenue
WHERE hour >= now() - INTERVAL 24 HOUR
GROUP BY hour, event_type
ORDER BY hour, total_revenue DESC;
```

### 5. INSERT Best Practices

```
Rule: batch inserts into ClickHouse, do not insert row by row.
Optimal batch size: 10 000 – 1 000 000 rows per INSERT.
Reason: each INSERT creates a new part on disk; too many parts cause merges to fall behind.
```

```sql
-- Bad: one INSERT per event (creates 1 000 000 small parts)
INSERT INTO events VALUES (now(), 1, 'click', ...);
INSERT INTO events VALUES (now(), 2, 'view', ...);
-- ... 1 000 000 more

-- Good: batch insert
INSERT INTO events FORMAT JSONEachRow
{"event_time":"2024-01-15 12:00:00","user_id":1,"event_type":"click"}
{"event_time":"2024-01-15 12:00:00","user_id":2,"event_type":"view"}
...
-- 100 000 rows in one INSERT
```

```yaml
# Async insert (ClickHouse 21.8+) — buffers small inserts server-side
# In clickhouse-client or connection string settings:
async_insert: 1
wait_for_async_insert: 1          # wait for flush confirmation (at-least-once)
async_insert_max_data_size: 10000000   # 10 MB buffer before flush
async_insert_busy_timeout_ms: 200      # flush after 200ms even if buffer not full
```

```python
# Python: clickhouse-connect with batching
import clickhouse_connect

client = clickhouse_connect.get_client(
    host='localhost', port=8123,
    settings={'async_insert': 1, 'wait_for_async_insert': 1}
)

# Build batch
rows = [(row['event_time'], row['user_id'], row['event_type']) for row in batch]
client.insert('events', rows, column_names=['event_time', 'user_id', 'event_type'])
```

### 6. Query Optimization: PREWHERE

```sql
-- PREWHERE is a ClickHouse-specific optimization.
-- Filters are applied before reading all columns — reduces I/O significantly.
-- ClickHouse often pushes WHERE to PREWHERE automatically, but you can be explicit.

-- Normal WHERE (reads all columns for all granules, then filters)
SELECT user_id, revenue FROM events
WHERE event_type = 'purchase' AND event_date = today();

-- PREWHERE (reads event_type column first, skips non-matching granules entirely)
SELECT user_id, revenue FROM events
PREWHERE event_type = 'purchase'
WHERE event_date = today();

-- When to use PREWHERE explicitly:
-- 1. The filtering column has low cardinality relative to the granule.
-- 2. The column you're filtering on is NOT in the primary key.
-- 3. The remaining columns are wide (e.g., large Strings or Arrays).

-- AVOID in PREWHERE: non-deterministic functions, expressions involving multiple columns
```

### 7. Data Types for Compression

```sql
-- Use the smallest type that fits the data range.

-- Integer types
UInt8     -- 0 to 255
UInt16    -- 0 to 65535
UInt32    -- 0 to 4 billion
UInt64    -- 0 to 18 quintillion
Int32     -- signed
Int64     -- signed

-- LowCardinality — dictionary encoding for repeated strings
-- Use when column has < ~10 000 distinct values
event_type  LowCardinality(String)
country     LowCardinality(FixedString(2))  -- ISO 3166-1 alpha-2

-- Nullable — adds a separate null bitmap; avoid when possible
-- Better: use sentinel value (0 or empty string) or store in separate table
revenue     Decimal(10, 2)       -- NOT Nullable(Decimal) if 0 means no revenue

-- DateTime vs DateTime64
event_date   Date                 -- 4 bytes, day resolution
event_time   DateTime             -- 4 bytes, second resolution
event_time   DateTime64(3, 'UTC') -- 8 bytes, millisecond resolution — prefer for events

-- Compression codecs (column-level)
CREATE TABLE metrics
(
    ts        DateTime CODEC(DoubleDelta, LZ4),   -- great for monotonic timestamps
    value     Float64 CODEC(Gorilla, ZSTD(1)),    -- great for slowly-changing floats
    user_id   UInt64  CODEC(T64, LZ4)             -- T64 for large integers with common bits
)
ENGINE = MergeTree() ORDER BY ts;
```

### 8. TTL Policies

```sql
-- Automatically delete or move data after a time period

-- Delete rows older than 90 days
ALTER TABLE events MODIFY TTL event_date + INTERVAL 90 DAY;

-- Move cold data to cheaper storage (tiered storage)
ALTER TABLE events MODIFY TTL
    event_date + INTERVAL 30 DAY TO DISK 'warm_disk',
    event_date + INTERVAL 90 DAY TO DISK 'cold_s3';

-- Column-level TTL: nullify a column instead of deleting the row
ALTER TABLE users MODIFY COLUMN email String TTL updated_at + INTERVAL 365 DAY;

-- Force TTL processing immediately (default is lazy on merge)
ALTER TABLE events MATERIALIZE TTL;

-- Check TTL expressions on a table
SHOW CREATE TABLE events;
```

### 9. clickhouse-client Commands

```bash
# Connect
clickhouse-client --host localhost --port 9000 --user default --password secret --database analytics

# Run a query inline
clickhouse-client -q "SELECT count() FROM events WHERE event_date = today()"

# Import from CSV
clickhouse-client --query="INSERT INTO events FORMAT CSV" < data.csv

# Import from JSONEachRow
clickhouse-client --query="INSERT INTO events FORMAT JSONEachRow" < data.jsonl

# Export to CSV
clickhouse-client --query="SELECT * FROM events WHERE event_date='2024-01-15' FORMAT CSV" > events_20240115.csv

# Check system health
clickhouse-client -q "SELECT * FROM system.replicas WHERE is_readonly OR is_session_expired"

# Check current merges
clickhouse-client -q "SELECT database, table, elapsed, progress, rows_read FROM system.merges"

# Check recent mutations (ALTER UPDATE/DELETE)
clickhouse-client -q "SELECT * FROM system.mutations WHERE not is_done ORDER BY create_time DESC LIMIT 10"

# Check part count (high part count = inserts too small or merges falling behind)
clickhouse-client -q "
  SELECT table, count() AS parts, sum(rows) AS rows, formatReadableSize(sum(bytes_on_disk)) AS size
  FROM system.parts WHERE active AND database = 'analytics'
  GROUP BY table ORDER BY parts DESC"
```

### 10. Kafka Integration

```sql
-- Step 1: Kafka engine table (source — do not query directly)
CREATE TABLE kafka_raw_events
(
    payload String
)
ENGINE = Kafka()
SETTINGS
    kafka_broker_list     = 'kafka:9092',
    kafka_topic_list      = 'events',
    kafka_group_name      = 'clickhouse-consumer',
    kafka_format          = 'JSONEachRow',
    kafka_num_consumers   = 4,
    kafka_skip_broken_messages = 100;

-- Step 2: Target MergeTree table
CREATE TABLE events ( ... ) ENGINE = MergeTree() ...;

-- Step 3: Materialized view (moves data from Kafka table to MergeTree)
CREATE MATERIALIZED VIEW mv_kafka_to_events TO events AS
SELECT
    JSONExtractString(payload, 'event_type') AS event_type,
    toDateTime64(JSONExtractUInt(payload, 'ts') / 1000.0, 3, 'UTC') AS event_time,
    JSONExtractUInt(payload, 'user_id') AS user_id
FROM kafka_raw_events;
```

### 11. S3 Integration

```sql
-- Read directly from S3 (no ingestion needed for ad-hoc queries)
SELECT count(), event_type
FROM s3(
    'https://my-bucket.s3.amazonaws.com/events/2024/01/*.parquet',
    'ACCESS_KEY', 'SECRET_KEY',
    'Parquet'
)
GROUP BY event_type;

-- S3 as a storage backend (MergeTree on S3)
-- config.xml / storage_configuration:
-- disk type=s3, endpoint, access_key_id, secret_access_key

-- Export query results to S3
INSERT INTO FUNCTION s3(
    'https://my-bucket.s3.amazonaws.com/export/daily_revenue.parquet',
    'ACCESS_KEY', 'SECRET_KEY',
    'Parquet'
)
SELECT * FROM daily_revenue WHERE event_date = yesterday();

-- S3Queue engine (2023.8+) — streaming ingest from S3
CREATE TABLE s3_queue_events
ENGINE = S3Queue('https://my-bucket.s3.amazonaws.com/events/*.jsonl', 'JSONEachRow')
SETTINGS mode = 'ordered', s3queue_loading_retries = 3;
```

## Anti-Patterns

- **Never INSERT one row at a time** — batch aggressively (minimum 1 000 rows, target 100 000+).
- **Never use Nullable() columns unnecessarily** — they add overhead; prefer sentinel values.
- **Never ORDER BY on a high-cardinality first column when you always filter by a low-cardinality one** — put the equality filter column first in the sort key.
- **Never run ALTER TABLE DELETE (mutation) frequently** — mutations rewrite data parts; use TTL or ReplacingMergeTree instead.
- **Never query a Kafka engine table directly in production** — use the materialized view target table.
- **Never ignore part count growth** — more than 3 000 active parts per table causes performance degradation.
- **Never use String for time series metrics** — use Decimal or Float64 with appropriate codecs.
- **Never skip FINAL on ReplacingMergeTree queries unless you understand duplicates may appear** — merges are background and not instantaneous.

## Safe Behavior

- Read-only query analysis — no schema or data changes without Ahmed's confirmation.
- Flags missing partition pruning conditions, unbatched inserts, and missing ORDER BY alignment.
- Flags Nullable columns on high-volume tables and raw string storage for numeric data.
- CRITICAL findings (data loss via TTL misconfiguration, Kafka consumer group drift) require Ahmed's attention.
- Does not execute DDL or INSERT statements on production ClickHouse autonomously.
