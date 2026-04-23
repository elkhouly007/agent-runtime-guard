# Skill: workflow-acceleration

# Workflow Acceleration

Find and fix the bottlenecks that waste developer time.

## When to Use

Use when CI is slow, local test runs take too long, onboarding new contributors is painful, or developers are context-switching because they have to wait on builds. Profile before optimizing.

## Step 1: Measure First

```bash
# Time the full test suite
time npm test

# Time individual test files to find slow tests
npx jest --verbose 2>&1 | grep "●" | sort -k2 -rn | head -20

# Time the build
time npm run build

# Time CI from push to green (check CI logs)
```

## Step 2: Local Setup Time

Identify friction for new contributors:
- How long does `git clone + npm install` take?
- Are there manual steps not in the README?
- Are there environment variable dependencies that aren't documented?

```bash
# Dependency install time
time npm ci

# Docker build time (if applicable)
time docker build .
```

## Step 3: Test Suite Optimization

Common test slowdowns:

```bash
# Find tests with unnecessary sleep/timeouts
grep -rn "setTimeout\|sleep\|delay\|waitFor.*\d{4,}" --include="*.test.*" | head -20

# Find tests hitting real network
grep -rn "http://\|https://" --include="*.test.*" | grep -v mock | grep -v fixture | head -20

# Find tests spawning processes
grep -rn "spawn\|exec\|fork\|child_process" --include="*.test.*" | head -20
```

## Step 4: Build Optimization

```bash
# Identify large bundles
npx vite-bundle-visualizer  # or webpack-bundle-analyzer

# Find circular dependencies
npx madge --circular src/ | head -20

# TypeScript compile time
tsc --diagnostics 2>&1 | grep "Total time"
```

## Step 5: CI Optimization

- Parallelize independent test suites across CI workers
- Cache node_modules / cargo / .gradle between runs
- Skip unchanged packages in monorepos (Turborepo, Nx, Bazel)
- Run fast linting before slow tests (fail fast)
- Use `--shard` for large Jest suites

## Quick Wins (Typical)

| Bottleneck | Fix | Time Saved |
|-----------|-----|-----------|
| Tests hit real database | Use in-memory / sqlite | 10x |
| No test parallelization | Add `--maxWorkers=auto` | 2–4x |
| No dependency caching in CI | Add cache step | 2–3 min |
| Full rebuild on every PR | Incremental build | 2–5x |
| All tests run serially | Jest `--runInBand` removed | 2–4x |
