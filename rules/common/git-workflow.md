---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Git Workflow

Standards for using git in a way that produces a useful, honest history.

## Commits

- Every commit should represent one logical change. If you need "and" to describe the commit, it should be two commits.
- Commit messages: one-line summary under 72 characters describing WHAT changed. Body paragraph (when needed) explaining WHY.
- Present tense imperative: "Add rate limiting to API endpoints" not "Added" or "Adding."
- Never include implementation details in the commit message. The diff shows what changed. The message explains why.
- Do not commit commented-out code, debug statements, or temporary scaffolding.
- Commit working code only. A commit that breaks the build creates problems for everyone who bases work on it.

## Branches

- Branch names: descriptive, lowercase, hyphenated. `feature/user-auth-refresh-tokens`, not `johns-branch` or `fix1`.
- Short-lived branches are better than long-lived ones. Long-lived branches accumulate merge debt.
- Keep branches focused on one change. A branch that touches authentication and billing and logging is harder to review and harder to revert.
- Delete branches after merging. Dead branches are noise.

## Pull Requests

- A PR should be reviewable in one sitting. If reviewing takes more than 30 minutes, the PR is too large.
- The PR description should explain: what changed, why it changed, and how to verify it works.
- Link the PR to the issue it resolves. Context for reviewers and for future bisecting.
- Tests must pass before requesting review. Requesting review on failing tests wastes reviewer time.
- Respond to review comments before requesting re-review. Let the reviewer know each comment was addressed.

## History Hygiene

- Never rewrite history on a shared branch. Rebasing or amending commits that others have built on creates divergent histories.
- Squash micro-commits (wip, typo fix, forgot to add file) before merging to main. Every commit on main should be meaningful.
- `git bisect` requires a meaningful history. A history full of squashed and noise commits is useless for bisecting bugs.

## Sensitive Data

- Never commit secrets, credentials, or PII to git. Git history is permanent — even after deletion, the data exists in forks and clones.
- Use pre-commit hooks to scan for secrets. ARG hooks (`secret-warning.js`) provide this protection.
- If a secret is accidentally committed: invalidate it immediately, then remove it from history using git-filter-repo.
