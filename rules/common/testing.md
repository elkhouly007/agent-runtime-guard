---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Testing — Common Rules

## Test Pyramid

| Layer       | Scope                          | Speed    | Recommended Share |
|-------------|--------------------------------|----------|-------------------|
| Unit        | Single function / class        | < 1 s    | ~70%              |
| Integration | Component interactions, DB/API | 1–30 s   | ~20%              |
| E2E         | Full user journey through UI   | 30 s–min | ~10%              |

Keep the pyramid proportional. A project with more E2E than unit tests is inverted and will be slow and brittle.

---

## Coverage Targets

- 80%+ line coverage as a minimum for production code.
- 100% coverage for security-critical and payment-related paths.
- New features without tests are not complete.

**Coverage commands:**
```bash
# Node.js
npm test -- --coverage

# Python
pytest --cov=src --cov-report=term-missing --cov-fail-under=80

# Go
go test -cover ./...
go test -coverprofile=coverage.out ./... && go tool cover -html=coverage.out
```

---

## Test Types

### Unit Tests

- Test a single function or class in isolation.
- Mock all external dependencies (network, database, filesystem, time).
- Fast: the full unit suite must run in seconds.
- Name tests to describe behavior: `[unit] should [behavior] when [condition]`.

**BAD test name:**
```python
def test_user():  # tells you nothing about what is tested or expected
    ...
```

**GOOD test name:**
```python
def test_create_user_raises_validation_error_when_email_is_missing():
    ...
```

**GOOD fixture example (pytest):**
```python
@pytest.fixture
def valid_user_payload():
    return {"name": "Alice", "email": "alice@example.com", "role": "viewer"}

def test_create_user_succeeds_with_valid_payload(valid_user_payload):
    result = create_user(valid_user_payload)
    assert result.id is not None
```

### Integration Tests

- Test interactions between components: API + database, service + external API.
- Use a real database (test instance, Docker) rather than mocks where possible.
- Verify the contract between components, not implementation internals.

### End-to-End Tests

- Test complete user journeys through the UI or API.
- Cover the critical happy path and the most important failure paths.
- Keep E2E tests focused — they are slow and expensive.

---

## Test Quality

### Good Test Checklist

- Tests one behavior.
- Is independent — does not rely on execution order or shared mutable state.
- Is deterministic — same result every run.
- Has a clear assertion that explains what was expected.
- Fails when the behavior it tests breaks.

**GOOD assertion (explicit failure message):**
```js
expect(result.status).toBe(201);
expect(result.body.id).toBeDefined();
expect(result.body.email).toBe('alice@example.com');
```

**BAD assertion (hides failures):**
```js
expect(result).toBeTruthy();  // passes even if result is a wrong object
```

### Mocking Principles

- Mock at the boundary of the system under test (HTTP clients, DB adapters, clocks).
- Do not mock what you own — mock what you do not (external APIs, OS resources).
- Excessive mocking is a sign the code needs better separation of concerns.

**GOOD mock example (Jest):**
```js
jest.mock('../lib/emailClient', () => ({
  send: jest.fn().mockResolvedValue({ messageId: 'test-id' })
}));

test('registers user and sends welcome email', async () => {
  await registerUser({ email: 'alice@example.com' });
  expect(emailClient.send).toHaveBeenCalledWith(
    expect.objectContaining({ to: 'alice@example.com' })
  );
});
```

---

## Edge Cases to Always Test

- Null or empty inputs.
- Boundary values (0, -1, max integer, empty string, single character).
- Invalid types or malformed input.
- Error and rejection paths.
- Concurrent or repeated calls where applicable.

---

## Test Isolation

- Each test cleans up after itself or uses a fresh context.
- No shared mutable state between tests.
- Tests can run in any order and in parallel.

---

## Anti-Patterns

| Anti-Pattern                        | Problem                                        | Fix                                          |
|-------------------------------------|------------------------------------------------|----------------------------------------------|
| `test_1`, `test_a`, `test_stuff`    | Unintelligible failure messages                | Name: `should [behavior] when [condition]`   |
| `assert True` / `expect(x).toBe(x)` | Test always passes; behavior never verified    | Assert the actual expected value             |
| Sleep/delay in tests                | Flaky, environment-dependent timing            | Use mocked clocks or event-driven waits      |
| Tests that share DB rows            | Order-dependent failures                       | Truncate/seed fresh data per test            |
| Mocking internal implementation     | Breaks on refactoring, not on real bugs        | Mock at external boundaries only             |
| Hitting production services         | Slow, costly, non-deterministic                | Use test doubles or sandbox environments     |
| One giant test method               | Hard to diagnose failures; tests multiple things | Split into focused single-behavior tests   |
| No assertion, just no exception     | Passes when method silently fails              | Assert on return value or observable effect  |
