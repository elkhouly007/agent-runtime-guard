---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Swift Testing Rules

## Toolchain

- XCTest for unit and integration tests (built-in, no dependency needed).
- Swift Testing (`@Test`, `#expect`) for new code — available from Swift 5.9/Xcode 15.
- Protocol-based fakes over third-party mocking frameworks.
- `@MainActor` and `async/await` in tests for concurrency.

## XCTest Naming

```swift
// test_[method]_[scenario]_[expected] or plain descriptive names
func testCreateOrder_validInput_returnsOrder() { ... }
func testCreateOrder_blankProductId_throwsValidationError() { ... }
```

## Swift Testing (Modern — Xcode 15+)

```swift
import Testing

@Suite("OrderService")
struct OrderServiceTests {

    @Test("creates order with valid input")
    func createOrderValidInput() async throws {
        let repo = FakeOrderRepository()
        let service = OrderService(repository: repo)

        let order = try await service.create(productId: "p1", quantity: 2)

        #expect(order.productId == "p1")
        #expect(repo.savedOrders.count == 1)
    }

    @Test("throws when quantity is zero", arguments: [0, -1, -100])
    func createOrderInvalidQuantity(quantity: Int) async {
        let service = OrderService(repository: FakeOrderRepository())
        await #expect(throws: ValidationError.self) {
            try await service.create(productId: "p1", quantity: quantity)
        }
    }
}
```

- `#expect` replaces `XCTAssert*` — cleaner syntax, better failure messages.
- `@Test(..., arguments:)` replaces table-driven pattern.

## XCTest Async Tests

```swift
func testFetchUser_existingId_returnsUser() async throws {
    let repo = FakeUserRepository(users: ["1": User(id: "1", name: "Ahmed")])
    let service = UserService(repository: repo)

    let user = try await service.getUser(id: "1")

    XCTAssertEqual(user.name, "Ahmed")
}
```

- Use `async throws` test methods — not `XCTestExpectation` for async code.
- `XCTestExpectation` is only needed for callback-based (non-async) code.

## Protocol Fakes

```swift
protocol OrderRepository {
    func save(_ order: Order) async throws
    func findById(_ id: String) async throws -> Order?
}

final class FakeOrderRepository: OrderRepository {
    private(set) var savedOrders: [Order] = []
    var stubbedOrder: Order?

    func save(_ order: Order) async throws {
        savedOrders.append(order)
    }

    func findById(_ id: String) async throws -> Order? {
        stubbedOrder
    }
}
```

- Fakes are simple and readable — prefer them over `@objc protocol` + OCMock.
- For complex interaction verification, consider using a mocking library like Mockingbird.

## MainActor Tests

```swift
@MainActor
final class ProfileViewModelTests: XCTestCase {
    func testLoadPopulatesUser() async throws {
        let vm = ProfileViewModel(repository: FakeUserRepository())
        await vm.load(userId: "1")
        XCTAssertNotNil(vm.user)
    }
}
```

- Annotate the test class with `@MainActor` if the ViewModel is `@MainActor`-isolated.

## Test Setup and Teardown

```swift
override func setUp() async throws {
    try await super.setUp()
    // async setup
}

override func tearDown() async throws {
    // async cleanup
    try await super.tearDown()
}
```

## What NOT to Test

- SwiftUI view body rendering (use Previews for visual validation).
- Auto-synthesized `Codable` conformance for simple structs.
- Compiler-enforced contracts (non-optional unwrapping, enum exhaustiveness).
