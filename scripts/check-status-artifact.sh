#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
workdir="$(mktemp -d)"
cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }

printf '[check-status-artifact]\n'

artifact_dir="$workdir/artifact"
bash "$root/scripts/generate-status-artifact.sh" "$artifact_dir" >/dev/null

summary_file="$artifact_dir/status-summary.txt"
meta_file="$artifact_dir/status-summary.meta"

[ -f "$summary_file" ] || fail 'status artifact summary generated'
[ -f "$meta_file" ] || fail 'status artifact metadata generated'
grep -Fq 'Agent Runtime Guard Status Summary' "$summary_file" || fail 'status artifact contains summary heading'
grep -Fq '[Verification]' "$summary_file" || fail 'status artifact contains verification block'
grep -Fq '[Parity Snapshot]' "$summary_file" || fail 'status artifact contains parity snapshot'
grep -Fq 'artifact=status-summary' "$meta_file" || fail 'status artifact metadata type'
grep -Fq 'source=scripts/status-summary.sh' "$meta_file" || fail 'status artifact metadata source'
pass 'status artifact generation works'

# Validate version field matches VERSION file
expected_version="$(tr -d '[:space:]' < "$root/VERSION" 2>/dev/null || echo unknown)"
grep -Fq "version=${expected_version}" "$meta_file" || fail "status artifact metadata version does not match VERSION file (expected ${expected_version})"
pass "status artifact version field matches VERSION (${expected_version})"

# Validate generated_at is present and ISO-8601 shaped (YYYY-MM-DDTHH:MM:SSZ)
generated_at_line="$(grep '^generated_at=' "$meta_file" || true)"
[ -n "$generated_at_line" ] || fail 'status artifact metadata missing generated_at field'
generated_at_val="${generated_at_line#generated_at=}"
printf '%s' "$generated_at_val" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$' || \
  fail "status artifact generated_at not ISO-8601 (got: ${generated_at_val})"
pass 'status artifact generated_at is ISO-8601'

# Validate path field exists on disk (the generated artifact path)
path_line="$(grep '^path=' "$meta_file" || true)"
[ -n "$path_line" ] || fail 'status artifact metadata missing path field'
path_val="${path_line#path=}"
[ -f "$path_val" ] || fail "status artifact path does not exist: ${path_val}"
pass 'status artifact path field resolves to a real file'

# Validate count fields are present and numeric
for field in agents rules skills scripts fixtures checks; do
  field_line="$(grep "^${field}=" "$meta_file" || true)"
  [ -n "$field_line" ] || fail "status artifact metadata missing ${field}= count field"
  field_val="${field_line#*=}"
  printf '%s' "$field_val" | grep -qE '^[0-9]+$' || fail "status artifact ${field}= is not numeric (got: ${field_val})"
  [ "$field_val" -gt 0 ] || fail "status artifact ${field}= count is zero (unexpected)"
done
pass 'status artifact count fields present and numeric'

# Cross-check fixture count in metadata against actual disk count
meta_fixtures_line="$(grep '^fixtures=' "$meta_file" || true)"
meta_fixtures="${meta_fixtures_line#fixtures=}"
actual_fixtures="$(find "$root/tests/fixtures" -name '*.input' | wc -l | tr -d ' ')"
[ "$meta_fixtures" = "$actual_fixtures" ] || \
  fail "status artifact fixtures count (${meta_fixtures}) does not match disk count (${actual_fixtures})"
pass "status artifact fixtures count matches disk (${actual_fixtures})"

printf '\nStatus artifact checks passed.\n'
