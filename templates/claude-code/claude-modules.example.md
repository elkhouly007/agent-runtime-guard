# Claude Code Modules Example

Use this as a project-local example for referencing reviewed Safe-Plus capability packs.

## Example References

- AGENTS -> `tools/ecc-safe-plus/claude/AGENTS.md`
- hooks -> `tools/ecc-safe-plus/claude/hooks/`
- MCP registry -> `tools/ecc-safe-plus/modules/mcp-pack/registry.json`
- wrapper registry -> `tools/ecc-safe-plus/modules/wrapper-pack/registry.json`
- plugin registry -> `tools/ecc-safe-plus/modules/plugin-pack/registry.json`

## Example Rule

Use local warning hooks directly. Use external capability packs only after reviewing the outbound payload and confirming it does not contain personal or confidential data unless the user approved it.

## Example Escalation

If a module would delete data, overwrite important files, use elevated privileges, or send sensitive data externally, stop and ask the user.
