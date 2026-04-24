---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# TypeScript Design Patterns

TypeScript-specific patterns for type-safe, maintainable code.

## Discriminated Unions

Model state machines and sum types with discriminated unions:

```typescript
type Result<T, E> =
  | { ok: true; value: T }
  | { ok: false; error: E };
```

Always use exhaustive checking with switch statements over discriminated unions. The compiler catches missing cases when noImplicitReturns is enabled.

## Branded Types

Prevent primitive type confusion with branded types:

```typescript
type UserId = string & { readonly _brand: "UserId" };
type OrderId = string & { readonly _brand: "OrderId" };
function makeUserId(id: string): UserId { return id as UserId; }
```

`UserId` and `OrderId` are both strings at runtime but distinct types at compile time. Passing an `OrderId` where a `UserId` is expected is a compile error.

## Builder Pattern for Complex Objects

For objects with many optional fields, the builder pattern provides a type-safe construction API:

```typescript
class QueryBuilder {
  private query: Partial<Query> = {};
  where(condition: Condition): this { ... }
  limit(n: number): this { ... }
  build(): Query { ... }
}
```

## Mapped Types for Transformations

Use mapped types for systematic transformations:

```typescript
type ReadOnly<T> = { readonly [K in keyof T]: T[K] };
type Partial<T> = { [K in keyof T]?: T[K] };
type Required<T> = { [K in keyof T]-?: T[K] };
```

## Template Literal Types

For string-based APIs, template literal types catch string construction errors at compile time:

```typescript
type EventName = `on${Capitalize<string>}`;
type CSSProperty = `${string}-${string}`;
```
