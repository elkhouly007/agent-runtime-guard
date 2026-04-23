# Skill: Swift 6.2 Approachable Concurrency

## Trigger

Use when writing or reviewing Swift code that involves async/await, actors, TaskGroup, @MainActor, Sendable conformance, or migrating code to Swift 6 strict concurrency.

## Pre-Concurrency Checklist

Before writing or reviewing concurrent Swift code:
- [ ] Identify which data crosses actor boundaries (the root cause of 90% of Swift 6 errors).
- [ ] Decide on structured vs. unstructured concurrency (prefer structured unless you have a reason).
- [ ] Check if the type truly needs to be Sendable or if you can eliminate the crossing entirely.
- [ ] Confirm @MainActor is justified — it is a serialization point, not a magic safety blanket.

## Process

### 1. Enable strict concurrency incrementally

In `Package.swift`, ramp up per-target rather than project-wide:

```swift
// Package.swift
.target(
    name: "MyFeature",
    swiftSettings: [
        // Step 1: warnings only — see what breaks without blocking CI
        .swiftLanguageVersion(.v5),
        .unsafeFlags(["-strict-concurrency=complete"]),

        // Step 2: when warnings are clean, flip to Swift 6
        // .swiftLanguageVersion(.v6),
    ]
)
```

In Xcode: Build Settings → Swift Language Version → Swift 6 (per target, not project).

### 2. Understand the three actor isolation models

| Model | Declaration | Use when |
|-------|-------------|----------|
| Global actor | `@MainActor class Foo` | UI types, ViewModels |
| Actor | `actor Foo` | Shared mutable state accessed concurrently |
| Nonisolated | `nonisolated func foo()` | Stateless utilities, pure computation |

### 3. Structured vs. unstructured concurrency

**Prefer structured** — scope is clear, cancellation propagates, errors surface:

```swift
// Structured: TaskGroup — all child tasks cancel if parent cancels
func fetchAll(ids: [String]) async throws -> [Article] {
    try await withThrowingTaskGroup(of: Article.self) { group in
        for id in ids {
            group.addTask { try await API.fetch(id: id) }
        }
        return try await group.reduce(into: []) { $0.append($1) }
    }
}
```

**Unstructured only when necessary** (fire-and-forget, outlives caller):

```swift
// Unstructured — caller does not wait, task escapes scope
// Use Task { } to inherit actor context
// Use Task.detached { } to get a clean context (no actor, no task-local values)
func scheduleRefresh() {
    Task { @MainActor in          // inherits MainActor because caller is @MainActor
        await refreshFeed()
    }
}
```

### 4. Actor for shared mutable state

```swift
actor ImageCache {
    private var store: [URL: UIImage] = [:]

    func image(for url: URL) -> UIImage? {
        store[url]
    }

    func store(_ image: UIImage, for url: URL) {
        store[url] = image
    }
}

// Caller — must await every access
let cache = ImageCache()
let img = await cache.image(for: url)
await cache.store(downloaded, for: url)
```

Actors serialize access; you cannot have a data race on actor-isolated properties.

### 5. @MainActor — global actor for UI

```swift
@MainActor
final class FeedViewModel: ObservableObject {
    @Published var articles: [Article] = []

    // This function is automatically @MainActor — safe to touch @Published
    func load() async {
        do {
            // Hop off MainActor for network work
            let fetched = try await Task.detached(priority: .userInitiated) {
                try await API.fetchFeed()     // runs off main thread
            }.value
            articles = fetched               // back on MainActor, safe
        } catch {
            // handle
        }
    }
}
```

Rule: annotate the whole type with `@MainActor` instead of individual methods when most of its surface is UI-facing.

### 6. Sendable — the right tool for each case

| Situation | Solution |
|-----------|----------|
| Value type (struct/enum) with Sendable members | Synthesized automatically in Swift 6 |
| Reference type with internal lock | `@unchecked Sendable` + document why |
| Global var you cannot refactor right now | `nonisolated(unsafe) var` (Swift 5.10+) |
| Type you own, can make safe | Proper actor or `@MainActor` isolation |

```swift
// @unchecked Sendable — you assert safety, compiler trusts you
// Document the invariant or this becomes a landmine
final class AtomicCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0

    var value: Int {
        lock.withLock { _value }
    }

    func increment() {
        lock.withLock { _value += 1 }
    }
}

// nonisolated(unsafe) — for globals that are set-once before concurrency starts
// NOT for mutable state accessed from multiple tasks
nonisolated(unsafe) var globalConfig: AppConfig = .default
```

### 7. Isolated parameters (Swift 5.9+)

Pass an actor instance as an isolation parameter to allow callers to choose the execution context:

```swift
// Without isolated parameter — always hops to `cache`'s executor
func prewarm(cache: ImageCache) async { ... }

// With isolated parameter — runs on the actor the caller passes in
// Useful for protocol conformances and flexible utilities
func prewarm(isolation: isolated any Actor = #isolation) async {
    // runs on the caller's actor without an extra hop
}
```

`#isolation` captures the calling context's isolation — a Swift 6 feature for zero-hop utilities.

### 8. Common Swift 6 migration errors and fixes

**Error: Sending 'x' risks causing data races**
```swift
// Bad — closure captures non-Sendable value across actor boundary
actor Worker {
    func process(_ handler: () -> Void) {  // () -> Void is not Sendable
        Task { handler() }                  // ERROR: handler crosses to Task
    }
}

// Fix — require @Sendable
actor Worker {
    func process(_ handler: @Sendable () -> Void) {
        Task { handler() }                  // OK
    }
}
```

**Error: Call to main actor-isolated property from nonisolated context**
```swift
// Bad
class DataLoader {
    var viewModel: FeedViewModel        // @MainActor
    func loadSync() {
        viewModel.articles = []         // ERROR: nonisolated cannot touch @MainActor property
    }
}

// Fix — make the method async and await the hop
class DataLoader {
    var viewModel: FeedViewModel
    func load() async {
        await viewModel.articles = []   // explicit hop to MainActor
    }
}
```

**Error: Stored property of 'Sendable'-conforming class is mutable**
```swift
// Bad
final class Config: Sendable {
    var timeout: Int = 30              // ERROR: mutable var in Sendable class
}

// Fix option A — immutable
final class Config: Sendable {
    let timeout: Int

    init(timeout: Int = 30) { self.timeout = timeout }
}

// Fix option B — @unchecked if you need mutability with a lock
final class Config: @unchecked Sendable { ... }
```

### 9. TaskGroup patterns

```swift
// Parallel fetch with bounded concurrency
func fetchPages(urls: [URL], maxConcurrent: Int = 4) async throws -> [Data] {
    try await withThrowingTaskGroup(of: (Int, Data).self) { group in
        var results = [Data?](repeating: nil, count: urls.count)
        var inFlight = 0

        for (index, url) in urls.enumerated() {
            if inFlight >= maxConcurrent {
                // drain one before adding another
                let (i, data) = try await group.next()!
                results[i] = data
                inFlight -= 1
            }
            group.addTask { (index, try await URLSession.shared.data(from: url).0) }
            inFlight += 1
        }

        for try await (i, data) in group {
            results[i] = data
        }

        return results.compactMap { $0 }
    }
}
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|--------------|---------|-----|
| `Task.detached` everywhere | Loses actor context, suppresses cancellation propagation | Use `Task { }` to inherit context |
| `@unchecked Sendable` without a lock | Just suppresses the error; race condition exists | Add a real lock or use an actor |
| `nonisolated(unsafe)` on mutable shared state | Undefined behavior across threads | Use actor or lock-protected wrapper |
| `@MainActor` on background-heavy types | Blocks UI thread | Isolate only the UI-touching layer |
| Ignoring `Task.isCancelled` in long loops | Tasks that never stop after cancellation | Check `try Task.checkCancellation()` |
| `await` inside a `for` loop when order doesn't matter | Sequential instead of parallel | Use TaskGroup |

## Safe Behavior

- Read-only analysis in review context — does not modify source files.
- Does not approve its own output.
- CRITICAL concurrency findings (races, deadlocks) require Ahmed's attention before merge.
- Does not bypass Swift 6 warnings with `@unchecked` without documenting the invariant.
