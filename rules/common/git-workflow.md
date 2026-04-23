---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Git Workflow — Common Rules

## Commits

- Each commit represents one logical change — not a day's work, not "misc fixes".
- Commit message format: `type(scope): short description` (Conventional Commits).
  - Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `security`, `ci`.
  - Example: `fix(auth): prevent session token reuse after logout`.
- Short description: imperative, present tense, under 72 characters.
- Body (optional): explain *why* the change was made, not what the diff shows.
- Never commit secrets, credentials, or `.env` files.
- Never commit commented-out code blocks.
- Never commit debug statements (`console.log`, `print`, `debugger`, `pdb.set_trace`).
- Never commit with `--no-verify` unless you understand every hook you're bypassing.

## Branches

| Branch | Purpose | Merge strategy |
|--------|---------|----------------|
| `main` / `master` | Production-ready code only | Protected — PR required |
| `feature/<name>` | New functionality | Squash or rebase into main |
| `fix/<name>` | Bug fix | Squash or rebase into main |
| `hotfix/<name>` | Urgent production fix | Direct merge (then tag) |
| `chore/<name>` | Deps, tooling, config | Squash into main |

- Branches should be short-lived — merge and delete within days, not weeks.
- A branch older than 2 weeks with no activity is a smell. Review or close it.
- Delete merged branches promptly — keep the repo clean.

## Pull Requests

- Every PR has a description: what changed, why, and how to test it.
- Link the relevant issue or ticket in the description.
- PR size: aim for changes reviewable in under 30 minutes.
- Large PRs must be split unless splitting would be more confusing than the large diff.
- Address all review comments before merging — do not resolve conversations unilaterally.
- Keep the branch up to date with main before merging (`git rebase main` preferred over merge).
- Self-review the diff before requesting review — no "rough drafts" in PRs.

## Merge Strategy

| Scenario | Preferred strategy | Reason |
|----------|--------------------|--------|
| Feature PR, single logical change | **Squash merge** | Clean linear history |
| Feature PR, meaningful commit sequence | **Rebase merge** | Preserves history, no merge commit |
| Hotfix into main | **Merge commit** | Traceable merge point |
| Long-running integration branch | **Merge commit** | Preserves branch history |

**Never rewrite history on shared branches.** No `push --force` on `main`, `develop`, or any branch others are working on. `push --force-with-lease` on your own feature branch is acceptable if no one else is on it.

## Code Review Etiquette

- Review within one business day.
- Approving means you are confident the change is correct and safe.
- Label your comments:
  - `nit:` — style preference, non-blocking.
  - `?:` — question, must be answered before merge.
  - `suggestion:` — improvement idea, non-blocking.
  - Unlabeled = blocking concern that must be resolved.
- Praise good work when you see it.

## History Hygiene

- Do not rewrite history on shared branches.
- Tags for every release: `v1.2.3` (semantic versioning). Annotated tags preferred.
- Keep `git log --oneline main` readable — each entry should describe one meaningful change.
- Avoid empty merge commits — use rebase to keep history linear.

## Emergency Hotfix Process

```bash
git checkout main
git pull
git checkout -b hotfix/<description>
# make the fix
git commit -m "fix(<scope>): <description>"
git checkout main
git merge hotfix/<description>      # merge commit — traceable
git tag v<major>.<minor>.<patch+1>
git push origin main --tags
git branch -d hotfix/<description>
```

## Common Mistakes to Avoid

- `git add .` — stages everything including `.env`, binaries, OS files. Use `git add -p` or specific paths.
- `git commit -m "WIP"` — not a commit message. Squash before merging.
- Resolving conflicts by accepting "ours" or "theirs" blindly — read the conflict and understand both sides.
- Leaving `<<<<<<`, `======`, `>>>>>>` markers in committed code — always verify with `git diff --staged`.
