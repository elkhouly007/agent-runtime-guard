# Skill: Python Patterns

## Trigger

Use when:
- Writing new Python modules or classes
- Reviewing Python code for idiomatic style
- Choosing between data container types (dataclass, NamedTuple, TypedDict)
- Designing resource management, generators, or functional pipelines
- Spotting anti-patterns before code review

## Process

### 1. Choose the right data container

| Type | Use when |
|------|----------|
| `dataclass` | Mutable state, methods needed, default factories, `__post_init__` validation |
| `NamedTuple` | Immutable, hashable, unpack-friendly, small record |
| `TypedDict` | Dict that must stay a dict (JSON, kwargs forwarding, partial updates) |

```python
from dataclasses import dataclass, field
from typing import NamedTuple, TypedDict

# dataclass — mutable, with post-init validation
@dataclass
class Order:
    id: str
    items: list[str] = field(default_factory=list)
    discount: float = 0.0

    def __post_init__(self) -> None:
        if not 0.0 <= self.discount <= 1.0:
            raise ValueError(f"discount must be in [0, 1], got {self.discount}")

    @property
    def item_count(self) -> int:
        return len(self.items)


# NamedTuple — immutable, hashable, unpackable
class Point(NamedTuple):
    x: float
    y: float

p = Point(1.0, 2.0)
x, y = p  # unpacking works


# TypedDict — typed dict, stays a plain dict
class Config(TypedDict, total=False):
    host: str
    port: int
    debug: bool

cfg: Config = {"host": "localhost", "port": 8080}
```

### 2. Context managers

Always implement `__enter__`/`__exit__` or use `contextlib.contextmanager` for resource management.

```python
from contextlib import contextmanager
import sqlite3

# Class-based: full control over cleanup
class ManagedConnection:
    def __init__(self, dsn: str) -> None:
        self._dsn = dsn
        self._conn: sqlite3.Connection | None = None

    def __enter__(self) -> sqlite3.Connection:
        self._conn = sqlite3.connect(self._dsn)
        return self._conn

    def __exit__(self, exc_type, exc_val, exc_tb) -> bool:
        if self._conn:
            if exc_type is None:
                self._conn.commit()
            else:
                self._conn.rollback()
            self._conn.close()
        return False  # do not suppress exceptions


# Generator-based: simpler for linear setup/teardown
@contextmanager
def temp_directory():
    import tempfile, shutil
    path = tempfile.mkdtemp()
    try:
        yield path
    finally:
        shutil.rmtree(path, ignore_errors=True)


with temp_directory() as tmp:
    print(tmp)  # guaranteed cleanup
```

### 3. Generators and itertools

Prefer lazy generators for large sequences. Never materialize a list when you only need iteration.

```python
import itertools
from collections.abc import Generator, Iterator

# Generator function — lazy, memory-efficient
def chunked(seq: list, size: int) -> Generator[list, None, None]:
    for i in range(0, len(seq), size):
        yield seq[i : i + size]


# itertools recipes
data = [1, 2, 3, 4, 5, 6]

pairs = list(itertools.pairwise(data))          # [(1,2),(2,3),...]  Python 3.10+
batches = list(itertools.batched(data, 2))      # [(1,2),(3,4),(5,6)] Python 3.12+
grouped = itertools.groupby(data, key=lambda x: x % 2)

# chain instead of nested loops
from itertools import chain
flat = list(chain.from_iterable([[1, 2], [3, 4]]))  # [1, 2, 3, 4]

# islice for lazy truncation
first_five: Iterator[int] = itertools.islice(iter(range(10**9)), 5)
```

### 4. functools

```python
import functools
from typing import Callable

# lru_cache — memoize pure functions (use maxsize=None for unlimited)
@functools.lru_cache(maxsize=256)
def fibonacci(n: int) -> int:
    if n < 2:
        return n
    return fibonacci(n - 1) + fibonacci(n - 2)


# cache — Python 3.9+ alias for lru_cache(maxsize=None)
@functools.cache
def factorial(n: int) -> int:
    return 1 if n == 0 else n * factorial(n - 1)


# partial — fix arguments for callbacks and higher-order functions
def power(base: float, exp: float) -> float:
    return base ** exp

square = functools.partial(power, exp=2)
cube   = functools.partial(power, exp=3)


# reduce — fold a sequence (prefer sum/max/min builtins when possible)
product = functools.reduce(lambda a, b: a * b, [1, 2, 3, 4])  # 24


# total_ordering — implement __eq__ + one comparison, get the rest free
@functools.total_ordering
class Version:
    def __init__(self, major: int, minor: int) -> None:
        self.major, self.minor = major, minor

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Version):
            return NotImplemented
        return (self.major, self.minor) == (other.major, other.minor)

    def __lt__(self, other: "Version") -> bool:
        return (self.major, self.minor) < (other.major, other.minor)
```

### 5. pathlib over os.path

```python
from pathlib import Path

root = Path("/var/data")

# Construction
config_file = root / "config" / "app.toml"

# Read / write
text = config_file.read_text(encoding="utf-8")
config_file.write_text("key = value\n", encoding="utf-8")

# Metadata
if config_file.exists() and config_file.is_file():
    size = config_file.stat().st_size

# Glob
py_files = list(root.rglob("*.py"))

# Stem / suffix
stem   = config_file.stem    # "app"
suffix = config_file.suffix  # ".toml"
parent = config_file.parent  # Path("/var/data/config")

# Resolve symlinks
absolute = config_file.resolve()
```

### 6. ABC for nominal interfaces, Protocol for structural typing

```python
from abc import ABC, abstractmethod
from typing import Protocol, runtime_checkable

# ABC — enforce implementation via inheritance
class Repository(ABC):
    @abstractmethod
    def get(self, entity_id: str) -> dict: ...

    @abstractmethod
    def save(self, entity: dict) -> None: ...


class InMemoryRepository(Repository):
    def __init__(self) -> None:
        self._store: dict[str, dict] = {}

    def get(self, entity_id: str) -> dict:
        return self._store[entity_id]

    def save(self, entity: dict) -> None:
        self._store[entity["id"]] = entity


# Protocol — structural (duck) typing, no inheritance required
@runtime_checkable
class Closeable(Protocol):
    def close(self) -> None: ...

def cleanup(resource: Closeable) -> None:
    resource.close()

# Any object with .close() satisfies Closeable — no subclassing needed
```

### 7. Comprehensions, enumerate, and zip

```python
# List comprehension — filter + transform in one pass
squares = [x * x for x in range(10) if x % 2 == 0]

# Dict comprehension
word_lengths = {word: len(word) for word in ["hello", "world"]}

# Set comprehension
unique_lengths = {len(w) for w in ["a", "bb", "bb", "ccc"]}

# Generator expression (lazy — no list created)
total = sum(x * x for x in range(10**6))

# enumerate — always use instead of manual index
for idx, item in enumerate(["a", "b", "c"], start=1):
    print(f"{idx}: {item}")

# zip — pair iterables; use strict=True (Python 3.10+) to catch length mismatch
keys = ["a", "b", "c"]
vals = [1, 2, 3]
mapping = dict(zip(keys, vals, strict=True))

# zip_longest from itertools when lengths differ intentionally
from itertools import zip_longest
padded = list(zip_longest([1, 2], [10, 20, 30], fillvalue=0))
```

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `def f(items=[])` mutable default | Shared across all calls; mutates silently | `def f(items=None): items = items or []` |
| `except:` bare except | Catches `SystemExit`, `KeyboardInterrupt` | `except Exception:` at minimum; be specific |
| `from module import *` | Pollutes namespace, hides origin | Explicit imports only |
| `type(x) == int` | Misses subclasses | `isinstance(x, int)` |
| Nested list comprehensions > 2 levels | Unreadable | Extract to named loop or function |
| `open(path)` without encoding | Platform-dependent behavior | Always pass `encoding="utf-8"` |
| `os.path.join(a, b)` | Verbose, error-prone | `Path(a) / b` |
| `assert` for validation | Stripped with `-O` flag | Raise `ValueError`/`TypeError` explicitly |
| Using `__dunder__` methods directly | Bypasses descriptor protocol | Use `len(x)`, `str(x)`, etc. |

## Safe Behavior

- Every new module uses `from __future__ import annotations` if Python < 3.12.
- No mutable default arguments, ever.
- All file opens specify `encoding=`.
- Bare `except:` is blocked — delegate to `code-review` agent to flag it.
- `pathlib.Path` is the only accepted path manipulation API.
- `Protocol` is preferred over `ABC` when the caller controls neither hierarchy.
