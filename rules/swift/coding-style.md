---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Swift Coding Style

## Swift-Specific Idioms

- `let` by default; `var` only when mutation is needed.
- Use `guard` for early exits — prefer it over `if let` for failure paths.
- Trailing closure syntax for single closure arguments.
- Computed properties over methods for derived values with no side effects.
- `struct` for value semantics (most models); `class` only when identity matters or inheritance is needed.

```swift
// BAD — var where let suffices
var name = user.name
print(name)

// GOOD
let name = user.name

// BAD — nested if let
func process(user: User?) {
    if let user = user {
        if let email = user.email {
            send(email)
        }
    }
}

// GOOD — guard for early exit
func process(user: User?) {
    guard let user = user, let email = user.email else { return }
    send(email)
}

// Trailing closure
users.sorted { $0.name < $1.name }

// Computed property (no side effects)
var fullName: String { "\(firstName) \(lastName)" }
```

## Optional Handling

- `guard let` or `if let` for safe unwrapping.
- `??` for default values.
- `!` (force unwrap) only when the value is guaranteed to be non-nil — document why.
- `try?` for expected failures; `try` with proper error handling for unexpected ones.

```swift
// BAD — force unwrap without justification
let image = UIImage(named: "logo")!

// GOOD — safe unwrap with fallback
let image = UIImage(named: "logo") ?? UIImage(systemName: "photo")!
// ^ system name is always available — force unwrap justified here

// BAD
let result = try! fetchData()

// GOOD — proper error handling
do {
    let result = try fetchData()
    process(result)
} catch {
    logger.error("fetchData failed: \(error)")
}

// GOOD — expected failure → optional
let parsed = try? JSON.decode(data)
```

## Error Handling

- Define typed errors with `enum X: Error`.
- `do-try-catch` for recoverable errors.
- `try?` to convert to optional — only when failure is expected and the default behavior is correct.
- Never use `try!` in production code.

```swift
enum NetworkError: Error {
    case invalidURL
    case unauthorized
    case serverError(statusCode: Int)
    case decodingFailed(underlying: Error)
}

func fetchUser(id: String) async throws -> User {
    guard let url = URL(string: "\(baseURL)/users/\(id)") else {
        throw NetworkError.invalidURL
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw NetworkError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }
    do {
        return try JSONDecoder().decode(User.self, from: data)
    } catch {
        throw NetworkError.decodingFailed(underlying: error)
    }
}
```

## Concurrency (Swift Concurrency)

- `async/await` for all asynchronous code (Swift 5.5+).
- `@MainActor` for UI updates.
- `Task` for launching async work; `TaskGroup` for parallel work.
- `actor` for safe shared mutable state.
- Cancel tasks when the owning view disappears.

```swift
// @MainActor — UI always on main thread
@MainActor
class UserViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var error: String?

    func load() async {
        do {
            users = try await userService.fetchAll()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// actor — safe shared mutable state
actor Cache {
    private var storage: [String: User] = [:]

    func set(_ user: User, for key: String) {
        storage[key] = user
    }

    func get(for key: String) -> User? {
        storage[key]
    }
}

// TaskGroup — parallel work
let users = try await withThrowingTaskGroup(of: User.self) { group in
    for id in ids {
        group.addTask { try await fetchUser(id: id) }
    }
    return try await group.reduce(into: []) { $0.append($1) }
}
```

## SwiftUI (when applicable)

```swift
// State ownership rules
struct ParentView: View {
    @State private var isShowing = false          // owned by this view
    @StateObject private var vm = UserViewModel() // owned lifetime

    var body: some View {
        ChildView(isShowing: $isShowing)          // pass binding down
            .environmentObject(vm)                // share via environment
    }
}

struct ChildView: View {
    @Binding var isShowing: Bool                  // two-way from parent
    @EnvironmentObject var vm: UserViewModel      // from ancestor

    var body: some View {
        Button("Toggle") { isShowing.toggle() }
    }
}
```

## Code Quality

- Follow Swift API Design Guidelines (swift.org/documentation/api-design-guidelines).
- Run `SwiftLint` with a project-standard config.
- Prefer value types — they are safer and more predictable.
- Test with `XCTest` — or `swift-testing` (Swift 6+).

## Tooling

```bash
# Lint
swiftlint lint

# Auto-fix lint issues
swiftlint --fix

# Format
swift-format format --in-place Sources/

# Run tests
swift test

# Build for release
swift build -c release
```

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `var` for non-mutated values | Use `let` |
| Force unwrap `!` without comment | Guard or provide default |
| `try!` in production | `do { try } catch { }` |
| Nested `if let` chains | `guard let x, let y else { return }` |
| `DispatchQueue.main.async` for UI | `@MainActor` |
| Raw `Thread` or `DispatchQueue` for data | `actor` |
