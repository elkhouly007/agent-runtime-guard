#!/usr/bin/env bash
# classify-changes.sh — Categorize changes in a diff into Agent Runtime Guard classes.
#
# Usage:
#   diff -uNr upstream local | ./scripts/classify-changes.sh
#
# Classes:
# - Class A: Documentation/Prompts (Low risk)
# - Class B: Logic/Hooks/Scripts (Medium risk, review needed)
# - Class C: External/Sensitive (High risk, approval needed)

set -eu

printf 'Change Classification Report\n'
printf '============================\n\n'

tmp_diff="$(mktemp)"
trap 'rm -f "$tmp_diff"' EXIT
cat > "$tmp_diff"

# Analysis
class_a_count="$(grep -cE '^\+\+\+ .*\.(md|txt|prompts/)' "$tmp_diff" || true)"
class_b_count="$(grep -cE '^\+\+\+ .*\.(sh|js|jsonc|json)' "$tmp_diff" || true)"
class_c_count="$(grep -cE '^\+\+\+ .*(security|policy|auth|key|secret)' "$tmp_diff" || true)"

printf 'Class A (Docs/Prompts): %d files\n' "$class_a_count"
printf 'Class B (Scripts/Logic): %d files\n' "$class_b_count"
printf 'Class C (Security/Sensitive): %d files\n' "$class_c_count"

printf '\nRecommendation:\n'
if [ "$class_c_count" -gt 0 ]; then
  printf '  HIGH RISK: Manual review of security-sensitive changes is MANDATORY.\n'
elif [ "$class_b_count" -gt 0 ]; then
  printf '  MEDIUM RISK: Review script logic for unexpected side effects.\n'
else
  printf '  LOW RISK: Changes are primarily informational.\n'
fi
