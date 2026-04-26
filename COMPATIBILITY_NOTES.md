# Host Harness Compatibility Notes

Six harnesses are supported. Three are **production-grade** (well-documented, verified hook APIs, full fixture coverage). Three are **best-effort** (stub adapters with assumed input shapes; verify against your actual harness before deploying).

---

## Production harnesses

### Claude Code
- **Hook API**: `{"tool_name":"Bash","tool_input":{"command":"..."},"cwd":"..."}`
- **Activation**: `.claude/settings.json` → `hooks.PreToolUse` array pointing to `claude/hooks/dangerous-command-gate.js`
- **Enforce mode**: `HORUS_ENFORCE=1`
- **Status**: Production — full fixture coverage, native hooks system

### OpenClaw
- **Hook API**: `{"tool":"shell","cmd":"...","cwd":"..."}`
- **Activation**: `.openclaw/settings.json` → hooks entry pointing to `openclaw/hooks/adapter.js`
- **Enforce mode**: `HORUS_ENFORCE=1`
- **Status**: Production — confirmed payload shape, full fixture coverage

### OpenCode
- **Hook API**: `{"tool_name":"Bash","args":{"command":"..."}}`  (note: `args`, not `tool_input`)
- **Activation**: `.opencode/config.json` → hooks configuration pointing to `opencode/hooks/adapter.js`
- **Enforce mode**: `HORUS_ENFORCE=1`
- **Status**: Production — confirmed payload shape, full fixture coverage

---

## Best-effort harnesses

### Codex (OpenAI Codex CLI)
- **Hook API**: `{"session_id":"...","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"..."}}`
- **Activation**: Register `codex/hooks/adapter.js` as a PreToolUse hook in your Codex configuration
- **Enforce mode**: `HORUS_ENFORCE=1`
- **Status**: Best-effort — hook API structure inferred from Codex CLI source; confirmed compatible with fixture suite; verify before production use
- **Notes**: Codex wraps the Claude Code `tool_input` shape inside a `session_id`/`hook_event_name` envelope. The adapter extracts `tool_input.command` which covers this shape.

### ClawCode
- **Hook API**: `{"tool_name":"Bash","tool_input":{"command":"..."}}` (assumed — mirrors Claude Code)
- **Activation**: Register `clawcode/hooks/adapter.js` as a PreToolUse hook
- **Enforce mode**: `HORUS_ENFORCE=1`
- **Status**: Best-effort — API not publicly documented; assumed Claude Code compat based on available evidence
- **Notes**: If the actual payload shape differs, update `extractCommand` in `clawcode/hooks/adapter.js`. The adapter's fallback chain (`i.command || i.cmd || i.tool_input?.command || i.args?.command`) covers most likely variants.

### Antegravity
- **Hook API**: Unknown (possibly internal Google tooling, not publicly documented)
- **Activation**: Register `antegravity/hooks/adapter.js` as a PreToolUse hook
- **Enforce mode**: `HORUS_ENFORCE=1`
- **Status**: Stub — API undocumented; adapter uses the broadest possible fallback chain; **test your actual payload shape before deploying**
- **Notes**: This adapter will not be promoted from stub until the hook API is documented or a verified payload is obtained. The fixture suite uses the assumed Claude Code shape (`tool_input.command`) for baseline coverage only.

---

## Environment variables

| Variable | Default | Effect |
|---|---|---|
| `HORUS_ENFORCE` | `0` | `1` = block mode (exit 2 on dangerous commands); `0` = warn mode (exit 0, log to stderr) |
| `HORUS_KILL_SWITCH` | unset | `1` = kill-switch active; all PreToolUse gates exit 2 immediately |
| `HORUS_STATE_DIR` | `~/.horus` | Override state directory (useful in CI for isolation) |
| `HORUS_RATE_LIMIT` | `1` | `0` = disable rate limiting (useful in CI/fixture testing) |
| `HORUS_HOOK_LOG` | `0` | `1` = verbose hook debug logging |

---

## Cross-harness equivalence

All six harnesses are tested for identical decision output on the same commands via `scripts/check-cross-harness-equivalence.sh`. For any given input command, all harnesses must agree on whether to allow, warn, or block. This is validated in CI.
