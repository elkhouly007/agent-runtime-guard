# Performance

Universal performance principles. Apply these regardless of language or domain.

## Measure Before You Optimize

- Every performance improvement starts with a measurement. Without a baseline, you cannot verify improvement and you cannot prioritize work.
- Profile actual code on realistic data. Synthetic benchmarks on small data do not predict production behavior.
- Find the dominant cost before optimizing anything. Optimizing a component that represents 5% of total time gives at most 5% improvement.
- The profiler is more reliable than intuition. Where you think the bottleneck is is usually wrong.

## Algorithmic Complexity

- Complexity improvements are more valuable than constant-factor improvements. O(n log n) beats O(n squared) at any scale.
- Understand the complexity of every algorithm and data structure you use. Know when linear scan beats binary search (small n, poor cache behavior).
- N+1 query patterns are the most common source of unexpected quadratic complexity. Find them before they reach production.

## I/O Patterns

- I/O is orders of magnitude slower than computation. Minimize I/O operations and maximize data transferred per operation.
- Batch I/O operations: one database query returning 100 rows is far faster than 100 queries returning 1 row each.
- Cache the results of expensive I/O at the right level: in-process memory, distributed cache, or database materialized view.
- Async I/O for operations that can proceed in parallel. Synchronous sequential I/O is a throughput bottleneck.

## Memory Management

- Memory allocation is not free. High-frequency allocation of short-lived objects stresses the garbage collector.
- Object pooling for objects that are expensive to create and frequently discarded.
- Prefer value types over reference types in hot paths (where the language supports the distinction).
- Watch for memory leaks: objects retained longer than necessary prevent garbage collection. Common sources: event listeners, caches without eviction, long-lived collections that grow without bound.

## Latency vs. Throughput

- Latency (time for one operation) and throughput (operations per unit time) are different metrics with different optimization strategies.
- Improving latency often requires reducing per-request work. Improving throughput often requires parallelism.
- Tail latency (p99, p999) matters more than mean latency for user-facing systems. Mean latency can be great while p99 is terrible.
- Set latency budgets. Know your latency target and measure against it. Without a target, "fast enough" has no definition.
