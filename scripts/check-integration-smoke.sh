#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

for file in \
  openclaw/WIRING_PLAN.md \
  openclaw/OPENCLAW_POLICY_MAP.md \
  openclaw/OPENCLAW_APPLY_CHECKLIST.md \
  openclaw/COMPATIBILITY_STRATEGY.md \
  templates/openclaw/openclaw-modules.example.md \
  opencode/opencode.safe.jsonc \
  opencode/commands/plan-safe.md \
  opencode/WIRING_PLAN.md \
  opencode/OPENCODE_POLICY_MAP.md \
  opencode/OPENCODE_APPLY_CHECKLIST.md \
  opencode/COMPATIBILITY_STRATEGY.md \
  templates/opencode/opencode-modules.example.jsonc \
  claude/AGENTS.md \
  claude/hooks/secret-warning.js \
  claude/WIRING_PLAN.md \
  claude/CLAUDE_POLICY_MAP.md \
  claude/CLAUDE_APPLY_CHECKLIST.md \
  claude/COMPATIBILITY_STRATEGY.md \
  templates/claude-code/claude-modules.example.md \
  modules/mcp-pack/registry.json \
  modules/wrapper-pack/registry.json \
  modules/plugin-pack/registry.json \
  modules/browser-pack/registry.json \
  modules/notification-pack/registry.json \
  modules/daemon-pack/registry.json \
  scripts/classify-payload.sh \
  scripts/redact-payload.sh \
  scripts/review-payload.sh \
  scripts/test-payload-protection.sh \
  references/payload-classification.md \
  references/payload-redaction.md \
  references/upstream-sync.md \
  references/vendor-policy.md \
  references/import-checklist.md \
  references/import-report-template.md
 do
  if [ ! -f "$file" ]; then
    printf '%s\n' "Missing integration smoke file: $file" >&2
    exit 1
  fi
 done

printf '%s\n' "Integration smoke check passed."
