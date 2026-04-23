# Skill: Upstream Import

## Trigger

Use when reviewing updates from the upstream repo (`affaan-m/everything-claude-code`) and deciding what to adopt into Agent Runtime Guard.

## Pre-Import: Check Current Sync State

```bash
cd /home/khouly/.openclaw/workspace/tools/ecc-safe-plus
cat references/upstream-sync.md   # last known sync point and date
cat references/import-log.md      # what was accepted/rejected and why
```

## Process

### 1. Fetch latest upstream (read-only)

```bash
git fetch upstream --dry-run       # see what's available
git log HEAD..upstream/main --oneline   # commits since last sync
git diff HEAD..upstream/main --stat     # files changed, volume
```

Do NOT `git merge upstream/main` — review first.

### 2. Review the diff in categories

```bash
# See what new files exist upstream that we don't have
git diff HEAD..upstream/main --name-only --diff-filter=A

# See what existing files were modified upstream
git diff HEAD..upstream/main --name-only --diff-filter=M

# Review a specific file's upstream version
git show upstream/main:agents/some-agent.md
```

### 3. Classify each candidate using import-checklist

For every new or modified upstream file, answer:

| Question | Action if yes |
|----------|--------------|
| Does it make external network calls? | Needs payload review layer before import |
| Does it run shell commands? | Read the commands carefully before importing |
| Does it auto-install packages? | Reject or rewrite — violates D1/D6 |
| Does it expand permissions silently? | Reject — violates D2 |
| Does it add `npx -y` or equivalent? | Reject entirely |
| Is it pure prompts/docs/rules? | Safe to import and adapt |
| Does it conflict with our security model? | Reject or rewrite |

### 4. Classification decision table

| Class | Examples | Action |
|-------|----------|--------|
| Safe local | Agents, rules, doc-only skills, prompt templates | Import and adapt |
| Reviewed external | MCP configs, wrappers with external calls | Import with payload review layer added |
| Needs rewrite | Good concept, but unsafe implementation | Rewrite to match our policy |
| Risky / Reject | Auto-installers, `npx -y`, silent permission expansion | Reject — log the decision |

### 5. Adapt, do not copy raw

When importing:
- Read our version of the same file (if it exists) and compare.
- Keep our extensions and improvements — don't overwrite with a thinner upstream version.
- If upstream is better in some section, cherry-pick that section only.
- Add `# adapted from upstream vX.Y` comment at the top if useful for tracking.

### 6. Verify after import

```bash
bash scripts/audit-local.sh     # ensure no regressions
bash scripts/status-summary.sh  # all green check
```

### 7. Update sync records

```bash
# Update references/upstream-sync.md
# - New sync date
# - Upstream commit hash reviewed
# - Summary of what was reviewed

# Update references/import-log.md
# - For each file: ADDED / REJECTED / ADAPTED — with reason
```

## What to Watch For in Upstream Updates

- **New agents** — compare against our existing agents; don't import if ours is better.
- **New skills** — check if it covers something we're missing; adapt if useful.
- **Modified rules** — check if upstream improved something; cherry-pick improvements.
- **New dependencies or integrations** — always classify before importing.
- **Version bumps** — note if a major version adds capabilities we should evaluate.

## Red Lines (Never Import)

- `npx -y <package>` or equivalent one-shot remote execution.
- Silent permission expansion or auto-approval flows.
- Auto-install of packages without user confirmation.
- Any flow that exfiltrates data without explicit payload review.

## Safe Behavior

- No raw `git merge upstream/main`.
- No auto-install of upstream dependencies.
- Every file reviewed before entering the repo.
- Our improvements are never overwritten by a thinner upstream version.
- Audit passes after every import batch.
- All decisions logged in `references/import-log.md`.
