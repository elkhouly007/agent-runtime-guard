# Skill: Python Testing (pytest)

## Trigger

Use when:
- Writing or reviewing Python tests
- Choosing fixture scope or sharing test infrastructure
- Setting up property-based testing with Hypothesis
- Mocking external dependencies or patching modules
- Configuring coverage and CI test commands

## Process

### 1. Fixture scopes

Fixtures are the core of pytest's setup/teardown. Choose scope deliberately.

| Scope | Created | Destroyed | Use for |
|-------|---------|-----------|---------|
| `function` (default) | Each test | After each test | Anything with mutable state |
| `class` | Once per class | After last test in class | Shared class-level setup |
| `module` | Once per file | After last test in file | Expensive one-time setup per file |
| `session` | Once per run | After entire suite | DB connections, Docker containers |

```python
# conftest.py — fixtures here are available to all tests in the directory tree

import pytest
import httpx

@pytest.fixture(scope="session")
def http_client():
    """One client for the whole session — no reconnect overhead."""
    with httpx.Client(base_url="http://localhost:8000") as client:
        yield client


@pytest.fixture(scope="module")
def db_schema(tmp_path_factory):
    """Create schema once per module."""
    db_path = tmp_path_factory.mktemp("db") / "test.db"
    # run migrations...
    yield db_path


@pytest.fixture()  # function scope (default)
def clean_db(db_schema):
    """Wipe tables before each test — ensures isolation."""
    # truncate tables...
    yield
    # teardown if needed
```

### 2. parametrize

```python
import pytest

@pytest.mark.parametrize("value,expected", [
    (0,   True),
    (1,   False),
    (-1,  False),
    (100, False),
], ids=["zero", "positive", "negative", "large"])
def test_is_zero(value: int, expected: bool) -> None:
    assert (value == 0) == expected


# Combine multiple parametrize decorators (cartesian product)
@pytest.mark.parametrize("base", [2, 10])
@pytest.mark.parametrize("exp", [0, 1, 2])
def test_power(base: int, exp: int) -> None:
    assert base ** exp >= 1
```

### 3. conftest.py structure

```
tests/
├── conftest.py           # session/module fixtures, shared plugins
├── unit/
│   ├── conftest.py       # unit-test-only fixtures
│   └── test_orders.py
└── integration/
    ├── conftest.py       # DB, network fixtures
    └── test_api.py
```

Rules:
- Never import from one test file into another — use `conftest.py`.
- `conftest.py` is auto-discovered; no import needed.
- Keep session fixtures in the root `conftest.py`.

### 4. tmp_path and monkeypatch

```python
from pathlib import Path

def test_writes_output_file(tmp_path: Path) -> None:
    """tmp_path is a unique directory per test, auto-cleaned."""
    output = tmp_path / "result.txt"
    write_results(output)
    assert output.read_text() == "done\n"


def test_reads_env_var(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_ENV", "test")
    assert get_environment() == "test"


def test_patches_open(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    fake_config = tmp_path / "config.toml"
    fake_config.write_text('[app]\nport = 9999\n')
    monkeypatch.setattr("myapp.config.CONFIG_PATH", fake_config)
    cfg = load_config()
    assert cfg["app"]["port"] == 9999


def test_replaces_function(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("myapp.utils.time.time", lambda: 1_700_000_000.0)
    assert current_timestamp() == 1_700_000_000.0
```

### 5. Hypothesis for property-based testing

```python
from hypothesis import given, settings, assume
from hypothesis import strategies as st

@given(st.lists(st.integers()))
def test_sort_is_idempotent(xs: list[int]) -> None:
    assert sorted(sorted(xs)) == sorted(xs)


@given(st.text(min_size=1))
def test_reverse_roundtrip(s: str) -> None:
    assert s[::-1][::-1] == s


@given(st.integers(min_value=1), st.integers(min_value=1))
def test_gcd_divides_both(a: int, b: int) -> None:
    import math
    g = math.gcd(a, b)
    assert a % g == 0
    assert b % g == 0


# assume() discards examples that don't satisfy preconditions
@given(st.integers(), st.integers())
def test_division(a: int, b: int) -> None:
    assume(b != 0)
    assert (a // b) * b + (a % b) == a


# Control shrinking and example count
@settings(max_examples=500, deriving=False)
@given(st.binary())
def test_encode_decode(data: bytes) -> None:
    import base64
    assert base64.b64decode(base64.b64encode(data)) == data
```

### 6. mock.patch and MagicMock

```python
from unittest.mock import MagicMock, patch, call

# Patch as decorator — auto-restored after test
@patch("myapp.email.send_smtp")
def test_sends_welcome_email(mock_send: MagicMock) -> None:
    register_user("alice@example.com")
    mock_send.assert_called_once_with(
        to="alice@example.com",
        subject="Welcome!",
    )


# Patch as context manager — good for conditional patching
def test_retries_on_failure() -> None:
    with patch("myapp.http.requests.get") as mock_get:
        mock_get.side_effect = [ConnectionError(), MagicMock(status_code=200)]
        result = fetch_with_retry("https://example.com")
        assert result.status_code == 200
        assert mock_get.call_count == 2


# Mock return values and attributes
def test_payment_gateway() -> None:
    gateway = MagicMock()
    gateway.charge.return_value = {"status": "ok", "txn_id": "abc123"}
    gateway.charge.side_effect = None  # clear any side_effect

    result = process_payment(gateway, amount=100)
    assert result["txn_id"] == "abc123"
    gateway.charge.assert_called_once_with(100)


# Spy on real objects — wrap without replacing
from unittest.mock import create_autospec
import myapp.utils

def test_calls_util() -> None:
    spy = create_autospec(myapp.utils.format_name, wraps=myapp.utils.format_name)
    with patch("myapp.service.format_name", spy):
        greet("alice")
    spy.assert_called_once_with("alice")
```

### 7. pytest-asyncio for async tests

```python
import pytest
import pytest_asyncio
import asyncio

# pyproject.toml:
# [tool.pytest.ini_options]
# asyncio_mode = "auto"

@pytest.mark.asyncio
async def test_async_fetch() -> None:
    result = await fetch_data("https://example.com")
    assert result is not None


# Async fixtures
@pytest_asyncio.fixture
async def async_client():
    import httpx
    async with httpx.AsyncClient(base_url="http://testserver") as client:
        yield client


@pytest.mark.asyncio
async def test_endpoint(async_client: httpx.AsyncClient) -> None:
    resp = await async_client.get("/health")
    assert resp.status_code == 200


# Test concurrent behavior
@pytest.mark.asyncio
async def test_concurrent_tasks() -> None:
    results = await asyncio.gather(task_a(), task_b(), task_c())
    assert all(r is not None for r in results)
```

### 8. Coverage with pytest-cov

```bash
# Run tests with coverage
pytest --cov=src --cov-report=term-missing --cov-report=html --cov-fail-under=90

# Branch coverage (catches missing else paths)
pytest --cov=src --cov-branch --cov-report=term-missing

# Exclude files from coverage
# pyproject.toml:
# [tool.coverage.run]
# omit = ["src/migrations/*", "src/*/admin.py"]
# branch = true
#
# [tool.coverage.report]
# fail_under = 90
# show_missing = true
```

```python
# Mark blocks that cannot be tested (use sparingly)
def debug_dump() -> None:  # pragma: no cover
    import pprint
    pprint.pprint(globals())
```

## Test Naming Convention

| Bad | Good |
|-----|------|
| `test_order()` | `test_order_total_is_zero_for_empty_cart()` |
| `test_validate()` | `test_validate_raises_value_error_for_negative_amount()` |
| `test_api()` | `test_post_order_returns_201_with_location_header()` |

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| `scope="session"` for mutable state | Tests bleed into each other | Use `function` scope or reset in fixture |
| Patching at the wrong path | Mock not applied | Patch where the name is *used*, not defined |
| `assert mock.called` | Too weak | `assert_called_once_with(...)` |
| Catching all exceptions in tests | Hides real errors | Let exceptions propagate; use `pytest.raises` |
| Test file imports another test file | Tight coupling | Move shared code to `conftest.py` or `helpers/` |
| `time.sleep` in tests | Flaky, slow | Patch time or use event-driven async patterns |

## Safe Behavior

- Every test file lives under `tests/` and is never imported by production code.
- No test modifies global state without monkeypatching and auto-restoration.
- Coverage gate enforced in CI — failures block merge.
- `pytest.raises(SpecificError)` always used over bare `try/except` in tests.
- Hypothesis `@given` tests are part of the standard suite, not optional.
