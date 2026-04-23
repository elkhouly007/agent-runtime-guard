---
paths:
  - "**/*.py"
  - "**/*.pyi"
last_reviewed: 2026-04-22
version_target: "Best Practices"
---
# Python Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Python-specific content.

## Protocol (Duck Typing)

Prefer structural typing for pluggable dependencies:

```python
from typing import Protocol

class Repository(Protocol):
    def find_by_id(self, id: str) -> dict | None: ...
    def save(self, entity: dict) -> dict: ...
```

Use Protocols when consumers care about behavior, not inheritance trees.

## Dataclasses as DTOs

Use dataclasses for explicit request/response and transport objects:

```python
from dataclasses import dataclass

@dataclass
class CreateUserRequest:
    name: str
    email: str
    age: int | None = None
```

Prefer immutable DTOs (`frozen=True`) when mutation is not required.

## Context Managers and Generators

- Use context managers (`with`) for resource management
- Use generators for lazy evaluation and memory-efficient iteration
- Prefer iterators/streams for large datasets over loading everything at once

## Dependency Injection by Construction

Pass collaborators in explicitly rather than constructing them inside functions or classes:

```python
class UserService:
    def __init__(self, repo: UserRepo, mailer: Mailer) -> None:
        self.repo = repo
        self.mailer = mailer
```

## Value Objects Over Naked Dicts

Use small typed objects for domain concepts when meaning matters. Reserve raw dicts for loose transport boundaries.

## References

See skill: `python-patterns` for broader guidance including decorators, concurrency, and package organization.
