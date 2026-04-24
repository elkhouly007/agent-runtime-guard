---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Testing

Universal testing principles. Tests are not a chore — they are the specification of how the system should behave, and the mechanism that makes change safe.

## What to Test

- Test behaviors, not implementations. "Given input X, expect output Y" — not "expect function A to call function B."
- Test at the level where the behavior is defined: unit tests for algorithms, integration tests for component interactions, end-to-end tests for user journeys.
- Test the unhappy paths as thoroughly as the happy path. Production failures live in error conditions, edge cases, and boundary values.
- Every bug fix must include a regression test that would have caught the bug. This prevents reintroduction.

## Test Structure

- One test, one assertion of interest. Tests with multiple unrelated assertions are hard to diagnose when they fail.
- Name tests as specifications: `when_token_is_expired_returns_401`, not `test_auth`.
- Arrange-Act-Assert (AAA) structure: set up state, perform the action, verify the result. One clear section per phase.
- Tests should be hermetic: they set up their own state and clean up after themselves. Tests that depend on run order are fragile.

## Test Quality

- Tests that always pass regardless of the implementation are not tests — they are noise. Verify each test can fail by breaking the behavior it tests.
- Mutation testing is the gold standard: if you can change a line of implementation without failing any test, the test coverage is incomplete.
- Flaky tests must be fixed or removed immediately. A test suite with flaky tests teaches everyone to ignore test failures.
- Test data should be minimal and meaningful. Large, realistic-looking test data masks what the test is actually testing.

## Coverage

- Coverage metrics measure how much code is executed by tests, not how well the behavior is specified. 100% coverage with bad tests means nothing.
- Focus coverage efforts on: critical paths, security-sensitive code, complex algorithms, and code that has had bugs before.
- Untested code is a maintenance liability. Changes to untested code cannot be verified without manual testing.

## Test Performance

- Fast tests run frequently; slow tests are skipped. Keep unit tests under 100ms each.
- Separate slow tests (integration, end-to-end) from fast tests. Run fast tests on every save; slow tests on every commit.
- Parallelize tests where possible. Sequential test execution is a velocity tax.
- Mock external dependencies at the integration boundary. Do not mock internal components — that tests the mock, not the system.
