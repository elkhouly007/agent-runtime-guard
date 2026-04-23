#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }
check_file() { [ -f "$1" ] || fail "$2"; }

check_file "$root/claude/WIRING_PLAN.md" 'claude wiring plan'
check_file "$root/claude/CLAUDE_POLICY_MAP.md" 'claude policy map'
check_file "$root/claude/CLAUDE_APPLY_CHECKLIST.md" 'claude apply checklist'
check_file "$root/claude/COMPATIBILITY_STRATEGY.md" 'claude compatibility strategy'

check_file "$root/opencode/WIRING_PLAN.md" 'opencode wiring plan'
check_file "$root/opencode/OPENCODE_POLICY_MAP.md" 'opencode policy map'
check_file "$root/opencode/OPENCODE_APPLY_CHECKLIST.md" 'opencode apply checklist'
check_file "$root/opencode/COMPATIBILITY_STRATEGY.md" 'opencode compatibility strategy'
check_file "$root/opencode/opencode.safe.jsonc" 'opencode safe config template'

check_file "$root/openclaw/WIRING_PLAN.md" 'openclaw wiring plan'
check_file "$root/openclaw/OPENCLAW_POLICY_MAP.md" 'openclaw policy map'
check_file "$root/openclaw/OPENCLAW_APPLY_CHECKLIST.md" 'openclaw apply checklist'
check_file "$root/openclaw/COMPATIBILITY_STRATEGY.md" 'openclaw compatibility strategy'

pass 'tool wiring docs present for claude, opencode, and openclaw'
printf '\nWiring docs checks passed.\n'
