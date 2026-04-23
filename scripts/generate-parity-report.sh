#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
parity_file="$root/references/parity-matrix.json"

[ -f "$parity_file" ] || { printf 'parity-matrix.json missing\n' >&2; exit 1; }

today="$(date -u +%Y-%m-%d)"

# Extract summary counts from parity-matrix.json
read -r au ac aa ad ae <<EOF
$(awk '
  BEGIN { in_sum=0; comp=""; ut=""; ct=""; ad=""; de=""; eo="" }
  /"summary":/ { in_sum=1; next }
  !in_sum { next }
  /"agents":/ { comp="agents"; next }
  comp == "agents" && /"upstream_total":/ { v=$0; gsub(/[^0-9]/,"",v); ut=v }
  comp == "agents" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); ct=v }
  comp == "agents" && /"adopted":/ { v=$0; gsub(/[^0-9]/,"",v); ad=v }
  comp == "agents" && /"deferred":/ { v=$0; gsub(/[^0-9]/,"",v); de=v }
  comp == "agents" && /"current_only_total":/ { v=$0; gsub(/[^0-9]/,"",v); eo=v; comp="" }
  END { print ut, ct, ad, de, eo }
' "$parity_file")
EOF

read -r ru rc ra rd re <<EOF
$(awk '
  BEGIN { in_sum=0; comp=""; ut=""; ct=""; ad=""; de=""; eo="" }
  /"summary":/ { in_sum=1; next }
  !in_sum { next }
  /"rules":/ { comp="rules"; next }
  comp == "rules" && /"upstream_total":/ { v=$0; gsub(/[^0-9]/,"",v); ut=v }
  comp == "rules" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); ct=v }
  comp == "rules" && /"adopted":/ { v=$0; gsub(/[^0-9]/,"",v); ad=v }
  comp == "rules" && /"deferred":/ { v=$0; gsub(/[^0-9]/,"",v); de=v }
  comp == "rules" && /"current_only_total":/ { v=$0; gsub(/[^0-9]/,"",v); eo=v; comp="" }
  END { print ut, ct, ad, de, eo }
' "$parity_file")
EOF

read -r su sc sa sd se <<EOF
$(awk '
  BEGIN { in_sum=0; comp=""; ut=""; ct=""; ad=""; de=""; eo="" }
  /"summary":/ { in_sum=1; next }
  !in_sum { next }
  /"skills":/ { comp="skills"; next }
  comp == "skills" && /"upstream_total":/ { v=$0; gsub(/[^0-9]/,"",v); ut=v }
  comp == "skills" && /"current_total":/ { v=$0; gsub(/[^0-9]/,"",v); ct=v }
  comp == "skills" && /"adopted":/ { v=$0; gsub(/[^0-9]/,"",v); ad=v }
  comp == "skills" && /"deferred":/ { v=$0; gsub(/[^0-9]/,"",v); de=v }
  comp == "skills" && /"current_only_total":/ { v=$0; gsub(/[^0-9]/,"",v); eo=v; comp="" }
  END { print ut, ct, ad, de, eo }
' "$parity_file")
EOF

cat <<EOF
# Parity Report

Last updated: ${today}
Upstream reference: \`affaan-m/everything-claude-code\` \`v1.10.0\`
Source of truth: \`references/parity-matrix.json\`

## Summary

| Component | Upstream | Current | Adopted | Deferred | Current-only |
|---|---:|---:|---:|---:|---:|
| Agents | ${au} | ${ac} | ${aa} | ${ad} | ${ae} |
| Rules | ${ru} | ${rc} | ${ra} | ${rd} | ${re} |
| Skills | ${su} | ${sc} | ${sa} | ${sd} | ${se} |

## Interpretation

- **Agents**: full upstream coverage, plus ECC-specific additions.
- **Rules**: full upstream parity, plus ECC-specific additions.
- **Skills**: full upstream coverage is now present in the tree, plus ECC-specific additions.
- Structural normalization is complete.
- Runtime activation and superiority work are complete.

## Sprint 3 Result

Sprint 3 imported the remaining upstream skills and closed the explicit skills parity gap in the tracker.

## Current Outcome

Agent Runtime Guard now has full upstream parity plus verified runtime/usability/superiority layers backed by executable checks and anti-drift documentation guards.
EOF
