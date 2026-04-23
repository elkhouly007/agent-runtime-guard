# Python Coding Style

Python-specific coding standards. These extend the common coding-style rules.

## Formatting

- Use black for formatting. No configuration overrides. Consistent formatting is more important than personal preference.
- Use isort for import ordering. Standard library, third-party, local — each group separated by a blank line.
- Line length: 88 characters (black default). Never manually break lines that black would not break.

## Naming

- Functions and variables: `snake_case`.
- Classes: `PascalCase`.
- Constants: `UPPER_SNAKE_CASE`.
- Private attributes and methods: `_single_leading_underscore`. Dunder methods: `__double_leading_and_trailing__`.
- Module-level names intended to be public should appear in `__all__`.

## Type Annotations

- Annotate all function signatures in production code: parameters and return types.
- Use `from __future__ import annotations` to enable postponed evaluation (cleaner union syntax).
- Use `Optional[T]` or `T | None` for nullable values. Never return `None` from a function typed to return a value.
- Prefer `Sequence[T]` over `List[T]` for function parameters that only need iteration.
- Run mypy or pyright in strict mode. Type annotations without a type checker are suggestions, not guarantees.

## Pythonic Patterns

- Use context managers (`with` statements) for all resource acquisition/release.
- Use list/dict/set comprehensions over explicit loops when the transformation is simple.
- Prefer `enumerate()` over `range(len())` for indexed iteration.
- Use `collections.defaultdict`, `Counter`, and `namedtuple` where they express intent more clearly.
- Dataclasses or attrs over manual `__init__` for data-holding classes.

## Anti-Patterns

- Never use mutable default arguments in function signatures. Use `None` and initialize inside the function.
- Never bare `except:` or `except Exception:` without re-raising or logging with the traceback.
- Never `import *` except in `__init__.py` files, and even there with explicit `__all__`.
- Never compare to `True`, `False`, or `None` with `==`. Use `is`, `is not`, or truthy/falsy checks.
