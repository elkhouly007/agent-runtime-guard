# Skill: checkpoint

## Purpose

Capture a point-in-time snapshot of project state — what works, what is in progress, what is pending. Use before a large refactor, before a release, or when handing off work.

## Trigger

- Before a major refactor or risky change
- Before cutting a release branch
- At the end of a work session with unfinished threads
- When another person or agent is taking over the work

## Trigger

`/checkpoint` or `checkpoint the current state`

## Steps

1. **Run status checks**
   - `git status` — uncommitted changes
   - `git log --oneline -10` — recent commit history
   - Test suite: `npm test` / `pytest` / `cargo test` / `go test ./...`
   - Build: confirm it compiles cleanly

2. **Document what works**
   - Features and flows that are complete and tested
   - API contracts that are stable
   - Infrastructure that is running

3. **Document what is in progress**
   - Branches with open PRs
   - Files with uncommitted changes
   - Partially implemented features

4. **Document what is pending**
   - Known bugs or TODOs in the code
   - Features planned but not started
   - Blocked items and their blockers

5. **Write the checkpoint file**
   - Save to `CHECKPOINT.md` in the project root (or a `checkpoints/` directory with a date-stamped name)
   - Format: date, works/in-progress/pending sections, next recommended action

## Output Format

```markdown
# Checkpoint — YYYY-MM-DD

## Status: [Green / Yellow / Red]

## What Works
- ...

## In Progress
- ...

## Pending / Blocked
- ...

## Recommended Next Step
- ...
```

## Safe Behavior

- Read-only: this skill only reads state and writes a markdown file.
- Does not commit, push, or modify any source files.
- If test suite is failing, report it clearly — do not hide failures.
