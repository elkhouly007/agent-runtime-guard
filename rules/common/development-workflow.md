---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Development Workflow — Common Rules

## Branch Strategy

| Branch type | Pattern                   | Base     | Merges into  |
|-------------|---------------------------|----------|--------------|
| Main        | `main`                    | —        | —            |
| Feature     | `feat/<ticket>-short-desc`| `main`   | `main` via PR|
| Bug fix     | `fix/<ticket>-short-desc` | `main`   | `main` via PR|
| Hotfix      | `hotfix/<ticket>-desc`    | `main`   | `main` + tag |
| Release     | `release/v1.2.0`          | `main`   | `main` + tag |

```bash
# Start a feature
git checkout main && git pull
git checkout -b feat/ECC-42-add-rate-limiting

# Keep branch current
git fetch origin && git rebase origin/main
```

---

## Before Starting Work

- Understand the requirements before writing code.
- Identify affected components and dependencies.
- For complex changes, write a brief plan before coding; use `TodoWrite` to track steps.
- Check for existing utilities or patterns before writing new ones:
  ```bash
  grep -r "rate.limit" src/     # find existing patterns
  ```

### TodoWrite Usage Guidelines

Use `TodoWrite` to track multi-step work so nothing is forgotten:

- Create a todo list at the start of any task with 3+ steps.
- Mark items `in_progress` when actively working on them — only one at a time.
- Mark `completed` immediately after finishing each step.
- Do not leave todo lists with stale `in_progress` items after the task ends.

---

## Pre-Commit Checklist

Run these before every commit:

```bash
# 1. Lint
npm run lint           # Node
flake8 src/ && black --check src/   # Python
golangci-lint run ./...             # Go

# 2. Type check (if applicable)
npm run type-check     # TypeScript
mypy src/              # Python

# 3. Tests
npm test               # Node
pytest -q              # Python
go test ./...          # Go

# 4. No secrets committed
git diff --staged | grep -iE "(password|secret|token|api_key)\s*=" && echo "STOP: secret detected"

# 5. No debug code
git diff --staged | grep -iE "(console\.log|pdb\.set_trace|debugger)" && echo "WARN: debug code"
```

---

## During Development

- Make small, incremental commits — each commit should leave the codebase in a working state.
- Run tests frequently; do not accumulate failures.
- Keep the branch up to date with main via rebase (not merge for feature branches).
- If scope grows significantly, split the work into separate PRs.

```bash
# Good commit message format
git commit -m "feat(auth): add rate limiting to login endpoint

Limits to 5 attempts per minute per IP.
Refs ECC-42."
```

---

## PR Checklist

**As Author — before opening PR:**
- [ ] Branch is rebased on latest `main`.
- [ ] All CI checks pass locally.
- [ ] PR description explains what changed and why (not just what).
- [ ] No secrets, debug code, or commented-out blocks.
- [ ] Coverage is at or above the project target.
- [ ] Public API docs updated if interface changed.
- [ ] PR is small and focused — one logical change per PR.

**As Reviewer:**
- [ ] Review within one business day.
- [ ] Ask clarifying questions before blocking.
- [ ] Distinguish `[blocking]` from `[suggestion]` in comments.
- [ ] Approve only when confident the change is correct and safe.

---

## CI Pipeline Stages

```
1. lint          → fail fast on style / type errors
2. unit-tests    → fast feedback, no external deps
3. security-scan → npm audit / pip-audit / trivy
4. integration   → DB + API contract tests
5. build         → produce artifact
6. e2e           → smoke test on staging (post-merge only)
```

Every merge to `main` must pass stages 1–5. Stage 6 runs after merge.

---

## Hook Integration (Claude Code Agents)

| Hook           | When to Use                                              | Example Trigger                          |
|----------------|----------------------------------------------------------|------------------------------------------|
| `PreToolUse`   | Validate or block a tool call before it executes         | Block `Bash` with `rm -rf` patterns      |
| `PostToolUse`  | React to tool output after execution                     | Log file writes; re-run linter after Edit|
| `Stop`         | Validate final state before agent turn ends              | Ensure no secrets in staged files        |

```jsonc
// settings.json hook example — block dangerous rm
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{ "type": "command", "command": "scripts/check-safe-bash.sh" }]
    }]
  }
}
```

---

## Definition of Done

A change is done when:
- [ ] Functionality works as specified.
- [ ] Tests are written and passing.
- [ ] Coverage is at or above the project target.
- [ ] Linter passes with no new warnings.
- [ ] Documentation updated if public APIs changed.
- [ ] PR reviewed and approved.
- [ ] No secrets or debug code left in.
- [ ] Merged to `main` and CI is green.

---

## Deployment and Incidents

- Every merge to `main` must be deployable.
- Database migrations are tested in staging before production.
- Rollback procedure is documented before every deploy.
- High-severity bugs get a fix before new features.
- Post-mortems for significant incidents: what happened, why, what prevents recurrence. Action items are tracked.
