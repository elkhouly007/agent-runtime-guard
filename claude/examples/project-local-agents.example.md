# Project-Local Claude Code Instructions Example

Use this as a project-local reference pattern. Copy or adapt it into a project document rather than editing Claude Code core or user-level files.

## Example Content

This project uses Agent Runtime Guard as an external AGENTS and hook layer.

Available local hook files:

- `tools/ecc-safe-plus/claude/hooks/secret-warning.js`
- `tools/ecc-safe-plus/claude/hooks/build-reminder.js`
- `tools/ecc-safe-plus/claude/hooks/git-push-reminder.js`

Approval model:

- proceed for local, non-destructive work;
- review outbound payloads before trusted external prompts or agents;
- ask the user before deletion, destructive overwrite, personal/confidential outbound data, elevated actions, or unclear external routing.
