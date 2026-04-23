#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
status_file="$root/references/per-tool-apply-status.md"
parity_file="$root/references/parity-matrix.json"
generator="$root/scripts/generate-apply-status.sh"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }

[ -f "$status_file" ] || fail 'per-tool-apply-status.md missing'
[ -f "$parity_file" ] || fail 'parity-matrix.json missing'
[ -x "$generator" ] || fail 'generate-apply-status.sh missing or not executable'

tmp_generated="$(mktemp)"
trap 'rm -f "$tmp_generated"' EXIT
bash "$generator" > "$tmp_generated"
if ! cmp -s "$tmp_generated" "$status_file"; then
  fail 'per-tool-apply-status.md is out of sync with generate-apply-status.sh'
fi
pass 'apply-status file matches generator output'

counts="$(awk '
  BEGIN { in_sum=0; comp=""; ac=""; rc=""; sc="" }
  /"summary":/ { in_sum=1; next }
  !in_sum { next }
  /"agents":/ { comp="agents"; next }
  /"rules":/ { comp="rules"; next }
  /"skills":/ { comp="skills"; next }
  comp == "agents" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); ac=v }
  comp == "rules" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); rc=v }
  comp == "skills" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); sc=v }
  END { print ac, rc, sc }
' "$parity_file")"
set -- $counts
agents_total="$1"
rules_total="$2"
skills_total="$3"

for tool in 'Claude Code (`claude/`)' 'OpenCode (`opencode/`)' 'OpenClaw (`openclaw/`)'; do
  grep -Fq "$tool" "$status_file" || fail "$tool section missing"
done
pass 'tool sections present'

grep -Fq "Agents (${agents_total})" "$status_file" || fail "apply-status agents count not updated (${agents_total})"
grep -Fq "Rules (${rules_total})" "$status_file" || fail "apply-status rules count not updated (${rules_total})"
grep -Fq "Skills (${skills_total})" "$status_file" || fail "apply-status skills count not updated (${skills_total})"
pass 'apply-status counts aligned with parity matrix'

for plan in "$root/claude/WIRING_PLAN.md" "$root/opencode/WIRING_PLAN.md" "$root/openclaw/WIRING_PLAN.md"; do
  [ -f "$plan" ] || fail "missing wiring plan: $(basename "$plan")"
done
pass 'wiring plans present'

for doc in \
  "$root/claude/CLAUDE_POLICY_MAP.md" \
  "$root/claude/CLAUDE_APPLY_CHECKLIST.md" \
  "$root/opencode/OPENCODE_POLICY_MAP.md" \
  "$root/opencode/OPENCODE_APPLY_CHECKLIST.md" \
  "$root/openclaw/OPENCLAW_POLICY_MAP.md" \
  "$root/openclaw/OPENCLAW_APPLY_CHECKLIST.md"
 do
  [ -f "$doc" ] || fail "missing wiring support doc: $(basename "$doc")"
done
pass 'policy maps and apply checklists present'

for term in 'Payload protection' 'Policy layers (1–3)' 'Browser pack' 'Notification pack' 'Daemon pack'; do
  grep -Fq "$term" "$status_file" || fail "apply-status missing row: $term"
done
pass 'core apply-status rows present'

printf '\nApply-status checks passed.\n'
