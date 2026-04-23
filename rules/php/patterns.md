---
paths:
  - "**/*.php"
  - "**/composer.json"
last_reviewed: 2026-04-22
version_target: "Best Practices"
---
# PHP Patterns

> This file extends [common/patterns.md](../common/patterns.md) with PHP-specific content.

## Thin Controllers, Explicit Services

- Keep controllers focused on transport: auth, validation, serialization, and status codes
- Move business rules into application or domain services that are easy to test without full HTTP bootstrapping

## DTOs and Value Objects

- Replace shape-heavy associative arrays with DTOs for requests, commands, and external API payloads
- Use value objects for money, identifiers, date ranges, and other constrained concepts

## Dependency Injection

- Depend on interfaces or narrow service contracts, not framework globals
- Pass collaborators through constructors so services remain testable without service-locator lookups

## Boundaries

- Isolate ORM models from domain decisions when the model layer is doing more than persistence
- Wrap third-party SDKs behind small adapters so the rest of the codebase depends on your contract, not theirs

## Reference

See skill: `api-design` for endpoint conventions and response-shape guidance.
See skill: `laravel-patterns` for Laravel-specific architecture guidance.
