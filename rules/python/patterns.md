---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Python Design Patterns

Python-specific design patterns and idioms for amplifying code quality.

## Protocols and ABCs

- Prefer `Protocol` (from `typing`) over abstract base classes for interface definition. Protocols enable structural subtyping (duck typing with static checking).
- Use ABCs when you need `isinstance` checks or want to enforce method implementation at class creation time.
- Document the expected interface with a Protocol even if you do not enforce it. This makes intentions explicit.

## Functional Patterns

- `functools.lru_cache` or `functools.cache` for memoizing expensive pure functions.
- `functools.partial` for creating specialized versions of general functions.
- Generator functions for lazy sequences that avoid loading all data into memory.
- `itertools` for composing iterators: `chain`, `groupby`, `islice`, `product`.

## Context Managers

- Implement `__enter__` and `__exit__` for any resource that needs guaranteed cleanup.
- `contextlib.contextmanager` for simpler context manager construction via generators.
- `contextlib.suppress` for swallowing specific exceptions cleanly.
- `contextlib.ExitStack` for dynamically composing multiple context managers.

## Dataclasses and Attrs

- `@dataclass` for simple data containers. Set `frozen=True` for immutable data.
- `@dataclass(slots=True)` for memory efficiency in high-frequency objects.
- `attrs` for more control: validators, converters, and factory defaults.
- `pydantic.BaseModel` for data with validation requirements (especially at API boundaries).

## Error Handling Patterns

- Custom exception hierarchy: `ApplicationError` as base, specific errors inheriting from it.
- Include context in exceptions: the invalid value, the constraint violated, the operation attempted.
- Result pattern with `typing.Union` or `typing.TypeVar` for functions that want to return errors without raising.
- `contextlib.suppress` for known, expected exceptions that should not propagate.
