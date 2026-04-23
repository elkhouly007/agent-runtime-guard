---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Swift Testing

Swift-specific testing standards.

## Framework

- XCTest for unit, integration, and UI tests.
- Swift Testing (Swift 6+) as an alternative with better syntax.
- `XCTestExpectation` for async testing in older code.
- `async/await` in tests with `@MainActor` where needed.

## Test Structure

- Test classes: `UserRepositoryTests` inheriting from `XCTestCase`.
- Test methods: `testFetchUser_returnsUser_whenFound()`.
- `setUpWithError()` and `tearDownWithError()` for setup and teardown.

## Swift Testing Syntax (Swift 6+)

```swift
@Test func fetchUser_returnsUser_whenFound() async throws {
    let repository = UserRepository(session: .mock)
    let user = try await repository.findById(userId)
    #expect(user.id == userId)
}

@Test("rejects invalid emails", arguments: ["", "notanemail", "@nodomain"])
func rejectsInvalidEmail(email: String) {
    #expect(throws: ValidationError.self) {
        try EmailAddress(rawValue: email)
    }
}
```

## Async Testing

- `async/await` tests: mark test function as `async throws`.
- `withCheckedThrowingContinuation` for bridging completion-handler code in tests.
- `Task { ... }` for detached work in tests — `await` the result.

## Mocking

- Protocol-based dependency injection enables mocking without frameworks.
- `@testable import` to access internal types in tests.
- Spy objects: store calls made to dependencies for verification.
