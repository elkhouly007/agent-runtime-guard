# Claude Code Modules Example

Use this as a project-local example for referencing reviewed Safe-Plus capability packs.

## Example References

- AGENTS -> `tools/horus/claude/AGENTS.md`
- hooks -> `tools/horus/claude/hooks/`
- MCP registry -> `tools/horus/modules/mcp-pack/registry.json`
- wrapper registry -> `tools/horus/modules/wrapper-pack/registry.json`
- plugin registry -> `tools/horus/modules/plugin-pack/registry.json`

## Example Rule

Use local warning hooks directly. Use external capability packs only after reviewing the outbound payload and confirming it does not contain personal or confidential data unless the user approved it.

## Example Escalation

If a module would delete data, overwrite important files, use elevated privileges, or send sensitive data externally, stop and ask the user.
