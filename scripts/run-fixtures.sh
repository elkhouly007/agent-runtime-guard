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

# Hermetic test mode: prevent live git branch detection from contaminating fixture
# results. When ECC_HERMETIC_TEST=1, all fixture runs that don't supply a "branch"
# field in their input JSON will fall back to this non-protected override branch,
# ensuring results are identical regardless of the current working branch.
#
# This does NOT affect fixtures that explicitly set "branch" in their input JSON;
# those already override git detection via rawInput.branch in pretool-gate.js.
if [ "${ECC_HERMETIC_TEST:-0}" = "1" ]; then
  export ECC_BRANCH_OVERRIDE="feature/hermetic-test-run"
fi

pass=0
fail=0

hooks_tmp_state="$(mktemp -d)"
cleanup_hooks_state() { rm -rf "$hooks_tmp_state"; }
trap cleanup_hooks_state EXIT
export ECC_STATE_DIR="$hooks_tmp_state"

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
    fix_state="$(mktemp -d)"
    ECC_ENFORCE="$enforce_val" ECC_STATE_DIR="$fix_state" node "$hook" < "$input_file" > /dev/null 2> "$tmp_stderr" || actual_exit=$?
    rm -rf "$fix_state"

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

# ── opencode adapter fixtures ─────────────────────────────────────────────────

run_hook_fixtures \
  "opencode/hooks/adapter.js" \
  "tests/fixtures/opencode" \
  "opencode adapter fixtures"

# ── openclaw adapter fixtures ─────────────────────────────────────────────────

run_hook_fixtures \
  "openclaw/hooks/adapter.js" \
  "tests/fixtures/openclaw" \
  "openclaw adapter fixtures"

# ── kill-switch fixtures ───────────────────────────────────────────────────────
# Each hook is tested with ECC_KILL_SWITCH=1 ECC_ENFORCE=1.
# PreToolUse hooks must exit 2 (block). Informational hooks must exit 0 (no-op).

printf '\n%s\n' "[kill-switch fixtures]"

run_ks() {
  local hook="$1" input_file="$2" expected_exit="$3" label="$4"
  [ -f "$input_file" ] || { skip "$label" "fixture missing: $input_file"; return; }
  [ -f "$hook" ]       || { skip "$label" "hook missing: $hook"; return; }
  local tmp_stderr; tmp_stderr="$(mktemp)"
  local actual_exit=0
  ECC_KILL_SWITCH=1 ECC_ENFORCE=1 node "$hook" < "$input_file" > /dev/null 2>"$tmp_stderr" \
    || actual_exit=$?
  rm -f "$tmp_stderr"
  if [ "$actual_exit" -eq "$expected_exit" ]; then
    ok "$label"
  else
    fail "$label" "exit $actual_exit, expected $expected_exit"
  fi
}

ks_dir="tests/fixtures/kill-switch"
run_ks "claude/hooks/dangerous-command-gate.js" "$ks_dir/ks-dangerous-command-gate.input" 2 "kill-switch: dangerous-command-gate (exit 2)"
run_ks "claude/hooks/secret-warning.js"         "$ks_dir/ks-secret-warning.input"         2 "kill-switch: secret-warning (exit 2)"
run_ks "claude/hooks/git-push-reminder.js"      "$ks_dir/ks-git-push-reminder.input"      2 "kill-switch: git-push-reminder (exit 2)"
run_ks "claude/hooks/build-reminder.js"         "$ks_dir/ks-build-reminder.input"         2 "kill-switch: build-reminder (exit 2)"
run_ks "openclaw/hooks/adapter.js"              "$ks_dir/ks-openclaw-adapter.input"        2 "kill-switch: openclaw-adapter (exit 2)"
run_ks "opencode/hooks/adapter.js"              "$ks_dir/ks-opencode-adapter.input"        2 "kill-switch: opencode-adapter (exit 2)"
run_ks "claude/hooks/session-start.js"          "$ks_dir/ks-session-start.input"           0 "kill-switch: session-start (exit 0, no-op)"
run_ks "claude/hooks/session-end.js"            "$ks_dir/ks-session-end.input"             0 "kill-switch: session-end (exit 0, no-op)"
run_ks "claude/hooks/memory-load.js"            "$ks_dir/ks-memory-load.input"             0 "kill-switch: memory-load (exit 0, no-op)"
run_ks "claude/hooks/strategic-compact.js"      "$ks_dir/ks-strategic-compact.input"       0 "kill-switch: strategic-compact (exit 0, no-op)"
run_ks "claude/hooks/pr-notifier.js"            "$ks_dir/ks-pr-notifier.input"             0 "kill-switch: pr-notifier (exit 0, no-op)"
run_ks "claude/hooks/quality-gate.js"           "$ks_dir/ks-quality-gate.input"            0 "kill-switch: quality-gate (exit 0, no-op)"
run_ks "claude/hooks/output-sanitizer.js"       "$ks_dir/ks-output-sanitizer.input"        0 "kill-switch: output-sanitizer (exit 0, no-op)"

# ── contract fixtures ──────────────────────────────────────────────────────────
# Fixture names containing "strict" → run with ECC_CONTRACT_REQUIRED=1 (no contract file = block gated)
# All others → ECC_CONTRACT_REQUIRED=0 (risk-engine-only path).
# State dir is isolated per run so no real contract interferes.

printf '\n%s\n' "[contract fixtures]"

contract_dir="tests/fixtures/contract"
[ -d "$contract_dir" ] || { skip "contract fixtures" "directory missing: $contract_dir"; }

if [ -d "$contract_dir" ]; then
  for input_file in "$contract_dir"/*.input; do
    [ -f "$input_file" ] || continue
    name="$(basename "$input_file" .input)"
    expected_exit_file="${contract_dir}/${name}.expected_exit"
    expected_stderr_file="${contract_dir}/${name}.expected_stderr"

    contract_required="0"
    cc_enforce="0"
    case "$name" in *strict*)   contract_required="1"; cc_enforce="1" ;; esac
    case "$name" in *critical*) cc_enforce="1" ;; esac

    tmp_state="$(mktemp -d)"
    tmp_stderr="$(mktemp)"
    actual_exit=0
    ECC_STATE_DIR="$tmp_state" ECC_CONTRACT_REQUIRED="$contract_required" \
      ECC_CONTRACT_ENABLED="1" ECC_ENFORCE="$cc_enforce" ECC_RATE_LIMIT=0 \
      node "claude/hooks/dangerous-command-gate.js" < "$input_file" > /dev/null 2>"$tmp_stderr" \
      || actual_exit=$?
    rm -rf "$tmp_state"

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
      if ! grep -qF "$expected_substr" "$tmp_stderr"; then
        fail "$name" "expected '$expected_substr' in stderr"
        fixture_ok=0
      fi
    fi

    rm -f "$tmp_stderr"
    [ "$fixture_ok" -eq 1 ] && ok "$name"
  done
fi

# ── summary ───────────────────────────────────────────────────────────────────

printf '\n'
printf 'Results: %d passed, %d failed\n' "$pass" "$fail"

[ "$fail" -eq 0 ]
