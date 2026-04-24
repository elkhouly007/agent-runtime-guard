#!/usr/bin/env bash
# check-fixture-count.sh — Verify fixture count claims match actual fixture files on disk.
#
# Counts all *.input files under tests/fixtures/ and checks that the count matches
# claims in README.md, CHANGELOG.md (anywhere in the file), and
# references/full-power-status.md. Fails if any documented count drifts.
#
# Usage: bash scripts/check-fixture-count.sh

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }

printf '[check-fixture-count]\n'

# Count actual fixtures on disk
actual="$(find "$root/tests/fixtures" -name '*.input' | wc -l | tr -d ' ')"
[ "$actual" -gt 0 ] || fail "no fixture .input files found under tests/fixtures/"
pass "found ${actual} fixture files on disk"

# Check README.md — looks for "NNN fixture" or "NNN-fixture" patterns
readme="$root/README.md"
[ -f "$readme" ] || fail "README.md missing"
# Accept "54 fixture" or "54-fixture" forms
if ! grep -qE "${actual}[ -]fixture" "$readme"; then
  fail "README.md fixture count does not match actual (${actual}): check for stale count"
fi
pass "README.md fixture count matches (${actual})"

# Check references/full-power-status.md — "54/54 passing" pattern
fps="$root/references/full-power-status.md"
[ -f "$fps" ] || fail "references/full-power-status.md missing"
if ! grep -qF "${actual}/${actual}" "$fps"; then
  fail "full-power-status.md fixture count (${actual}/${actual}) not found: check for stale count"
fi
pass "full-power-status.md fixture count matches (${actual}/${actual})"

# Check CHANGELOG.md — the fixture count should be referenced somewhere in the file.
# When the count changes, all existing CHANGELOG references will fail to match the
# new number, ensuring the CHANGELOG is updated alongside README and full-power-status.
changelog="$root/CHANGELOG.md"
[ -f "$changelog" ] || fail "CHANGELOG.md missing"
if ! grep -qE "${actual}[ -]fixture|${actual}/${actual}" "$changelog"; then
  fail "CHANGELOG.md does not reference fixture count (${actual}): check for stale count"
fi
pass "CHANGELOG.md references fixture count (${actual})"

printf '\nFixture count checks passed.\n'
