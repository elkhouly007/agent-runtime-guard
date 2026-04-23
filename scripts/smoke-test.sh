#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

./scripts/check-registries.sh >/dev/null
./scripts/audit-local.sh >/dev/null
./scripts/review-payload.sh tests/sample-payload.txt >/dev/null

for file in \
  templates/openclaw/openclaw-modules.example.md \
  templates/opencode/opencode-modules.example.jsonc \
  templates/claude-code/claude-modules.example.md
 do
  if [ ! -f "$file" ]; then
    printf '%s\n' "Missing template: $file" >&2
    exit 1
  fi
 done

printf '%s\n' "Smoke test passed."
