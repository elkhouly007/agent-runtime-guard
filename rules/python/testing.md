# Python Testing

Python-specific testing standards.

## Framework

- Use pytest. Its fixtures, parameterization, and plugin ecosystem outclass unittest.
- pytest-cov for coverage. Aim for coverage on critical paths, not 100% coverage on everything.
- pytest-mock or unittest.mock for mocking. Prefer `mocker` fixture from pytest-mock.
- Hypothesis for property-based testing of algorithms and data transformations.

## Test Structure

- One test file per module. `tests/test_auth.py` for `src/auth.py`.
- Test names: `test_<behavior>_<condition>`. `test_login_fails_with_expired_token`, not `test_login_2`.
- Fixtures for shared setup. Use `conftest.py` for fixtures shared across multiple test files.
- Mark slow tests with `@pytest.mark.slow` and fast tests do not need marking.

## Mocking

- Mock at the boundary: external services, file system, databases, time.
- Do not mock internal functions. If you need to mock an internal function, the module needs to be split.
- `freezegun` for time-dependent tests. Never use `time.sleep()` in tests.
- Database tests: use a test database, not mocked database calls. Mocked database calls test the mock.

## Parametrize

- `@pytest.mark.parametrize` for testing multiple inputs against the same behavior.
- Each parameter set should have an `id` that describes the scenario: `pytest.param(input, expected, id="expired_token")`.
- Table-driven tests for algorithms with many input/output pairs.

## What Not to Mock

- Do not mock the code under test.
- Do not mock simple data structures.
- Do not mock framework behavior — test with the real framework.
- Do not mock to achieve coverage. Coverage of mocked paths is meaningless.
