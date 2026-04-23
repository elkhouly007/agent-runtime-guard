# Skill: swift-actor-persistence

## Purpose

Apply Swift Actor-based persistence patterns — thread-safe data stores, SwiftData/CoreData actor integration, and safe concurrent access to persistent state.

## Trigger

- Building a Swift app with persistent state that is accessed from multiple async contexts
- Diagnosing data races or `@MainActor` violations in a persistence layer
- Migrating from a non-actor-safe store to an actor-isolated one

## Trigger

`/swift-actor-persistence` or `apply swift actor persistence to [target]`

## Agents

- `swift-reviewer` (if available) or `code-reviewer` — Swift concurrency review

## Patterns

### Actor-Isolated Store

```swift
actor UserStore {
    private var cache: [String: User] = [:]
    private let db: DatabaseClient

    init(db: DatabaseClient) {
        self.db = db
    }

    func user(for id: String) async throws -> User {
        if let cached = cache[id] { return cached }
        let user = try await db.fetchUser(id: id)
        cache[id] = user
        return user
    }

    func update(_ user: User) async throws {
        try await db.save(user)
        cache[user.id] = user
    }
}
```

- `actor` serializes access automatically — no locks needed.
- All mutations go through the actor — no external direct mutation of state.

### SwiftData with MainActor

```swift
@MainActor
final class OrderViewModel: ObservableObject {
    @Published var orders: [Order] = []
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func load() throws {
        orders = try context.fetch(FetchDescriptor<Order>())
    }

    func add(order: Order) throws {
        context.insert(order)
        try context.save()
        orders.append(order)
    }
}
```

- `ModelContext` is not `Sendable` — only use it on the actor it was created on.
- Use `@MainActor` for ViewModels that drive SwiftUI views.

### Background Processing with Actor Bridging

```swift
actor SyncEngine {
    private let store: UserStore

    func syncAll() async throws {
        let remoteUsers = try await APIClient.shared.fetchAll()
        for user in remoteUsers {
            try await store.update(user)
        }
    }
}

// Usage from SwiftUI
Task {
    try await syncEngine.syncAll()
    await MainActor.run { viewModel.reload() }
}
```

- Do heavy work in background actors — switch to `MainActor` only for UI updates.
- Use `await MainActor.run { }` to update UI from a background actor.

### Sendable Conformance

```swift
// Value types are Sendable by default if all stored properties are Sendable
struct User: Sendable {
    let id: String
    let name: String
}

// Reference types need explicit conformance + isolation guarantee
@MainActor
final class AppState: ObservableObject {
    // Implicitly Sendable because it's MainActor-isolated
}
```

- Use value types (`struct`) for model objects — they are `Sendable` by default.
- Mark `final class` with `@MainActor` or `actor` to be `Sendable`.

### Avoiding Common Pitfalls

- **Do not capture `self` of an actor in a `Task` and then mutate from outside** — always go through the actor.
- **Do not use `nonisolated(unsafe)` or `@unchecked Sendable`** unless you have explicit lock-based protection.
- **Avoid global mutable state** — if you need shared state, put it in an actor.

## Safe Behavior

- Analysis only unless asked to modify code.
- Follow `rules/swift/coding-style.md` and `rules/swift/security.md`.
