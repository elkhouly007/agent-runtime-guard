# Skill: Performance Audit

## Trigger

Use when:
- An endpoint or operation is measurably slower than expected
- Memory usage grows over time (leak suspected)
- Lighthouse / Core Web Vitals scores are failing
- A recent change caused a measurable regression
- Pre-launch performance validation is required

**Never optimize without a measured baseline.** Gut feeling is not a bottleneck.

## Principle: Measure → Identify → Fix → Measure Again

```
[Baseline measurement]
       ↓
[Identify top bottleneck — ONE at a time]
       ↓
[Apply targeted fix]
       ↓
[Measure again — document delta]
       ↓
[Repeat for next bottleneck if needed]
```

## Process

### 1. Establish baseline
Document current numbers before touching anything:
- Response time (p50, p95, p99)
- Memory usage (heap, RSS)
- CPU usage under load
- Lighthouse score (if frontend)
- Query time (if database)

### 2. Delegate to performance-optimizer agent
Provide:
- The baseline numbers
- The suspected area (frontend / backend / database / memory)
- Recent changes that may have caused the regression

### 3. Profile — find the real bottleneck

#### Backend Profiling
```bash
# Node.js — clinic.js flame graph
npx clinic flame -- node server.js
npx clinic doctor -- node server.js

# Python — py-spy
py-spy record -o profile.svg -- python app.py
py-spy top --pid <pid>   # live view

# Go — pprof
go tool pprof http://localhost:6060/debug/pprof/profile   # CPU
go tool pprof http://localhost:6060/debug/pprof/heap      # Memory
# Add to main.go: import _ "net/http/pprof"

# Java — Flight Recorder / async-profiler
java -XX:+FlightRecorder -XX:StartFlightRecording=duration=60s,filename=app.jfr ...
# View in JDK Mission Control
```

#### Frontend Profiling
- Chrome DevTools → Performance tab → Record user interaction → identify long tasks.
- Chrome DevTools → Network tab → check resource sizes, waterfall, blocking requests.
- [Lighthouse](https://developers.google.com/web/tools/lighthouse): `npx lighthouse <url> --view`
- WebPageTest for real-device testing and filmstrip.
- Core Web Vitals: LCP, FID/INP, CLS.

#### Database Profiling
```sql
-- PostgreSQL: slow query analysis
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;

-- MySQL / MariaDB
EXPLAIN SELECT ...;
SHOW PROFILE FOR QUERY 1;

-- MongoDB: explain plan
db.collection.find({...}).explain("executionStats")

-- Enable slow query log (PostgreSQL)
SET log_min_duration_statement = 500;  -- log queries > 500ms
```

For DB issues → also consult `database-reviewer` agent.

#### Memory Leak Detection
```bash
# Node.js — heap snapshot
node --inspect server.js
# Chrome DevTools → Memory tab → Take Heap Snapshot (before/after operation)
# Look for: growing detached DOM nodes, growing closures, accumulating event listeners

# Python
import tracemalloc
tracemalloc.start()
# ... code ...
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

# Go
import _ "net/http/pprof"
# curl http://localhost:6060/debug/pprof/heap > heap.pprof
# go tool pprof heap.pprof
```

### 4. Bottleneck categories and fixes

| Category | Indicators | Fix direction |
|----------|-----------|---------------|
| N+1 query | DB query count grows with list size | Eager load / batch fetch / dataloader |
| Missing index | `EXPLAIN` shows seq scan on large table | Add index on filtered/sorted columns |
| Blocking I/O on main thread | Event loop lag, slow TTFB | Move to async / worker thread |
| Unnecessary re-renders | High React render count | memo, useMemo, useCallback, virtualize lists |
| Large bundle | Lighthouse flags JS size | Code splitting, tree shaking, lazy import |
| Uncompressed assets | Large network transfer | gzip/brotli, image optimization, CDN |
| Memory leak | RSS grows over time without release | Find retention chain, fix reference holding |
| Synchronous computation | CPU spike, blocked event loop | Move to worker, cache result, optimize algorithm |
| Cache miss | High DB/API hit rate for repeated queries | Add cache layer (Redis, in-memory) with TTL |

### 5. Document the result

For every optimization applied:
```
Metric:    p95 response time / Lighthouse LCP / query time / heap size
Before:    X ms / X MB / X score
Fix:       [description of what changed]
After:     Y ms / Y MB / Y score
Delta:     -Z% improvement
```

## What NOT to Do

- Do not optimize based on "this looks slow" without measuring.
- Do not optimize code that runs once or rarely.
- Do not add caching to hide a bad query — fix the query first.
- Do not disable functionality to improve performance.
- Do not apply multiple fixes simultaneously — you won't know which one worked.

## Safe Behavior

- Measurement tools (profilers, EXPLAIN) are read-only.
- Optimizations are applied one at a time with measurement between each.
- Do not push performance changes to production without a verified before/after delta.
- If profiling requires production traffic, flag to Ahmed — production instrumentation is high-risk.
