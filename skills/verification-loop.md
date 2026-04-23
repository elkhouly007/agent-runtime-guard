# Skill: Verification Loop

## Trigger

Use after making code changes to systematically verify correctness: run the full build, tests, linting, type checking, and security scan in sequence. Use as a pre-commit or pre-PR quality gate.

## Process

Run each step in order. Stop and fix before proceeding if any step fails.

### Step 1 — Build

```bash
# Detect and run the appropriate build command
npm run build        # Node.js / TypeScript / Next.js
cargo build          # Rust
go build ./...       # Go
mvn compile          # Java/Maven
./gradlew build      # Java/Kotlin/Gradle
```

**What to check:**
- Zero build errors.
- No unexpected warnings (treat warnings as errors in CI: `--strict`, `-Werror`).
- Build output is in the expected location.

### Step 2 — Type Check

```bash
npx tsc --noEmit                   # TypeScript
mypy src/                          # Python (if configured)
cargo check                        # Rust (faster than build for type-only)
```

**What to check:**
- Zero type errors.
- No `@ts-ignore` or `type: ignore` introduced without justification.

### Step 3 — Lint

```bash
npx eslint src/ --max-warnings 0   # TypeScript/JavaScript
ruff check .                       # Python
cargo clippy -- -D warnings        # Rust
golangci-lint run                  # Go
```

**What to check:**
- Zero lint errors.
- Zero new warnings (pass `--max-warnings 0` to enforce this).

### Step 4 — Tests

```bash
npm test                           # Jest / Vitest
pytest -x                          # Python (-x = stop on first failure)
cargo test                         # Rust
go test ./...                      # Go
mvn test                           # Java
```

**What to check:**
- 100% of existing tests pass — no regressions.
- New code is covered by tests (check coverage report if available).
- No skipped or `TODO` tests left in the changed code.

### Step 5 — Security Scan

```bash
npm audit --audit-level=high       # Node.js dependencies
pip-audit                          # Python dependencies
cargo audit                        # Rust dependencies
trivy fs .                         # Multi-language + Dockerfile
```

**What to check:**
- No new HIGH or CRITICAL vulnerabilities introduced.
- If new vulnerabilities exist, they are either: (a) false positives with justification, or (b) filed for immediate remediation.

### Step 6 — Integration Check (if applicable)

```bash
# Run smoke test against a local dev environment
npm run test:integration
# or
docker-compose up -d && npm run test:smoke
```

**What to check:**
- Key user flows work end-to-end.
- Database migrations (if any) apply cleanly.
- No broken environment configurations.

## Output Format

Report results as a checklist:

```
Verification Loop Results
─────────────────────────
✅ Build         — clean (0 errors, 0 warnings)
✅ Type check    — clean
✅ Lint          — clean (0 errors, 0 warnings)
✅ Tests         — 247/247 passed (coverage: 84%)
✅ Security      — no high/critical vulnerabilities
✅ Integration   — smoke tests passed

Status: READY TO COMMIT
```

Or with a failure:

```
❌ Tests         — 244/247 passed (3 failures)
   FAIL src/orders/OrderService.test.ts
   FAIL src/payments/refund.test.ts

Status: BLOCKED — fix failures before committing
```

## Shortcuts

For quick iteration during development, run only the relevant subset:
- Changed only TypeScript files: build + type check + lint + unit tests.
- Changed only tests: tests only.
- Changed dependencies: security scan + tests.
- Pre-commit: full loop.
- Pre-PR: full loop including integration.

## Constraints

- Never mark the loop as passed if any step reports errors.
- Never skip steps — especially security scan and type check.
- If a check is not set up for the project, note it explicitly and recommend setting it up rather than silently skipping it.
