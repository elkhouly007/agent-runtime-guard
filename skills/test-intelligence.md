# Skill: test-intelligence

# Test Intelligence

Extract maximum signal from your test suite and focus testing effort where it matters most.

## When to Use

Use when you need to understand test quality and coverage — not just line coverage numbers, but whether the tests actually protect against regressions, and where the highest-value tests to add next are.

## Test Suite Audit

```bash
# Test count by type
echo "Unit tests:"
find . -name "*.test.ts" -o -name "*.spec.ts" | grep -v e2e | grep -v integration | wc -l

echo "Integration tests:"
find . -path "*/integration/*.test.*" -o -path "*/integration/*.spec.*" | wc -l

echo "E2E tests:"
find . -path "*/e2e/*.ts" -o -path "*cypress*" | grep -v node_modules | wc -l
```

## Coverage Gap Detection

```bash
# Files with no corresponding test
for f in $(find src -name "*.ts" ! -name "*.test.ts" ! -name "*.spec.ts"); do
  base=$(basename "$f" .ts)
  dir=$(dirname "$f")
  if ! find . -name "${base}.test.ts" -o -name "${base}.spec.ts" 2>/dev/null | grep -q .; then
    echo "No test: $f"
  fi
done
```

## Brittle Test Patterns

Look for tests that fail for the wrong reasons:

```bash
# Snapshot tests (often break on cosmetic changes)
grep -rn "toMatchSnapshot\|toMatchInlineSnapshot" --include="*.test.*" | wc -l

# Tests with hardcoded IDs or dates
grep -rn '"id": "1"\|"2024-\|new Date("' --include="*.test.*" | wc -l

# Tests coupled to implementation details
grep -rn "\.prototype\.\|_private\|__internals\|.mock.calls\[0\]\[0\]" --include="*.test.*" | wc -l
```

## High-Value Tests to Add

Priority order for new tests:
1. **Happy path is untested** — the most common flow with no test
2. **Error paths** — what happens when a dependency fails
3. **Boundary conditions** — empty arrays, zero, null, max values
4. **Security inputs** — SQL injection, XSS, oversized strings
5. **Concurrent access** — race conditions in async code

## Test Quality Score

For each test, ask:
- Does it test one thing? (If it needs an "and" to describe, split it)
- Does it fail for the right reason when behavior breaks?
- Does it pass without depending on test order?
- Is it fast enough to run on every save?
- Would a reader know what behavior it documents?

## Coverage Is a Lagging Indicator

100% line coverage with bad assertions provides false confidence. Prioritize:
- High-value assertions (the actual behavior matters)
- Mutation testing to verify assertions are meaningful
- Property-based testing for functions with complex input spaces
