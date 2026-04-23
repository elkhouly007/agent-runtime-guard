# Design Patterns

Universal design patterns and principles that apply across languages and domains.

## Core Principles

**Single Responsibility**: Every module, class, and function should have exactly one reason to change. When something has multiple reasons to change, it has multiple responsibilities and should be split.

**Open/Closed**: Open for extension, closed for modification. Design components so new behavior can be added without modifying existing code. Achieved through composition, interfaces, and dependency injection.

**Dependency Inversion**: Depend on abstractions, not implementations. High-level modules should not depend on low-level modules. Both should depend on abstractions. This enables testing and flexibility.

**Composition over Inheritance**: Prefer building complex behavior by composing simple objects over inheriting from complex classes. Inheritance creates tight coupling; composition is flexible.

## Patterns That Amplify

**Repository Pattern**: Separate data access from business logic. Business logic tests do not need a database; they test against an interface. Data access code handles all the persistence concerns.

**Command/Query Separation**: Functions either change state (commands) or return data (queries), but not both. This makes reasoning about state much simpler.

**Result Type Pattern**: Functions that can fail return a Result<Value, Error> type instead of throwing or returning null. Error handling becomes explicit and composable.

**Observer/Event Pattern**: Decouple producers from consumers. The component that produces an event does not need to know who consumes it. New consumers can be added without modifying the producer.

**Factory Pattern**: Centralize complex object construction. When building an object requires multiple steps or decisions, a factory makes the complexity explicit and testable.

## Anti-Patterns to Avoid

**God Object**: A class that knows too much and does too much. Split it along responsibility lines.

**Shotgun Surgery**: A single change requires modifications in many places. Indicates logic that should be centralized.

**Feature Envy**: A function that accesses the data of another class more than its own. The function probably belongs on that other class.

**Premature Optimization**: Optimizing code before it is proven to be a bottleneck. Measure first. Optimize where the measurement says it matters.

**Stringly Typed**: Using strings to represent structured data (status codes, type discriminators, identifiers). Use proper types instead.

## Amplification-First Patterns

**Learning from Operation**: Systems should emit signals about their own behavior. These signals feed back into improved behavior. Design for this loop from the beginning.

**Explicit State Machines**: When a system has states and transitions, make them explicit in the type system or in named state management. Implicit state machines are the source of most "the system got into a weird state" bugs.

**Idempotency**: Operations that can safely be retried without additional side effects. Critical for reliability in distributed systems and scheduled jobs.
