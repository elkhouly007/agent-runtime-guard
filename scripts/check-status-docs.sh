#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
parity_file="$root/references/parity-matrix.json"
parity_report="$root/references/parity-report.md"
full_power="$root/references/full-power-status.md"
parity_generator="$root/scripts/generate-parity-report.sh"
readme_file="$root/README.md"
skills_readme="$root/skills/README.md"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }

[ -f "$parity_file" ] || fail 'parity-matrix.json missing'
[ -f "$parity_report" ] || fail 'parity-report.md missing'
[ -f "$full_power" ] || fail 'full-power-status.md missing'
[ -f "$readme_file" ] || fail 'README.md missing'
[ -f "$skills_readme" ] || fail 'skills/README.md missing'
[ -x "$parity_generator" ] || fail 'generate-parity-report.sh missing or not executable'

tmp_generated="$(mktemp)"
trap 'rm -f "$tmp_generated"' EXIT
bash "$parity_generator" > "$tmp_generated"
cmp -s "$tmp_generated" "$parity_report" || fail 'parity-report.md is out of sync with generate-parity-report.sh'
pass 'parity-report matches generator output'

counts="$(awk '
  BEGIN { in_sum=0; comp=""; ac=""; au=""; ae=""; rc=""; ru=""; re=""; sc=""; su=""; se="" }
  /"summary":/ { in_sum=1; next }
  !in_sum { next }
  /"agents":/ { comp="agents"; next }
  /"rules":/ { comp="rules"; next }
  /"skills":/ { comp="skills"; next }
  comp == "agents" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); ac=v }
  comp == "agents" && /"upstream_total":/ { v=$0; gsub(/[^0-9]/,"",v); au=v }
  comp == "agents" && /"current_only_total":/ { v=$0; gsub(/[^0-9]/,"",v); ae=v }
  comp == "rules" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); rc=v }
  comp == "rules" && /"upstream_total":/ { v=$0; gsub(/[^0-9]/,"",v); ru=v }
  comp == "rules" && /"current_only_total":/ { v=$0; gsub(/[^0-9]/,"",v); re=v }
  comp == "skills" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); sc=v }
  comp == "skills" && /"upstream_total":/ { v=$0; gsub(/[^0-9]/,"",v); su=v }
  comp == "skills" && /"current_only_total":/ { v=$0; gsub(/[^0-9]/,"",v); se=v }
  END { print ac, au, ae, rc, ru, re, sc, su, se }
' "$parity_file")"
set -- $counts
agents_current="$1"; agents_upstream="$2"; agents_only="$3"
rules_current="$4"; rules_upstream="$5"; rules_only="$6"
skills_current="$7"; skills_upstream="$8"; skills_only="$9"

grep -Fq "**${agents_current} specialist agents**, including full coverage of the ${agents_upstream} upstream agents plus ${agents_only} ECC-only additions;" "$full_power" || fail 'full-power-status agent summary drifted'
grep -Fq "**${rules_current} rule files** with **${rules_upstream} direct upstream matches** and ${rules_only} ECC-only additions;" "$full_power" || fail 'full-power-status rule summary drifted'
grep -Fq "**${skills_current} skill files** with **${skills_upstream} direct upstream matches** and ${skills_only} ECC-only additions;" "$full_power" || fail 'full-power-status skill summary drifted'
pass 'full-power-status top-level counts aligned'

for row in \
  "| Agents | ${agents_upstream} | ${agents_current} | ${agents_upstream} | 0 | ${agents_only} |" \
  "| Rules | ${rules_upstream} | ${rules_current} | ${rules_upstream} | 0 | ${rules_only} |" \
  "| Skills | ${skills_upstream} | ${skills_current} | ${skills_upstream} | 0 | ${skills_only} |"
do
  grep -Fq "$row" "$full_power" || fail "full-power-status parity snapshot drifted: $row"
done
pass 'full-power-status parity table aligned'

scripts_total="$(find "$root/scripts" -maxdepth 1 -type f | wc -l | tr -d ' ')"
grep -Fq '### Agents (`agents/`) — 48 files' "$readme_file" || fail 'README agent count drifted'
grep -Fq '### Rules (`rules/`) — 91 files' "$readme_file" || fail 'README rule count drifted'
grep -Fq '### Skills (`skills/`) — 199 files' "$readme_file" || fail 'README skill count drifted'
scripts_heading="### Scripts (\`scripts/\`) — ${scripts_total} files"
grep -Fq "$scripts_heading" "$readme_file" || fail 'README scripts count drifted'
pass 'README top-level counts aligned'

grep -Fq "**${skills_current} skills**" "$skills_readme" || fail 'skills/README skill count drifted'
grep -Fq 'selected examples, not an exhaustive index' "$skills_readme" || fail 'skills/README scope note missing'
pass 'skills/README count and scope note aligned'

apply_status="$root/references/per-tool-apply-status.md"
[ -f "$apply_status" ] || fail 'per-tool-apply-status.md missing'
grep -Fq "Agents (${agents_current})" "$apply_status" || fail "per-tool-apply-status agents count not updated (${agents_current})"
grep -Fq "Rules (${rules_current})" "$apply_status" || fail "per-tool-apply-status rules count not updated (${rules_current})"
grep -Fq "Skills (${skills_current})" "$apply_status" || fail "per-tool-apply-status skills count not updated (${skills_current})"
pass 'per-tool-apply-status counts aligned with parity matrix'

printf '\nStatus docs checks passed.\n'
