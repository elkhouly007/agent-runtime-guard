# OpenClaw Modules Example

Use this as a project-local example for enabling reviewed Safe-Plus capability packs without patching OpenClaw core.

## Example Capability References

- planner prompt -> `tools/ecc-safe-plus/openclaw/prompts/planner.md`
- reviewer prompt -> `tools/ecc-safe-plus/openclaw/prompts/reviewer.md`
- security prompt -> `tools/ecc-safe-plus/openclaw/prompts/security.md`
- MCP registry -> `tools/ecc-safe-plus/modules/mcp-pack/registry.json`
- wrapper registry -> `tools/ecc-safe-plus/modules/wrapper-pack/registry.json`
- plugin registry -> `tools/ecc-safe-plus/modules/plugin-pack/registry.json`
- browser registry -> `tools/ecc-safe-plus/modules/browser-pack/registry.json`
- notification registry -> `tools/ecc-safe-plus/modules/notification-pack/registry.json`

## Example Rule

Before using any external capability, review the outbound payload and confirm it does not contain personal or confidential data unless the user approved it.

## Example Escalation

If a capability would delete data, overwrite an important file, use elevated privileges, or send sensitive data externally, stop and ask the user.
