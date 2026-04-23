# Skill: Git Worktree Patterns

## Trigger

Use when working on multiple features simultaneously without context-switching between branches, when running long CI-equivalent checks on one branch while continuing work on another, or when using the "cascade method" for parallel agent-driven development.

## Core Concept

`git worktree` creates additional working directories linked to the same repository — each worktree can be on a different branch simultaneously. Changes in one worktree do not affect others.

```
repo/                    ← main worktree (main branch)
repo-worktrees/
  feature-auth/          ← worktree (feature/auth branch)
  feature-payments/      ← worktree (feature/payments branch)
  hotfix-prod/           ← worktree (hotfix/prod branch)
```

## Basic Commands

```bash
# Create a new worktree on a new branch
git worktree add ../repo-feature-auth -b feature/auth

# Create a new worktree on an existing branch
git worktree add ../repo-hotfix hotfix/prod

# List all worktrees
git worktree list

# Remove a worktree (after merging / no longer needed)
git worktree remove ../repo-feature-auth

# Prune stale worktree references (after manual directory removal)
git worktree prune
```

## The Cascade Method (Parallel Agent Development)

The cascade method uses worktrees to run multiple agent tasks in parallel without interference:

### Setup

```bash
# From the main repo root
mkdir -p ../worktrees

# Create one worktree per parallel stream
git worktree add ../worktrees/stream-api -b feature/api-layer
git worktree add ../worktrees/stream-ui -b feature/ui-layer
git worktree add ../worktrees/stream-tests -b feature/test-suite
```

### Execution pattern

1. Assign each sub-agent to one worktree directory.
2. Sub-agents work independently — no branch conflicts, no file locks.
3. When each stream completes: review its branch diff before merging.
4. Merge streams in dependency order (e.g., API layer → tests → UI).
5. Remove the worktree after its branch is merged.

```bash
# After stream-api is merged to main
git worktree remove ../worktrees/stream-api
git branch -d feature/api-layer
```

### Cascade merge order

```
feature/api-layer  ──┐
                     ├──→ feature/integration ──→ main
feature/ui-layer   ──┘
        ↑
feature/test-suite (runs against integration)
```

## Practical Patterns

### Running tests on a branch without switching

```bash
# Create a temporary worktree for the branch under test
git worktree add /tmp/test-branch origin/feature/new-auth
cd /tmp/test-branch
npm test
cd -
git worktree remove /tmp/test-branch
```

### Keeping a stable reference worktree

```bash
# Keep main always available for comparison
git worktree add ../repo-main main
# Now you can diff against main without checking it out
diff -r ../repo-main/src ./src
```

### Hotfix while on a feature branch

```bash
# Don't stash your feature work — just open a new worktree
git worktree add ../repo-hotfix -b hotfix/critical-bug
cd ../repo-hotfix
# Fix, commit, push — main worktree untouched
git worktree remove ../repo-hotfix
```

## Constraints and Gotchas

- You cannot check out the same branch in two worktrees simultaneously — git will error.
- Worktrees share the same `.git` directory — `git fetch` in any worktree updates all of them.
- Node `node_modules` are NOT shared — run `npm install` in each worktree separately.
- Do not create worktrees inside the main repo directory — create them as siblings to avoid accidental git tracking.
- Always clean up worktrees after merging — stale worktrees cause `git worktree list` noise and can prevent branch deletion.
