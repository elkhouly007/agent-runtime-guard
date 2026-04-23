# Skill: Git Review

## Trigger

Use before committing, pushing, or opening a PR. Ensures the change is clean, safe, and well-described.

Also use when:
- Reviewing a branch before merge
- Diagnosing a broken git state
- Deciding between squash / rebase / merge strategies

## Pre-Commit Review

### 1. Review what you're about to commit
```bash
git status                         # what's staged, unstaged, untracked
git diff                           # unstaged changes
git diff --staged                  # staged changes (what will be committed)
git diff --stat HEAD               # summary of changed files
```

### 2. Check for what shouldn't be committed
```bash
# Secrets
grep -rn -e "password\s*=" -e "api_key\s*=" -e "secret\s*=" -e "token\s*=" \
  -e "BEGIN.*PRIVATE KEY" -e "AKIA[0-9A-Z]{16}" \
  $(git diff --staged --name-only)

# Debug artifacts
grep -rn "console\.log\|debugger\|pdb\.set_trace\|binding\.pry\|TODO.*REMOVE" \
  $(git diff --staged --name-only)

# Accidental files
git diff --staged --name-only | grep -E "\.(env|pem|p12|key|pfx)$"
```

### 3. Pre-commit checklist
- [ ] No secrets, credentials, or tokens in the diff.
- [ ] No `console.log` / `print` / `debugger` / `pdb` in production code.
- [ ] No commented-out code blocks.
- [ ] No `.env`, `.pem`, or credential files staged.
- [ ] Tests pass locally.
- [ ] Only intentional files are staged (no accidental `git add .`).
- [ ] Commit is a single logical change (not multiple unrelated edits).

## Commit Message Format

```
type(scope): short description (under 72 chars)

Optional body: explain WHY, not what the diff shows.
Reference: closes #123, fixes #456
```

**Types:** `feat` `fix` `refactor` `test` `docs` `chore` `perf` `security` `ci`

**Good examples:**
```
feat(auth): add refresh token rotation
fix(cart): prevent double-charge on network retry
security(deps): upgrade lodash to fix CVE-2021-23337
refactor(user): extract profile validation to separate module
```

**Bad examples:**
```
WIP
fix stuff
update code
various changes
```

## Pre-Push Review

```bash
git log --oneline origin/main..HEAD    # commits about to be pushed
git diff origin/main...HEAD --stat     # files changed vs main
```

Additional checklist:
- [ ] Commits are atomic and well-described.
- [ ] No merge commits from pulling (use rebase: `git pull --rebase`).
- [ ] Branch is up to date with main.
- [ ] CI passes (or will pass — no known failures).

## Branch Strategy

| Branch | Purpose | Merge into |
|--------|---------|------------|
| `main` / `master` | Production-ready only | — |
| `feature/<name>` | New functionality | `main` via PR |
| `fix/<name>` | Bug fix | `main` via PR |
| `hotfix/<name>` | Urgent production fix | `main` directly (then backport) |
| `chore/<name>` | Tooling, deps, config | `main` via PR |

Keep branches short-lived. A branch older than 2 weeks is a smell.

## Merge Strategy Guide

| Scenario | Strategy | Why |
|----------|---------|-----|
| Feature PR, clean history preferred | Squash merge | One commit per feature in main |
| Feature PR, commits are meaningful | Rebase merge | Preserves history, no merge commit |
| Hotfix | Direct merge or squash | Fast and traceable |
| Long-running branch | Merge commit | Preserves the merge point in history |

**Never rewrite history on shared branches** (`git push --force` on `main`/`develop`).

## Conflict Resolution

```bash
# When rebasing and conflicts arise
git rebase main
# [conflict] edit the file, resolve the markers
git add <resolved-file>
git rebase --continue

# When merging and conflicts arise
git merge main
# [conflict] edit and resolve
git add <resolved-file>
git commit
```

For complex conflicts involving semantic changes (not just line conflicts):
- Read both versions fully before resolving.
- Run tests after resolving — merged code may be syntactically correct but logically wrong.

## Safe Behavior

- Read-only analysis until the user confirms the push.
- Never force push to `main` / `master` / shared branches.
- Never push without local tests passing.
- Never bypass pre-commit hooks with `--no-verify`.
- Flag any `.env`, credentials, or large binary files found in the diff.
- Do not commit on behalf of others without their knowledge.
