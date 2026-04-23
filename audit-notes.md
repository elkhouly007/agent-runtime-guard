# Audit Notes

Initial safe-plus construction notes:

- Kept source reference files separate from generated safe-plus files.
- Did not copy `.mcp.json` or create any MCP config.
- Did not copy plugin code or plugin configuration.
- Did not copy dependency installers.
- Did not include notification integrations.
- Did not include NanoClaw, REPL wrappers, daemons, or global setup flows.
- Adapted the useful pattern of local prompts, role specialization, and lightweight hooks.

Expected audit behavior:

- `source-*` reference files may contain risky patterns because they document the upstream behavior that was intentionally not carried forward.
- `audit-local.sh` excludes the source reference files by default so the safe-plus output can be reviewed separately.
- Run `./scripts/audit-local.sh --include-source` when you want to inspect the references too.
