#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
file="$root/references/superiority-evidence.md"
generator="$root/scripts/generate-superiority-evidence.sh"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }

[ -f "$file" ] || fail 'superiority-evidence.md missing'
[ -x "$generator" ] || fail 'generate-superiority-evidence.sh missing or not executable'

tmp_generated="$(mktemp)"
trap 'rm -f "$tmp_generated"' EXIT
bash "$generator" > "$tmp_generated"
cmp -s "$tmp_generated" "$file" || fail 'superiority-evidence.md is out of sync with generate-superiority-evidence.sh'
pass 'superiority evidence matches generator output'

for term in 'ECC-only extensions beyond upstream' 'Verified tool wiring targets' 'Reviewed capability packs' 'Verification layers in `status-summary.sh`'; do
  grep -Fq "$term" "$file" || fail "missing superiority metric: $term"
done
pass 'superiority metrics present'

for term in 'Safety' 'Verification' 'Installability' 'Observability' 'Operator UX'; do
  grep -Fq "$term" "$file" || fail "missing superiority category: $term"
done
pass 'superiority categories present'

for term in 'SECURITY_MODEL.md' 'check-installation.sh' 'check-config-integration.sh' 'check-apply-status.sh' 'check-executables.sh' 'check-setup-wizard.sh' 'check-wiring-docs.sh' 'check-status-docs.sh' 'parity-matrix.json' 'status-summary.sh'; do
  grep -Fq "$term" "$file" || fail "missing evidence reference: $term"
done
pass 'superiority evidence references present'

printf '\nSuperiority evidence checks passed.\n'
