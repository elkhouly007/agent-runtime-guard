# OpenClaw Task Profile Example

## Planner Task

Use `tools/ecc-safe-plus/openclaw/prompts/planner.md` when a task needs scoped planning before edits.

## Reviewer Task

Use `tools/ecc-safe-plus/openclaw/prompts/reviewer.md` when a task needs bug-first review without code mutation.

## Security Task

Use `tools/ecc-safe-plus/openclaw/prompts/security.md` when a task needs risk review for secrets, auth, file writes, command execution, or outbound data exposure.

## Escalation Rule

If the task would delete data, overwrite important existing data, send personal or confidential content externally, or require elevated access, stop and ask the user.
