---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Python Coding Style

## Type Hints

- All function signatures must have type hints (PEP 484).
- Use `T | None` (Python 3.10+) over `Optional[T]` — the union syntax is cleaner and avoids the `typing` import.
- Run `mypy` or `pyright` in strict mode in CI.
- Avoid `# type: ignore` — fix the underlying issue instead.
- Use `TypeVar` for generic functions and `ParamSpec` for decorator signatures.
- Use `Protocol` to express structural subtyping instead of abstract base classes when duck typing is appropriate.

```python
# BAD — old Optional syntax, untyped params, no return annotation
from typing import Optional, List
def get_user(user_id, include_deleted=False) -> Optional[dict]:
    ...

# GOOD — modern union syntax, full annotations
def get_user(user_id: int, include_deleted: bool = False) -> User | None:
    ...

# TypeVar for generic utility
from typing import TypeVar
T = TypeVar("T")

def first(items: list[T]) -> T | None:
    return items[0] if items else None

# ParamSpec preserves decorator signature
from typing import ParamSpec, Callable
P = ParamSpec("P")

def retry(fn: Callable[P, T]) -> Callable[P, T]:
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> T:
        return fn(*args, **kwargs)
    return wrapper

# Protocol — structural typing, no inheritance required
from typing import Protocol

class Closeable(Protocol):
    def close(self) -> None: ...

def cleanup(resource: Closeable) -> None:
    resource.close()
```

## Immutability and Data

- Prefer dataclasses or Pydantic models over plain dicts for structured data.
- Use `@dataclass(frozen=True)` for immutable value objects.
- Use `NamedTuple` for simple read-only record types where tuple compatibility matters.
- Never use mutable default arguments.

```python
# BAD — mutable default argument, shared across all calls
def add_tag(item, tags=[]):
    tags.append(item)
    return tags

# GOOD
def add_tag(item: str, tags: list[str] | None = None) -> list[str]:
    if tags is None:
        tags = []
    tags.append(item)
    return tags

# Frozen dataclass — immutable value object
from dataclasses import dataclass

@dataclass(frozen=True)
class Money:
    amount: int       # in cents
    currency: str

price = Money(amount=1000, currency="USD")
# price.amount = 2000  # raises FrozenInstanceError

# NamedTuple — when tuple unpacking is needed downstream
from typing import NamedTuple

class Coordinate(NamedTuple):
    lat: float
    lon: float

origin = Coordinate(lat=0.0, lon=0.0)
lat, lon = origin   # unpacks cleanly
```

## Error Handling

- Catch specific exception types — not bare `except:` or `except Exception:`.
- Use context managers for resource cleanup: `with open(...) as f`.
- Never silently swallow exceptions.
- Include enough context in error messages to debug without the full stack trace.
- Chain exceptions with `raise X from Y` to preserve the original cause.
- Define custom exception classes with structured context fields.

```python
# BAD — swallows everything, loses original error
try:
    result = call_api(endpoint)
except:
    return None

# GOOD — specific, chained, informative
class APIError(Exception):
    def __init__(self, endpoint: str, status: int) -> None:
        self.endpoint = endpoint
        self.status = status
        super().__init__(f"API call to {endpoint!r} failed with status {status}")

def call_api(endpoint: str) -> dict:
    try:
        response = requests.get(endpoint, timeout=10)
        response.raise_for_status()
        return response.json()
    except requests.HTTPError as exc:
        raise APIError(endpoint=endpoint, status=exc.response.status_code) from exc

# Context manager for resource cleanup
class ManagedConnection:
    def __enter__(self) -> "ManagedConnection":
        self._connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> bool:
        self._disconnect()
        return False  # do not suppress exceptions

with ManagedConnection() as conn:
    conn.query("SELECT 1")
```

## Code Organization

- One class or closely related group of functions per module.
- Modules over 300 lines should be reviewed for decomposition.
- Functions over 20 lines are candidates for extraction.
- Use `__all__` to define the public API of a module — controls `from module import *` and documents intent.

```python
# BAD — no __all__, everything leaks
import re
_PATTERN = re.compile(r"\d+")

def parse_id(text: str) -> int | None: ...
def _normalize(text: str) -> str: ...   # internal, but still importable

# GOOD — explicit public surface
__all__ = ["parse_id", "ParseError"]

class ParseError(ValueError):
    """Raised when input cannot be parsed."""

def parse_id(text: str) -> int | None:
    """Return the first integer found in text, or None."""
    match = _PATTERN.search(_normalize(text))
    return int(match.group()) if match else None

def _normalize(text: str) -> str:
    return text.strip().lower()

# Recommended module layout
# mypackage/
#   __init__.py       — re-exports from __all__ only
#   models.py         — data classes / Pydantic models
#   services.py       — business logic
#   repositories.py   — data access
#   exceptions.py     — custom exception hierarchy
#   utils.py          — stateless helpers
```

## Imports

- Standard library first, then third-party, then local — separated by blank lines.
- Use absolute imports; avoid relative imports in large codebases.
- No wildcard imports (`from module import *`).
- Enforce order with `isort` — configure once, automate always.

```python
# BAD — mixed groups, wildcard, relative
from .utils import *
import os, requests
from myapp.models import User

# GOOD — three groups, sorted within each group
import os
import sys
from pathlib import Path

import requests
from pydantic import BaseModel

from myapp.models import User
from myapp.services import UserService

# isort commands
# isort src/                          — fix all files under src/
# isort --check --diff src/           — CI dry-run, exit 1 if unsorted
# isort --profile black src/          — align with black's import style
```

## Logging

- Use `logging` module — no `print()` in production code.
- Log at the appropriate level: DEBUG for diagnostic detail, INFO for normal flow, WARNING for unexpected but handled, ERROR for failures.
- Always use `%s`-style lazy formatting or `logger.debug("msg %s", val)` — never f-strings in log calls (wastes CPU when level is disabled).

```python
# BAD
print(f"Processing order {order_id}")

# GOOD
import logging
logger = logging.getLogger(__name__)

logger.debug("processing order %s", order_id)
logger.info("order %s created successfully", order_id)
logger.warning("order %s missing optional field 'notes'", order_id)
logger.error("order %s failed: %s", order_id, exc, exc_info=True)
```

## Style

- Follow PEP 8.
- Use `black` for formatting and `ruff` for linting.
- Maximum line length: 88 (black default) or 100.
- Use f-strings for string formatting (Python 3.6+).

## Tooling Commands

```bash
# Type checking
mypy --strict src/
pyright src/

# Formatting
black src/
black --check src/          # CI: exit 1 if not formatted

# Linting
ruff check src/
ruff check --fix src/       # auto-fix safe violations

# Import sorting
isort src/
isort --check --diff src/   # CI check

# All-in-one pre-commit (recommended)
pre-commit run --all-files
```

Recommended `pyproject.toml` snippet:

```toml
[tool.mypy]
strict = true
python_version = "3.11"

[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "UP", "ANN"]

[tool.black]
line-length = 88
target-version = ["py311"]

[tool.isort]
profile = "black"
```

## Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| `except Exception: pass` | Swallows all errors silently, hides bugs | Catch specific type, log or re-raise |
| `def f(items=[])` | Mutable default shared across calls | Use `items: list \| None = None`, init inside |
| `from module import *` | Pollutes namespace, breaks static analysis | Explicit imports; define `__all__` |
| `# type: ignore` without comment | Hides real type errors from reviewers | Fix the type issue; if unavoidable, add explanation |
| `Optional[T]` with `typing` import | Verbose; `T \| None` is available since 3.10 | Use union syntax `T \| None` |
| Plain `dict` for structured data | No type safety, no IDE autocompletion | Use `@dataclass` or `Pydantic` model |
| `print()` in production code | Unstructured, unsuppressable, unleveled | Use `logging.getLogger(__name__)` |
| Bare `raise` inside `except` without chaining | Loses original traceback context | Use `raise NewError(...) from original_exc` |
| Relative imports across packages | Breaks refactors, confuses tooling | Use absolute imports everywhere |
| God module > 500 lines | Hard to navigate, review, and test | Split into domain-focused sub-modules |
