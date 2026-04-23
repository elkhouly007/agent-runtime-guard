# NanoClaw REPL

Use this skill when running or extending `scripts/claw.js`.

## Trigger

Use when:
- working on the NanoClaw REPL or its command surface,
- extending session, export, or model-switching behavior,
- debugging REPL workflow, compaction, branching, or metrics,
- documenting how operators should use `scripts/claw.js` safely.

## Capabilities

- persistent markdown-backed sessions
- model switching with `/model`
- dynamic skill loading with `/load`
- session branching with `/branch`
- cross-session search with `/search`
- history compaction with `/compact`
- export to md/json/txt with `/export`
- session metrics with `/metrics`

## Operating Guidance

1. Keep sessions task-focused.
2. Branch before high-risk changes.
3. Compact after major milestones.
4. Export before sharing or archival.

## Extension Rules

- keep zero external runtime dependencies
- preserve markdown-as-database compatibility
- keep command handlers deterministic and local
