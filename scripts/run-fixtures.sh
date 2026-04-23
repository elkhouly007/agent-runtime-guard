#!/usr/bin/env bash
# run-fixtures.sh — Fixture-based tests for Agent Runtime Guard scripts and hooks.
#
# Fixture layout:
#   tests/fixtures/classify/<name>.input          — text piped into classify-payload.sh
#   tests/fixtures/classify/<name>.expected       — lines that must appear in output
#
#   tests/fixtures/hooks/<name>.input             — JSON piped into secret-warning.js stdin
#   tests/fixtures/hooks/<name>.expected_exit     — expected exit code (default: 0)
#   tests/fixtures/hooks/<name>.expected_stderr   — substring that must appear in stderr
#
#   tests/fixtures/dangerous-command-gate/<name>.input          — JSON piped into hook
#   tests/fixtures/dangerous-command-gate/<name>.expected_exit  — expected exit code
#   tests/fixtures/dangerous-command-gate/<name>.expected_stderr — stderr substring
#   (files ending in -enforce.* are run with ECC_ENFORCE=1)
#
#   tests/fixtures/git-push-reminder/<name>.input          — JSON piped into hook
#   tests/fixtures/git-push-reminder/<name>.expected_exit  — expected exit code
#   tests/fixtures/git-push-reminder/<name>.expected_stderr — stderr substring
#   (files ending in -enforce.* are run with ECC_ENFORCE=1)
#
# Exit 0 = all pass. Exit 1 = one or more failures.

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

# Disable rate limiting during fixture tests so all invocations are processed.
export ECC_RATE_LIMIT=0

pass=0
fail=0

ok()     { printf '  PASS  %s\n' "$1"; pass=$((pass + 1)); }
fail()   { printf '  FAIL  %s — %s\n' "$1" "$2" >&2; fail=$((fail + 1)); }
skip()   { printf '  SKIP  %s — %s\n' "$1" "$2"; }

# ── helper: run a hook fixture ────────────────────────────────────────────────
# run_hook_fixture <hook_js> <fixture_dir> <enforce_override>
# enforce_override: "" = read from filename, "0" = force off, "1" = force on

run_hook_fixtures() {
  local hook="$1"
  local fixture_dir="$2"
  local label="$3"

  printf '\n%s\n' "[$label]"

  [ -d "$fixture_dir" ] || { skip "$label" "fixture directory missing: $fixture_dir"; return; }
  [ -f "$hook" ]        || { skip "$label" "hook missing: $hook"; return; }

  for input_file in "$fixture_dir"/*.input; do
    [ -f "$input_file" ] || continue
    name="$(basename "$input_file" .input)"
    expected_exit_file="${fixture_dir}/${name}.expected_exit"
    expected_stderr_file="${fixture_dir}/${name}.expected_stderr"

    # Fixtures containing "enforce" in their name run with ECC_ENFORCE=1
    enforce_val="0"
    case "$name" in *enforce*) enforce_val="1" ;; esac

    tmp_stderr="$(mktemp)"
    trap 'rm -f "$tmp_stderr"' EXIT

    actual_exit=0
    ECC_ENFORCE="$enforce_val" node "$hook" < "$input_file" > /dev/null 2> "$tmp_stderr" || actual_exit=$?

    fixture_ok=1

    if [ -f "$expected_exit_file" ]; then
      expected_exit="$(tr -d '[:space:]' < "$expected_exit_file")"
      if [ "$actual_exit" != "$expected_exit" ]; then
        fail "$name" "exit $actual_exit, expected $expected_exit"
        fixture_ok=0
      fi
    fi

    if [ -f "$expected_stderr_file" ]; then
      expected_substr="$(tr -d '\n' < "$expected_stderr_file")"
      if ! grep -qF "$expected_substr" "$tmp_stderr" 2>/dev/null; then
        fail "$name" "expected '$expected_substr' in stderr, got: $(cat "$tmp_stderr")"
        fixture_ok=0
      fi
    fi

    [ "$fixture_ok" -eq 1 ] && ok "$name"
  done
}

# ── classify-payload fixtures ─────────────────────────────────────────────────

printf '%s\n' "[classify-payload fixtures]"

for input_file in tests/fixtures/classify/*.input; do
  [ -f "$input_file" ] || continue
  name="$(basename "$input_file" .input)"
  expected_file="tests/fixtures/classify/${name}.expected"

  if [ ! -f "$expected_file" ]; then
    fail "$name" "missing .expected file"
    continue
  fi

  actual="$(./scripts/classify-payload.sh "$input_file" 2>/dev/null || true)"

  fixture_ok=1
  while IFS= read -r expected_line; do
    [ -n "$expected_line" ] || continue
    if ! printf '%s\n' "$actual" | grep -qF "$expected_line"; then
      fail "$name" "expected '$expected_line' not found in output"
      fixture_ok=0
    fi
  done < "$expected_file"

  [ "$fixture_ok" -eq 1 ] && ok "$name"
done

# ── secret-warning hook fixtures ──────────────────────────────────────────────

run_hook_fixtures \
  "claude/hooks/secret-warning.js" \
  "tests/fixtures/hooks" \
  "secret-warning hook fixtures"

# ── dangerous-command-gate hook fixtures ──────────────────────────────────────

run_hook_fixtures \
  "claude/hooks/dangerous-command-gate.js" \
  "tests/fixtures/dangerous-command-gate" \
  "dangerous-command-gate hook fixtures"

# ── git-push-reminder hook fixtures ───────────────────────────────────────────

run_hook_fixtures \
  "claude/hooks/git-push-reminder.js" \
  "tests/fixtures/git-push-reminder" \
  "git-push-reminder hook fixtures"

# ── redact-payload fixtures ───────────────────────────────────────────────────

printf '\n%s\n' "[redact-payload fixtures]"

for input_file in tests/fixtures/redact/*.input; do
  [ -f "$input_file" ] || continue
  name="$(basename "$input_file" .input)"
  expected_contains_file="tests/fixtures/redact/${name}.expected_contains"
  expected_absent_file="tests/fixtures/redact/${name}.expected_absent"

  actual="$(./scripts/redact-payload.sh "$input_file" 2>/dev/null || true)"
  fixture_ok=1

  if [ -f "$expected_contains_file" ]; then
    expected_substr="$(tr -d '\n' < "$expected_contains_file")"
    if ! printf '%s\n' "$actual" | grep -qF "$expected_substr"; then
      fail "$name" "expected '$expected_substr' in output"
      fixture_ok=0
    fi
  fi

  if [ -f "$expected_absent_file" ]; then
    absent_substr="$(tr -d '\n' < "$expected_absent_file")"
    if printf '%s\n' "$actual" | grep -qF "$absent_substr"; then
      fail "$name" "unexpected '$absent_substr' found in output (should be clean)"
      fixture_ok=0
    fi
  fi

  [ "$fixture_ok" -eq 1 ] && ok "$name"
done

# ── summary ───────────────────────────────────────────────────────────────────

printf '\n'
printf 'Results: %d passed, %d failed\n' "$pass" "$fail"

[ "$fail" -eq 0 ]
