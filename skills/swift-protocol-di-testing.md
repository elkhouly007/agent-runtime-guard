# Skill: swift-protocol-di-testing

## Purpose

Apply protocol-based dependency injection in Swift for testable, modular code — define protocols for dependencies, inject them at init, and swap in fakes/mocks in tests.

## Trigger

- Making a Swift class testable by replacing hard dependencies (network, DB, location, etc.)
- Designing a new feature that needs to be testable without real infrastructure
- Reviewing Swift code that is hard to test due to concrete dependencies

## Trigger

`/swift-protocol-di-testing` or `apply swift protocol DI to [target]`

## Agents

- `code-reviewer` — architecture and Swift patterns

## Patterns

### Define a Protocol for Each Dependency

```swift
// Protocol — the contract
protocol UserRepository {
    func fetchUser(id: String) async throws -> User
    func save(_ user: User) async throws
}

// Real implementation
final class RemoteUserRepository: UserRepository {
    func fetchUser(id: String) async throws -> User {
        return try await APIClient.shared.getUser(id: id)
    }
    func save(_ user: User) async throws {
        try await APIClient.shared.updateUser(user)
    }
}
```

### Inject at Init

```swift
final class ProfileViewModel: ObservableObject {
    private let repository: UserRepository  // protocol, not concrete type

    init(repository: UserRepository = RemoteUserRepository()) {
        self.repository = repository
    }

    func load(userId: String) async {
        do {
            let user = try await repository.fetchUser(id: userId)
            await MainActor.run { self.user = user }
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }
}
```

- Default argument `= RemoteUserRepository()` means production code requires no change.
- Tests inject a fake without touching production code.

### Fake for Testing (Preferred over Mocks)

```swift
final class FakeUserRepository: UserRepository {
    var stubbedUser: User?
    var savedUsers: [User] = []
    var shouldThrow = false

    func fetchUser(id: String) async throws -> User {
        if shouldThrow { throw URLError(.notConnectedToInternet) }
        return stubbedUser ?? User(id: id, name: "Test User")
    }

    func save(_ user: User) async throws {
        savedUsers.append(user)
    }
}
```

- Fakes are simple hand-written implementations — easier to read than generated mocks.
- Use mocking frameworks (e.g., `Mockingbird`) only when fakes become complex.

### Testing with Fakes

```swift
@MainActor
final class ProfileViewModelTests: XCTestCase {
    func testLoadPopulatesUser() async throws {
        let fake = FakeUserRepository()
        fake.stubbedUser = User(id: "1", name: "Ahmed")
        let vm = ProfileViewModel(repository: fake)

        await vm.load(userId: "1")

        XCTAssertEqual(vm.user?.name, "Ahmed")
    }

    func testLoadShowsErrorOnFailure() async throws {
        let fake = FakeUserRepository()
        fake.shouldThrow = true
        let vm = ProfileViewModel(repository: fake)

        await vm.load(userId: "1")

        XCTAssertNotNil(vm.errorMessage)
    }
}
```

### SwiftUI Preview Integration

```swift
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(viewModel: ProfileViewModel(repository: FakeUserRepository()))
    }
}
```

- The same fake used in tests works in SwiftUI previews — no real network in Xcode canvas.

### Trigger Protocols vs Structs

- Use `protocol` when you need multiple implementations (real + fake + stub).
- Use `struct` with a function property for simpler single-dependency cases.
- Do not add protocols speculatively — only when you have (or will soon have) multiple implementations.

## Safe Behavior

- Analysis only unless asked to modify code.
- Follow `rules/swift/coding-style.md`.
