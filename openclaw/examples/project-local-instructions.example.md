# Project-Local OpenClaw Instructions Example

Use this as a project-local reference pattern. Copy or adapt it into a project document rather than editing OpenClaw core files.

## Example Content

This project uses Agent Runtime Guard as an external policy and prompt layer.

Available prompt roles:

- planner -> `tools/ecc-safe-plus/openclaw/prompts/planner.md`
- reviewer -> `tools/ecc-safe-plus/openclaw/prompts/reviewer.md`
- security -> `tools/ecc-safe-plus/openclaw/prompts/security.md`

Approval model:

- proceed for local, non-destructive work;
- review outbound payloads before trusted external prompts or agents;
- ask the user before deletion, destructive overwrite, personal/confidential outbound data, elevated actions, or unclear external routing.
