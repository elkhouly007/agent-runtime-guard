# Wiring Plan — Codex and ClawCode Adapters

This document covers how to wire the Codex and ClawCode adapters into their respective harness hook systems. Antegravity stays as a stub until its hook API is documented.

---

## Codex (OpenAI Codex CLI)

### Hook mechanism
Codex CLI supports a hooks system via `~/.codex/config.toml` or a project-level `.codex/config.toml`. The PreToolUse hook receives the payload documented in `COMPATIBILITY_NOTES.md` via stdin and expects an exit code: `0` = allow, `2` = block.

### Wiring steps

**1. Identify the config file**
```
~/.codex/config.toml           # user-level (applies to all projects)
.codex/config.toml             # project-level (checked into repo)
```

**2. Add the hook entry**
```toml
[hooks]
pre_tool_use = ["node /path/to/agent-runtime-guard/codex/hooks/adapter.js"]
```

If using a relative path (project-level config):
```toml
[hooks]
pre_tool_use = ["node ../../agent-runtime-guard/codex/hooks/adapter.js"]
```

**3. Set enforce mode (optional)**
```bash
export HORUS_ENFORCE=1
```

Or set it permanently in your shell profile. In warn mode (default), the adapter logs dangerous commands to stderr but exits 0.

**4. Verify**
```bash
# Smoke test — should exit 0 and log nothing concerning
echo '{"session_id":"test","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
  | node codex/hooks/adapter.js

# Smoke test in enforce mode — should exit 2 and log BLOCKED
echo '{"session_id":"test","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' \
  | HORUS_ENFORCE=1 node codex/hooks/adapter.js; echo "exit=$?"

# Run full fixture suite
bash scripts/run-fixtures.sh
```

### Payload verification
The Codex adapter's `extractCommand` fallback chain is:
```
i.command || i.cmd || i.tool_input?.command || i.input?.command || i.args?.command || i.params?.command
```
If your Codex version uses a different shape, capture a real payload by temporarily adding:
```javascript
process.stderr.write(JSON.stringify(JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')),null,2)+'\n');
```
to the top of `codex/hooks/adapter.js`, then update `extractCommand` accordingly.

---

## ClawCode

### Hook mechanism
ClawCode hook API is not publicly documented. Based on available evidence, ClawCode mirrors the Claude Code hook system. The assumed mechanism:

**Option A — `settings.json` (Claude Code compat)**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{ "type": "command", "command": "node /path/to/clawcode/hooks/adapter.js" }]
      }
    ]
  }
}
```

**Option B — Environment variable**
Some ClawCode versions may support a `CLAWCODE_HOOK_PRETOOLUSE` environment variable pointing to a hook script.

### Wiring steps

**1. Locate ClawCode configuration**
Check for:
- `.clawcode/settings.json`
- `~/.clawcode/settings.json`
- `CLAWCODE_CONFIG` environment variable

**2. Add the hook (Option A — settings.json)**
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": ".*",
        "hooks": [{ "type": "command", "command": "node /abs/path/to/clawcode/hooks/adapter.js" }]
      }
    ]
  }
}
```

**3. Verify payload shape**
ClawCode may send a different payload than assumed. Capture a real payload to confirm:
```bash
# Temporarily add payload logging to the adapter, run a ClawCode session,
# then update extractCommand if the actual shape differs.
```

**4. Verify with fixtures**
```bash
bash scripts/run-fixtures.sh | grep "clawcode"
```

### Promotion criteria
ClawCode will be promoted from best-effort to production when:
1. The hook API shape is confirmed from ClawCode source code or documentation
2. A verified payload from a running ClawCode session is captured and matched against the adapter's extractCommand
3. Any shape differences are handled in the adapter

---

## Antegravity (stub only)

Antegravity remains a stub. Its hook API is undocumented and may be an internal Google tool not available for external integration. No wiring steps can be provided without a documented hook mechanism.

**Promotion path**: If Antegravity publishes a hooks API or source code becomes available, update `antegravity/hooks/adapter.js` with the verified `extractCommand`, then promote by following the same verification steps as Codex.

---

## Shared verification checklist

For any harness, before declaring production-ready:

- [ ] Confirmed hook payload shape (from source, docs, or captured real payload)
- [ ] `extractCommand` correctly extracts the shell command from the confirmed shape
- [ ] Safe command exits 0 in warn mode (fixture: `*-safe-ls`)
- [ ] Dangerous command logs warning and exits 0 in warn mode (fixture: `*-dangerous-rm-rf`)
- [ ] Dangerous command exits 2 in enforce mode (fixture: `*-enforce-rm-rf`)
- [ ] Critical command exits 2 in both modes (fixture: `*-enforce-rm-no-preserve-root`)
- [ ] Kill-switch exits 2 regardless of command (fixture: `ks-*-adapter`)
- [ ] Cross-harness equivalence test passes: `bash scripts/check-cross-harness-equivalence.sh`
