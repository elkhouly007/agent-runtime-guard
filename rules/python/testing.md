---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Python Testing Rules

## Framework

- Use `pytest` for all new code.
- `pytest-cov` for coverage reporting.
- `pytest-asyncio` for async tests.
- `pytest-mock` for ergonomic mocking via `mocker` fixture.
- `hypothesis` for property-based testing of edge cases.
- Run with `pytest --tb=short -q` for clean output.

## Test Structure

Name tests as `test_<unit>_<expected>_when_<condition>`. Test behavior, not implementation.

```python
# BAD — tests implementation detail, name says nothing about intent
def test_calculate():
    calc = Calculator()
    calc._run_internal()
    assert calc._result_cache == {1: 1}

# GOOD — tests observable behavior, name is self-documenting
def test_calculate_total_returns_zero_for_empty_cart():
    assert calculate_total([]) == 0

def test_calculate_total_applies_discount_when_threshold_exceeded():
    items = [Item(price=100), Item(price=50)]
    assert calculate_total(items, discount=0.1) == 135
```

## Fixtures

- Use `@pytest.fixture` for reusable setup.
- `scope="function"` (default) for test-isolated state.
- `scope="session"` for expensive shared resources (e.g., database connections).
- Always clean up with `yield` — teardown code runs even when the test fails.

```python
import pytest
from myapp.db import create_test_session, engine

# Function-scoped: each test gets a fresh, rolled-back session
@pytest.fixture
def db_session():
    session = create_test_session()
    yield session
    session.rollback()
    session.close()

# Session-scoped: schema created once for the whole test run
@pytest.fixture(scope="session")
def test_db():
    engine.create_all()
    yield engine
    engine.drop_all()

# Fixtures compose — db_session depends on test_db implicitly via SQLAlchemy
@pytest.fixture
def user_factory(db_session):
    created = []
    def _factory(name: str = "Alice"):
        user = User(name=name)
        db_session.add(user)
        db_session.flush()
        created.append(user)
        return user
    yield _factory
    # teardown: parent db_session fixture handles rollback
```

## Parametrize

Use `@pytest.mark.parametrize` with `ids` for readable test output — failure messages name the case, not just the index.

```python
# BAD — no ids, failure shows "test_validate_email[test0]"
@pytest.mark.parametrize("email,valid", [
    ("a@b.com", True),
    ("bad", False),
])
def test_validate_email(email, valid):
    assert validate_email(email) == valid

# GOOD — ids make failures self-explanatory
@pytest.mark.parametrize("email,valid", [
    ("user@example.com", True),
    ("missing_at_sign", False),
    ("@nodomain.com", False),
    ("trailing@dot.", False),
], ids=["valid", "no_at", "no_local", "trailing_dot"])
def test_validate_email(email: str, valid: bool) -> None:
    assert validate_email(email) == valid
```

## Mocking

- Mock at the boundary — where your code calls external systems.
- Do not mock what you own — mock what you do not (external APIs, time, filesystem).
- Prefer `pytest-mock`'s `mocker` fixture over manual `patch` setup/teardown.

```python
# BAD — mocks internal detail that could change with refactors
def test_user_service(mocker):
    mocker.patch("myapp.services.UserService._build_query")  # internal method

# GOOD — mock the I/O boundary, test the logic
from unittest.mock import patch, MagicMock

# Option A: decorator — cleaner for single-mock tests
@patch("myapp.email.SMTPClient.send")
def test_send_welcome_email_calls_smtp(mock_send):
    send_welcome_email("user@example.com")
    mock_send.assert_called_once_with(
        to="user@example.com", subject="Welcome!"
    )

# Option B: context manager — preferred when mock is conditional or scoped
def test_send_email_context_manager():
    with patch("myapp.email.SMTPClient.send") as mock_send:
        send_welcome_email("user@example.com")
        mock_send.assert_called_once()

# Option C: mocker fixture (pytest-mock) — no teardown needed
def test_send_email_mocker(mocker):
    mock_send = mocker.patch("myapp.email.SMTPClient.send")
    send_welcome_email("user@example.com")
    mock_send.assert_called_once()
```

## Hypothesis — Property-Based Testing

Use `hypothesis` to generate edge cases automatically — especially for parsers, serializers, and mathematical operations.

```python
from hypothesis import given, settings
from hypothesis import strategies as st

# BAD — hand-picked examples miss real edge cases
def test_roundtrip():
    assert decode(encode("hello")) == "hello"

# GOOD — hypothesis finds strings you'd never think to test
@given(st.text())
def test_encode_decode_roundtrip(value: str) -> None:
    """Encoding then decoding must always return the original value."""
    assert decode(encode(value)) == value

@given(st.lists(st.integers()))
def test_total_is_sum_of_parts(amounts: list[int]) -> None:
    assert calculate_total(amounts) == sum(amounts)

@settings(max_examples=500)    # increase for critical paths
@given(st.emails())
def test_validate_email_never_raises(email: str) -> None:
    """validate_email must return bool, never raise."""
    result = validate_email(email)
    assert isinstance(result, bool)
```

## Async Tests

```python
import pytest

@pytest.mark.asyncio
async def test_fetch_user_returns_correct_data(mocker) -> None:
    mocker.patch("myapp.http.get", return_value={"id": 1, "name": "Alice"})
    user = await fetch_user(user_id=1)
    assert user.id == 1
    assert user.name == "Alice"
```

## conftest.py Structure

Keep fixtures close to the tests that use them. Use layered `conftest.py` files — root for global fixtures, sub-package for local ones.

```
tests/
  conftest.py          ← session-scoped DB, shared HTTP client, global settings
  unit/
    conftest.py        ← lightweight fakes, in-memory repos
    test_services.py
  integration/
    conftest.py        ← real DB session, real Redis, test containers
    test_api.py
```

```python
# tests/conftest.py
import pytest
from myapp.config import Settings

@pytest.fixture(scope="session")
def settings() -> Settings:
    return Settings(env="test", db_url="sqlite:///:memory:")

# tests/unit/conftest.py
import pytest
from myapp.repositories import InMemoryUserRepo

@pytest.fixture
def user_repo() -> InMemoryUserRepo:
    return InMemoryUserRepo()
```

## Django Testing (when applicable)

- Use `pytest-django` and `@pytest.mark.django_db`.
- Use `client` fixture for API tests.
- Use `assertQuerySetEqual` for queryset assertions (Django 4.2+).
- Transactions roll back after each test automatically.

```python
@pytest.mark.django_db
def test_create_order_saves_to_db(client):
    response = client.post("/api/orders/", {"item": "widget", "qty": 2})
    assert response.status_code == 201
    assert Order.objects.filter(item="widget").exists()
```

## Coverage

```bash
# Standard coverage run — fail if below threshold
pytest --cov=myapp --cov-report=term-missing --cov-fail-under=80

# HTML report for local inspection
pytest --cov=myapp --cov-report=html

# Branch coverage (stricter — catches missing else paths)
pytest --cov=myapp --cov-branch --cov-fail-under=80

# Exclude test files and migrations from coverage count
# In pyproject.toml:
# [tool.coverage.run]
# omit = ["tests/*", "*/migrations/*"]
```

## Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| Testing implementation, not behavior | Tests break on refactors that don't change behavior | Assert on return values and side effects, not internal state |
| Mocking what you own | Hides integration bugs between your own modules | Only mock external boundaries (HTTP, DB, time, filesystem) |
| No `ids` on `parametrize` | Failures show `test_fn[test0]` — impossible to diagnose quickly | Always pass `ids=` with descriptive strings |
| Shared mutable fixture state | Tests pass or fail based on order — flaky CI | Use `scope="function"` by default; isolate with `yield` teardown |
| `assert` on magic `True` | `assert obj` passes for any truthy value — hides bugs | `assert obj.field == expected_value` — be explicit |
| Skipping teardown (`yield`-less fixture) | Leaked connections, files, or data corrupt subsequent tests | Always `yield`; put cleanup after `yield` |
| Giant test functions | Hard to read, multiple failure reasons per run | One concept per test; extract helpers for repeated setup |
| 100% coverage as the only goal | Coverage misses wrong logic that executes but returns wrong values | Combine coverage with property-based tests and mutation testing |
| No hypothesis for parsing/encoding | Hand-picked examples miss real edge cases | Add `@given(st.text())` for any encode/decode or parser function |
