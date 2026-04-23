# Skill: TDD Workflow Integration

## Trigger

Use when integrating TDD into the full development pipeline — not just writing tests, but wiring TDD into CI, coverage gates, PR reviews, and agent delegation.

For the core RED/GREEN/REFACTOR methodology, see `tdd.md`.
This skill covers: **how TDD connects to everything else**.

## Process

### 1. Project setup: configure the test runner

Pick one per project and commit the config:

```bash
# TypeScript / Node.js
npx vitest init               # vitest.config.ts
# or
npx jest --init               # jest.config.ts

# Python
pip install pytest pytest-cov
# pyproject.toml or pytest.ini

# Go
# built-in: go test ./...
# add: go install gotest.tools/gotestsum@latest

# Rust
# built-in: cargo test
```

### 2. Wire coverage gates

Coverage must be enforced in CI, not just measured locally.

**Vitest (vitest.config.ts):**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      thresholds: { lines: 80, functions: 80, branches: 70 },
      reporter: ['text', 'lcov'],
    },
  },
});
```

**pytest (pyproject.toml):**
```toml
[tool.pytest.ini_options]
addopts = "--cov=src --cov-fail-under=80"
```

**Go (Makefile):**
```makefile
test-coverage:
	go test ./... -coverprofile=coverage.out
	go tool cover -func=coverage.out | grep total | awk '{if ($$3+0 < 80) exit 1}'
```

**JaCoCo (pom.xml):**
```xml
<configuration>
  <rules>
    <rule><limits>
      <limit><counter>LINE</counter><minimum>0.80</minimum></limit>
    </limits></rule>
  </rules>
</configuration>
```

### 3. CI integration

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm test -- --coverage
      # Coverage gate is enforced inside the test command (step 2 above)
      # CI fails if threshold not met — no extra step needed
```

### 4. Agent delegation model

TDD workflows are delegated to specialist agents:

| Situation | Delegate to |
|-----------|-------------|
| Enforcing methodology (RED first) | `tdd-guide` |
| Writing test skeleton for a new feature | `tdd-guide` |
| Fixing a failing test after a refactor | `build-error-resolver` |
| Analyzing coverage gaps | `pr-test-analyzer` |
| Reviewing test quality in a PR | `code-reviewer` |
| E2E test generation | `e2e-runner` |

### 5. PR workflow with TDD

Before merging any PR:

```bash
# 1. Run tests locally
npm test

# 2. Check coverage delta (did this PR decrease coverage?)
npx jest --coverage --coverageReporters=json-summary
# compare coverage-summary.json to main branch baseline

# 3. Delegate PR test review
# → pr-test-analyzer agent: "Review test quality for PR #<n>"
```

Merge gates:
- All tests must pass (CI enforces)
- Coverage must not decrease (CI enforces if configured)
- New business logic must have tests (pr-test-analyzer flags if missing)

### 6. Continuous feedback loop

```
Write failing test  →  RED
    ↓
Implement minimum  →  GREEN
    ↓
Refactor           →  still GREEN
    ↓
Push to CI         →  tests + coverage gate
    ↓
PR review          →  pr-test-analyzer checks test quality
    ↓
Merge              →  coverage baseline updated
```

## Coverage Thresholds by Project Stage

| Stage | Lines | Branches | Notes |
|-------|-------|----------|-------|
| Greenfield (new project) | 90% | 80% | High bar from the start |
| Existing codebase | 80% | 70% | Don't let coverage drop on new code |
| Legacy code (tech debt) | 60% | 50% | Improve incrementally |
| Critical paths (auth, billing) | 100% | 95% | No exceptions |

## Anti-Patterns

| Anti-pattern | Problem |
|-------------|---------|
| Disabling coverage gate in CI | Removes the feedback loop |
| Writing tests only at the end | You are not doing TDD — you are writing confirmation tests |
| One test file per test session | Tests should live next to the code they test |
| Skipping tests with `.skip` in CI | Hidden debt accumulates silently |
| Coverage without assertions | 100% line coverage with no `expect()` calls = worthless |

## Safe Behavior

- Coverage gates fail the build — they do not block locally unless configured to do so.
- Never remove a test to make coverage thresholds pass.
- `--coverage --bail` is recommended for CI: fail fast on first test failure.
- Coverage reports are local artifacts — do not commit `coverage/` directories.
- If a test is genuinely not worth fixing, open a tracked issue before disabling it.
