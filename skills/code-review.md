# Skill: Code Review

## Trigger

Use when reviewing a PR, a changed file, or a block of code before merging.

## Pre-Review Checklist

Before starting analysis:
- [ ] Read the PR description and linked issue/ticket.
- [ ] Understand the intended behavior — do not judge code you don't understand yet.
- [ ] Identify the change type: feature, bugfix, refactor, chore, security patch.
- [ ] Note the blast radius: how many files, which systems are affected.

## Process

### 1. Understand the change
```bash
git diff main...HEAD           # all changes vs base
git log --oneline main..HEAD   # commits in this PR
git diff --stat                # which files changed, how much
```

### 2. Read changed files in full context
- Read the full function/class around each change, not just the diff hunk.
- Understand caller sites before judging a signature change.
- Check test changes alongside production changes.

### 3. Delegate to specialist agents
| Concern | Agent |
|---------|-------|
| General quality / logic | `code-reviewer` |
| Security vulnerabilities | `security-reviewer` |
| TypeScript / JavaScript | `typescript-reviewer` |
| Python | `python-reviewer` |
| Go | `go-reviewer` |
| Rust | `rust-reviewer` |
| Java | `java-reviewer` |
| Kotlin | `kotlin-reviewer` |
| C++ | `cpp-reviewer` |
| C# | `csharp-reviewer` |
| Flutter / Dart | `flutter-reviewer` |
| Database / SQL | `database-reviewer` |
| Architecture decisions | `architect` |

### 4. Apply rules
- `rules/common/coding-style.md` — applies to all changes
- `rules/common/security.md` — always check
- `rules/common/testing.md` — test coverage and quality
- `rules/<language>/` — language-specific rules for the PR's primary language

### 5. Check what's missing
- New code without tests → flag.
- Changed behavior without updated docs → flag.
- New dependency without justification → flag.
- Database migration without rollback plan → flag.

## Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| CRITICAL | Security hole, data loss, correctness bug | Block merge, fix required |
| HIGH | Will break in production, missing error handling | Block merge |
| MEDIUM | Code quality, performance, maintainability | Request changes |
| LOW | Style, naming, minor suggestions | Comment only, non-blocking |
| NIT | Preference, not a problem | Optional, clearly labeled |

## Output Format

```
## Summary
What this change does in 2–3 sentences.

## Findings

### CRITICAL: [Title] — file.ts:42
**Problem:** What's wrong and why it matters.
**Exploitation/impact:** What could go wrong.
**Fix:**
```code example```

### HIGH: ...
### MEDIUM: ...
### LOW: ...

## Verdict
[ ] Approve
[ ] Approve with minor fixes (LOW/NIT only)
[ ] Request changes (MEDIUM+)
[ ] Block (CRITICAL/HIGH present)
```

## Common Review Traps to Avoid

- **Do not approve because tests pass** — tests can be wrong too.
- **Do not approve because it "looks fine"** — read the logic path under error conditions.
- **Do not block on style if a linter handles it** — let tools own style.
- **Do not suggest refactors unrelated to the PR scope** — open a separate issue.

## Safe Behavior

- Read-only analysis — no file modifications.
- No external calls.
- Does not approve its own output.
- CRITICAL findings require Ahmed's attention before merge.
