#!/usr/bin/env bash
# wire-hooks.sh — Generate a ready-to-paste hooks snippet for Claude Code settings.
#
# Usage:
#   ./scripts/wire-hooks.sh                  # auto-detect hooks dir from this script's location
#   ./scripts/wire-hooks.sh /abs/path/hooks  # explicit hooks directory
#   ./scripts/wire-hooks.sh --check          # check if settings.json still has /ABS_PATH/
#   ./scripts/wire-hooks.sh --verify         # verify each hook executes (no stdin)
#
# This script ONLY prints output. It never writes to settings.json or any other file.
# Copy the printed snippet manually into your ~/.claude/settings.json under "hooks".

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
hooks_template="$root/claude/hooks/hooks.json"

# ── helpers ──────────────────────────────────────────────────────────────────

die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
info() { printf 'INFO:  %s\n' "$*"; }
ok()   { printf '  ok   %s\n' "$*"; }
fail() { printf '  FAIL %s\n' "$*" >&2; }

# ── --check mode ─────────────────────────────────────────────────────────────

if [ "${1:-}" = "--check" ]; then
  # Look for /ABS_PATH/ in common settings locations. Non-destructive read only.
  found=0
  for candidate in \
    "$HOME/.claude/settings.json" \
    "$HOME/.claude/settings.local.json" \
    ".claude/settings.json" \
    ".claude/settings.local.json"
  do
    if [ -f "$candidate" ] && grep -q '/ABS_PATH/' "$candidate" 2>/dev/null; then
      printf 'WARNING: /ABS_PATH/ placeholder still present in: %s\n' "$candidate" >&2
      printf '         Run:  ./scripts/wire-hooks.sh  then update that file manually.\n' >&2
      found=1
    fi
  done
  if [ "$found" -eq 0 ]; then
    info "No /ABS_PATH/ placeholders found in known settings locations."
  fi
  exit "$found"
fi

# ── --verify mode ─────────────────────────────────────────────────────────────

if [ "${1:-}" = "--verify" ]; then
  hooks_dir="$root/claude/hooks"
  info "Verifying hooks in: $hooks_dir"
  all_ok=1
  for hook in \
    secret-warning.js \
    build-reminder.js \
    dangerous-command-gate.js \
    git-push-reminder.js \
    session-start.js \
    session-end.js \
    quality-gate.js \
    strategic-compact.js \
    pr-notifier.js \
    memory-load.js
  do
    hook_path="$hooks_dir/$hook"
    if [ ! -f "$hook_path" ]; then
      fail "$hook (file not found)"
      all_ok=0
      continue
    fi
    if node "$hook_path" < /dev/null > /dev/null 2>&1; then
      ok "$hook"
    else
      # Some hooks may exit non-zero on empty input — that's acceptable.
      # We only fail if the script itself crashes (syntax error, missing require).
      exit_code=$?
      if [ "$exit_code" -gt 1 ]; then
        fail "$hook (exit $exit_code — possible syntax or require error)"
        all_ok=0
      else
        ok "$hook (non-zero exit on empty input — normal)"
      fi
    fi
  done
  [ "$all_ok" -eq 1 ] && info "All hooks verified." || { printf 'One or more hooks failed verification.\n' >&2; exit 1; }
  exit 0
fi

# ── generate snippet ──────────────────────────────────────────────────────────

# Determine hooks directory
if [ -n "${1:-}" ]; then
  hooks_dir="$1"
else
  hooks_dir="$root/claude/hooks"
fi

# Validate
[ -d "$hooks_dir" ] || die "Hooks directory not found: $hooks_dir"
[ -f "$hooks_template" ] || die "hooks.json not found: $hooks_template"

# Verify the directory contains hooks
[ -f "$hooks_dir/secret-warning.js" ] || die "secret-warning.js not found in: $hooks_dir"

# Convert to absolute path (resolve symlinks)
hooks_dir="$(cd "$hooks_dir" && pwd)"

info "Hooks directory : $hooks_dir"
info "Template source : $hooks_template"
printf '\n'
printf '%s\n' "──────────────────────────────────────────────────────────────────────────────"
printf '%s\n' "Paste the following into ~/.claude/settings.json under the \"hooks\" key."
printf '%s\n' "IMPORTANT: This script does NOT write to settings.json. You must copy manually."
printf '%s\n' "──────────────────────────────────────────────────────────────────────────────"
printf '\n'

# Substitute /ABS_PATH/ with the real hooks directory path
sed "s|/ABS_PATH/|${hooks_dir}/|g" "$hooks_template"

printf '\n'
printf '%s\n' "──────────────────────────────────────────────────────────────────────────────"
printf '%s\n' "After pasting, run:  ./scripts/wire-hooks.sh --verify"
printf '%s\n' "To check for stale placeholders: ./scripts/wire-hooks.sh --check"
printf '%s\n' "──────────────────────────────────────────────────────────────────────────────"
