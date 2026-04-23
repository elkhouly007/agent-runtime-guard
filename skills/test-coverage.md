# Skill: Test Coverage

## Trigger

Use when you want to measure test coverage, identify gaps before a PR, check if coverage meets a threshold, or decide which files need new tests most urgently.

## Coverage Commands by Language

| Language / Framework | Command |
|---------------------|---------|
| TypeScript / JS (Jest) | `npx jest --coverage --coverageReporters=text` |
| TypeScript / JS (Vitest) | `npx vitest run --coverage` |
| TypeScript / JS (c8) | `npx c8 --reporter=text npm test` |
| Python (pytest-cov) | `pytest --cov=src --cov-report=term-missing --cov-report=html` |
| Go | `go test ./... -coverprofile=coverage.out && go tool cover -func=coverage.out` |
| Rust | `cargo tarpaulin --out Stdout` |
| Java (Maven + JaCoCo) | `mvn test jacoco:report` |
| Java (Gradle + JaCoCo) | `./gradlew test jacocoTestReport` |
| Ruby (SimpleCov) | `bundle exec rspec --format progress` |
| PHP (PHPUnit) | `phpunit --coverage-text` |
| C / C++ (gcov/lcov) | `lcov --capture --directory . --output-file coverage.info && lcov --list coverage.info` |

## Process

### 1. Detect language and framework

```bash
# JS/TS detection
ls package.json jest.config.* vitest.config.* 2>/dev/null

# Python
ls pytest.ini setup.cfg pyproject.toml 2>/dev/null | xargs grep -l "pytest" 2>/dev/null

# Go
ls go.mod 2>/dev/null

# Rust
ls Cargo.toml 2>/dev/null

# Java
ls pom.xml build.gradle 2>/dev/null
```

### 2. Run coverage

Run the appropriate command from the table above. For JavaScript, prefer Vitest if a `vitest.config.*` file exists; otherwise use Jest.

To avoid re-running slow test suites, check for a cached coverage artifact first:

```bash
# Jest
ls coverage/lcov-report/index.html 2>/dev/null

# Python
ls htmlcov/index.html 2>/dev/null

# Go
ls coverage.out 2>/dev/null
```

If the cache is fresh (mtime < 5 minutes), parse the existing report instead of re-running.

### 3. Parse overall percentage

```bash
# Jest: extract summary line
grep -A4 "All files" coverage/lcov-report/index.html 2>/dev/null | grep -oP '\d+\.\d+(?=%)' | head -1

# Python: from terminal output
pytest --cov=src --cov-report=term-missing 2>&1 | grep TOTAL | awk '{print $NF}'

# Go
go tool cover -func=coverage.out | grep total | awk '{print $3}'

# Rust (tarpaulin)
cargo tarpaulin --out Stdout 2>&1 | grep "coverage"
```

### 4. Flag files below threshold

Default threshold: **80%**. Flag any file below this. Below 60% is critical.

```bash
# Jest: parse lcov.info for per-file coverage
python3 - <<'EOF'
import re, sys
threshold = 80
with open("coverage/lcov.info") as f:
    content = f.read()
blocks = content.split("end_of_record")
for block in blocks:
    sf = re.search(r"SF:(.+)", block)
    lh = re.search(r"LH:(\d+)", block)
    lf = re.search(r"LF:(\d+)", block)
    if sf and lh and lf:
        covered, total = int(lh.group(1)), int(lf.group(1))
        pct = (covered / total * 100) if total > 0 else 100
        if pct < threshold:
            print(f"{pct:5.1f}%  {sf.group(1)}")
EOF
```

```bash
# Python: parse missing lines from term-missing output
pytest --cov=src --cov-report=term-missing 2>&1 | awk '$4 < 80 && NR > 2 {print}'
```

```bash
# Go: per-file coverage
go tool cover -func=coverage.out | awk '{
  split($3, a, "%"); pct=a[1]+0
  if (pct < 80 && $1 != "total:") print pct"% "$1
}' | sort -n
```

### 5. Show top 5 least-covered files

Sort by coverage ascending and print the bottom 5 with uncovered line numbers:

```bash
# Jest — top 5 least covered
python3 - <<'EOF'
import re
with open("coverage/lcov.info") as f:
    content = f.read()
files = []
for block in content.split("end_of_record"):
    sf = re.search(r"SF:(.+)", block)
    lh = re.search(r"LH:(\d+)", block)
    lf = re.search(r"LF:(\d+)", block)
    da_miss = re.findall(r"DA:(\d+),0", block)
    if sf and lh and lf:
        covered, total = int(lh.group(1)), int(lf.group(1))
        pct = (covered / total * 100) if total > 0 else 100
        files.append((pct, sf.group(1), da_miss[:10]))
files.sort()
for pct, path, missing in files[:5]:
    lines = ", ".join(missing) if missing else "none"
    print(f"{pct:5.1f}%  {path}")
    print(f"        Uncovered lines: {lines}")
EOF
```

### 6. Delegate if coverage is critically low

If overall coverage < 60%, the project needs systematic TDD intervention, not just gap-filling. Delegate:

> Coverage is {X}% — below 60% critical threshold. Delegating to `tdd-guide` agent for TDD intervention plan.

Pass the list of uncovered files to `tdd-guide` as context.

## Example Output Format

```
## Coverage Report — 2026-04-19

Overall: 73.4%  [below 80% threshold]

### Files Below Threshold

| File | Coverage | Uncovered Lines |
|------|----------|-----------------|
| src/auth/token.ts | 41.2% | 45-67, 89, 102-115 |
| src/billing/invoice.ts | 52.0% | 23-45, 78-90 |
| src/jobs/scheduler.ts | 61.8% | 14-22, 55 |
| src/api/webhooks.ts | 67.3% | 88-102 |
| src/utils/retry.ts | 74.1% | 34-38 |

### Action
- CRITICAL: src/auth/token.ts at 41% — authentication code must reach 80%+
- HIGH: src/billing/invoice.ts at 52% — financial logic is under-tested
- Recommend: add tests for token refresh flow and invoice generation edge cases
```

## Minimum Thresholds in CI

### Jest (package.json)
```json
"jest": {
  "coverageThreshold": {
    "global": {
      "branches": 80,
      "functions": 80,
      "lines": 80,
      "statements": 80
    }
  }
}
```

### Vitest (vitest.config.ts)
```ts
coverage: {
  thresholds: { lines: 80, functions: 80, branches: 80, statements: 80 }
}
```

### pytest (pyproject.toml)
```toml
[tool.coverage.report]
fail_under = 80
```

### Go (Makefile)
```makefile
coverage-check:
    go test ./... -coverprofile=cov.out
    go tool cover -func=cov.out | awk '/^total/ { if ($3+0 < 80) { print "Coverage below 80%: "$3; exit 1 } }'
```

## Excluding Generated Files

```bash
# Jest — coveragePathIgnorePatterns in jest.config.js
coveragePathIgnorePatterns: [
  "/node_modules/",
  "\\.generated\\.ts$",
  "src/migrations/",
  "src/__generated__/"
]

# Python — .coveragerc
[report]
omit =
    src/migrations/*
    src/*_pb2.py
    src/generated/*

# Go — build tag in generated files
//go:build ignore

# Rust — tarpaulin.toml
[report]
exclude-files = ["src/generated/*", "src/proto/*"]
```

## Safe Behavior

- Runs tests and reads coverage output — no source files are modified.
- Does not push coverage results anywhere without explicit instruction.
- If running tests would trigger side effects (e.g., send emails, charge cards), read the test configuration first and flag this before running.
- Coverage below 60% surfaces a recommendation to delegate to `tdd-guide`; it does not auto-delegate without confirmation.
