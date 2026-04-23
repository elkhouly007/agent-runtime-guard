---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Performance — Common Rules

## Measure First

Never optimize without a baseline. Profile, record the metric, optimize, record again. Without numbers the optimization is fiction.

### Profiling Commands

```bash
# Node.js — CPU profile written to isolate-*.log
node --prof server.js
node --prof-process isolate-*.log > profile.txt

# Node.js — built-in heap snapshot (run in REPL or script)
const v8 = require("v8"); v8.writeHeapSnapshot();

# Python — cProfile to stdout, sorted by cumulative time
python -m cProfile -s cumtime my_script.py

# Python — line-level timing with line_profiler
pip install line_profiler
kernprof -l -v my_script.py

# Go — pprof CPU profile (30-second sample)
go tool pprof -http=:8080 http://localhost:6060/debug/pprof/profile?seconds=30

# Postgres — slow query log (queries > 100ms)
ALTER SYSTEM SET log_min_duration_statement = 100;
SELECT pg_reload_conf();
```

## Algorithm Complexity

- Know the complexity of your operations: O(1), O(log n), O(n), O(n log n), O(n²).
- Replace nested loops with lookups (dict/map/set) where the dataset can be large.
- Compute once outside the loop; never recompute inside.

```typescript
// BAD — O(n²): array.includes inside a loop
const result = orders.filter(o => activeIds.includes(o.id));  // O(n*m)

// GOOD — O(n): build a set first
const activeSet = new Set(activeIds);                          // O(m)
const result = orders.filter(o => activeSet.has(o.id));        // O(n)
```

## Database

- Run `EXPLAIN ANALYZE` on any query touching tables with > 10k rows.
- Index columns used in `WHERE`, `JOIN`, and `ORDER BY`.
- Select only the columns you need — `SELECT *` fetches columns the network and ORM must serialize for nothing.
- Paginate large result sets with keyset pagination, not OFFSET on large pages.
- Use connection pooling — never open a new connection per request.

### N+1 Fix

```typescript
// BAD — 1 query for posts + N queries for authors
const posts = await Post.findAll();
for (const post of posts) {
  post.author = await User.findById(post.authorId);  // N round-trips
}

// GOOD — 2 queries total (eager load / batch)
const posts = await Post.findAll({ include: [{ model: User, as: "author" }] });
// Or in raw SQL:
// SELECT posts.*, users.name FROM posts JOIN users ON posts.author_id = users.id
```

```bash
# Detect N+1 in Postgres: count queries during a single request
# Enable pg_stat_statements, then after a test run:
SELECT query, calls FROM pg_stat_statements ORDER BY calls DESC LIMIT 20;
```

## Caching

- Cache expensive, frequently accessed, rarely changing data only.
- Always set explicit TTLs — a cache with no TTL is a slow memory leak.
- Document the invalidation strategy next to the cache write.
- Never cache sensitive user data in a shared cache without scoped keys.

```typescript
// BAD — no TTL, no invalidation plan
await redis.set(`user:${id}`, JSON.stringify(user));

// GOOD — TTL + key versioned for invalidation
const TTL_SEC = 300;
await redis.set(`user:v2:${id}`, JSON.stringify(user), "EX", TTL_SEC);
// Invalidate on update:
await redis.del(`user:v2:${id}`);
```

## Lazy Loading

```typescript
// BAD — module initializes heavy resource at import time
import { HeavyClient } from "./heavy-client";  // 800ms startup penalty
const client = new HeavyClient();               // runs at require time

// GOOD — initialize on first use
let _client: HeavyClient | null = null;
function getClient() {
  if (!_client) _client = new HeavyClient();
  return _client;
}
```

## Network

- Parallelize independent requests — do not await them sequentially.
- Debounce rapid user-triggered calls (300ms is a common default).
- Return only the fields the client needs (`GraphQL` projections, `fields` query params).
- Set `Cache-Control` and `ETag` headers correctly on cacheable endpoints.

```typescript
// BAD — sequential: total latency = A + B + C
const user = await fetchUser(id);
const prefs = await fetchPrefs(id);
const feed  = await fetchFeed(id);

// GOOD — parallel: total latency = max(A, B, C)
const [user, prefs, feed] = await Promise.all([
  fetchUser(id), fetchPrefs(id), fetchFeed(id),
]);
```

## Memory

- Release resources explicitly: close files, DB connections, and streams in `finally` blocks.
- Stream or chunk large data — never load a 500MB CSV into memory.
- Watch for closures that capture large objects and prevent GC.

## Frontend

| Metric | Target |
|---|---|
| First Contentful Paint (FCP) | ≤ 1.8s |
| Largest Contentful Paint (LCP) | ≤ 2.5s |
| Cumulative Layout Shift (CLS) | ≤ 0.1 |
| JS bundle (gzipped, initial) | ≤ 200KB |

- Use lazy loading and code splitting for non-critical routes.
- Images: compress, use WebP/AVIF, set explicit `width`/`height`.

```bash
# Lighthouse CI — run and assert budgets
npx lighthouse-ci autorun

# Webpack bundle size analysis
npx webpack-bundle-analyzer stats.json

# Vite build analysis
npx vite-bundle-visualizer
```

## Common Performance Traps

| Trap | Consequence | Fix |
|---|---|---|
| `SELECT *` in ORM | Extra network + deserialization cost | Explicit column projection |
| `await` in a loop | Sequential when parallel is possible | `Promise.all` |
| No connection pool | New TCP handshake per request | `pg-pool`, `SQLAlchemy` pool |
| Cache without TTL | Stale data forever / memory growth | Always set TTL |
| Synchronous file I/O in server path | Blocks the event loop | Use async fs / streams |
| Sorting in application code | N log N in memory on full dataset | Sort in DB with index |
| Polling on short interval | Thundering herd | Exponential back-off or WebSocket |
