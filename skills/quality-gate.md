# Skill: Quality Gate

## Trigger

Use as a pre-merge or pre-deploy gate: runs build, type check, lint, tests, and security scan as a single pass and produces a binary PASS/FAIL verdict. Use before opening a PR, merging to main, or deploying to production.

## What Makes This Different from verification-loop

`verification-loop` is a step-by-step process skill — it walks through each step and explains what to look for.

`quality-gate` is a decision-making gate — it runs everything, collects the results, and gives a PASS or FAIL verdict with a summary for reviewers. Use it when you need a single go/no-go decision.

## Process

### Step 1 — Detect Project Type

```bash
# Auto-detect and select the right commands
[ -f package.json ]     && PROJECT=node
[ -f Cargo.toml ]       && PROJECT=rust
[ -f go.mod ]           && PROJECT=go
[ -f pom.xml ]          && PROJECT=java_maven
[ -f build.gradle* ]    && PROJECT=java_gradle
[ -f pyproject.toml ] || [ -f setup.py ] && PROJECT=python
```

### Step 2 — Run All Checks

Run all checks, collect results — do NOT stop on first failure (collect all failures at once):

```bash
# Node.js / TypeScript gate
RESULTS=()

npm run build 2>&1 && RESULTS+=("✅ Build") || RESULTS+=("❌ Build FAILED")
npx tsc --noEmit 2>&1 && RESULTS+=("✅ Type check") || RESULTS+=("❌ Type check FAILED")
npx eslint src/ --max-warnings 0 2>&1 && RESULTS+=("✅ Lint") || RESULTS+=("❌ Lint FAILED")
npm test -- --passWithNoTests 2>&1 && RESULTS+=("✅ Tests") || RESULTS+=("❌ Tests FAILED")
npm audit --audit-level=high 2>&1 && RESULTS+=("✅ Security") || RESULTS+=("❌ Security: vulnerabilities found")
```

```bash
# Rust gate
cargo build 2>&1         && echo "✅ Build"      || echo "❌ Build FAILED"
cargo clippy -- -D warnings 2>&1 && echo "✅ Lint" || echo "❌ Lint FAILED"
cargo test 2>&1          && echo "✅ Tests"      || echo "❌ Tests FAILED"
cargo audit 2>&1         && echo "✅ Security"   || echo "❌ Security FAILED"
```

```bash
# Go gate
go build ./... 2>&1           && echo "✅ Build"   || echo "❌ Build FAILED"
golangci-lint run 2>&1        && echo "✅ Lint"    || echo "❌ Lint FAILED"
go test ./... -count=1 2>&1   && echo "✅ Tests"   || echo "❌ Tests FAILED"
govulncheck ./... 2>&1        && echo "✅ Security" || echo "❌ Security FAILED"
```

```bash
# Python gate
python -m py_compile src/**/*.py 2>&1 && echo "✅ Syntax"  || echo "❌ Syntax FAILED"
ruff check . 2>&1                      && echo "✅ Lint"    || echo "❌ Lint FAILED"
pytest --tb=short 2>&1                 && echo "✅ Tests"   || echo "❌ Tests FAILED"
pip-audit 2>&1                         && echo "✅ Security" || echo "❌ Security FAILED"
```

### Step 3 — Produce Verdict

```
Quality Gate Report
═══════════════════════════════
Project:   [name] ([type])
Branch:    [branch]
Timestamp: [ISO datetime]

Checks:
  ✅ Build         clean
  ✅ Type check    clean
  ❌ Lint          3 errors in src/auth/middleware.ts
  ✅ Tests         247/247 passed (coverage: 84%)
  ✅ Security      no high/critical vulnerabilities

───────────────────────────────
Verdict: ❌ FAIL

Blocking issues:
  1. Lint: 3 errors — fix before merge
     → src/auth/middleware.ts:45 — Unexpected any
     → src/auth/middleware.ts:67 — Missing return type

Next step: fix lint errors, then re-run /quality-gate
```

Or on all-pass:

```
Quality Gate Report
═══════════════════════════════
  ✅ Build         clean
  ✅ Type check    clean
  ✅ Lint          clean
  ✅ Tests         247/247 (84% coverage)
  ✅ Security      clean

───────────────────────────────
Verdict: ✅ PASS — ready to merge
```

## Gate Levels

Configure strictness based on context:

| Level | Used when | What it gates |
|---|---|---|
| `standard` | Pre-PR | Build + types + lint + tests |
| `strict` | Pre-merge to main | All of standard + security + coverage threshold |
| `production` | Pre-deploy | All of strict + integration tests + E2E smoke |

Invoke with level:
```
/quality-gate --level=strict
/quality-gate --level=production
```

## Constraints

- Never issue a PASS verdict if any check fails, regardless of how minor.
- Do not suppress or skip checks without explicit user override with justification.
- Coverage threshold for `strict` level: minimum 80% line coverage. If coverage tooling is not set up, note it as a gap rather than marking security as passed.
- A FAIL verdict is a service — it catches problems before they reach main or production.
