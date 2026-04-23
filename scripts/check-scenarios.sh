#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }

printf '[check-scenarios]\n'

for file in \
  tests/approval-boundary-scenarios.md \
  tests/prompt-injection-scenarios.md
 do
  if [ ! -f "$file" ]; then
    fail "Missing scenario file: $file"
  fi
  pass "exists: $file"
 done

# Verify scenario counts match documented totals.
abs_count="$(grep -c '^## Scenario' tests/approval-boundary-scenarios.md || true)"
[ "$abs_count" -eq 20 ] || fail "approval-boundary-scenarios.md: expected 20 scenarios, found ${abs_count}"
pass "approval-boundary-scenarios.md: 20 scenarios"

pi_count="$(grep -c '^## Scenario' tests/prompt-injection-scenarios.md || true)"
[ "$pi_count" -eq 14 ] || fail "prompt-injection-scenarios.md: expected 14 scenarios, found ${pi_count}"
pass "prompt-injection-scenarios.md: 14 scenarios"

printf '\nScenario files present.\n'
