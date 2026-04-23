# Swift Design Patterns

Swift-specific patterns for safe, idiomatic code.

## Protocol-Oriented Programming

Define behavior through protocols:

```swift
protocol DataStore {
    func fetch<T: Decodable>(_ type: T.Type, id: UUID) async throws -> T?
    func save<T: Encodable>(_ value: T) async throws
}

// Production implementation
final class CoreDataStore: DataStore { ... }
// Test implementation
final class InMemoryStore: DataStore { ... }
```

## Result Builders

Use `@resultBuilder` for DSLs:

```swift
@resultBuilder struct ValidationBuilder {
    static func buildBlock(_ rules: ValidationRule...) -> [ValidationRule] { rules }
}

func validate(@ValidationBuilder _ rules: () -> [ValidationRule]) -> ValidationResult {
    return rules().reduce(.valid) { $0.and($1.check()) }
}
```

## Property Wrappers

Encapsulate cross-cutting concerns:

```swift
@propertyWrapper struct Clamped<T: Comparable> {
    private var value: T
    let range: ClosedRange<T>
    var wrappedValue: T {
        get { value }
        set { value = min(max(newValue, range.lowerBound), range.upperBound) }
    }
}
```

## Async Sequences

```swift
struct EventStream: AsyncSequence {
    typealias Element = Event
    func makeAsyncIterator() -> EventIterator { EventIterator() }
}

for await event in EventStream() {
    handle(event)
}
```

## Value Types with Copy-on-Write

Implement copy-on-write for expensive value types:

```swift
struct LargeData {
    private var _storage: StorageClass
    mutating func modify() {
        if !isKnownUniquelyReferenced(&_storage) { _storage = _storage.copy() }
        _storage.mutate()
    }
}
```
