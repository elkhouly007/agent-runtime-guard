#!/usr/bin/env bash
# check-skills.sh — Validate structure of all skill files in skills/*.md
#
# For each skill file, checks:
#   ERROR   — missing H1 "# Skill:" heading
#   ERROR   — missing trigger/purpose section (## Trigger, ## Purpose, ## Use When)
#   WARNING — fewer than 30 lines (suspiciously thin)
#   WARNING — no process/steps section (## Process, ## Steps, ## How, ## Workflow, ## Approach)
#   INFO    — file does not end with a newline
#
# Exit codes:
#   0 — all checks pass (errors + warnings = 0)
#   1 — one or more errors or warnings found
#
# Options:
#   --errors-only    only report ERRORs (skip warnings and info)
#   --fix-headings   add missing "# Skill: <name>" heading (writes file — use with care)
#   -h|--help

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
skills_dir="${root}/skills"
errors_only=0
fix_headings=0

while [ $# -gt 0 ]; do
  case "$1" in
    --errors-only)   errors_only=1 ;;
    --fix-headings)  fix_headings=1 ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# //'
      exit 0
      ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

[ -d "$skills_dir" ] || { printf 'skills/ directory not found: %s\n' "$skills_dir" >&2; exit 2; }

# ── counters ──────────────────────────────────────────────────────────────────

total=0
errors=0
warnings=0
infos=0

err()  { printf '  ERROR   %s — %s\n' "$1" "$2"; errors=$((errors + 1)); }
warn() {
  [ "$errors_only" -eq 0 ] || return 0
  printf '  WARN    %s — %s\n' "$1" "$2"; warnings=$((warnings + 1))
}
info() {
  [ "$errors_only" -eq 0 ] || return 0
  printf '  info    %s — %s\n' "$1" "$2"; infos=$((infos + 1))
}
ok()   { printf '  ok      %s\n' "$1"; }

# ── per-file checks ───────────────────────────────────────────────────────────

printf '[check-skills]\n'
printf 'Scanning %s\n\n' "$skills_dir"

for f in "$skills_dir"/*.md; do
  [ -f "$f" ] || continue
  name="$(basename "$f" .md)"

  # Skip the index README
  [ "$name" = "README" ] && continue

  total=$((total + 1))
  file_ok=1

  # H1 heading check
  first_line="$(head -1 "$f" 2>/dev/null || true)"
  if ! printf '%s\n' "$first_line" | grep -qiE '^# '; then
    err "$name" "missing H1 heading (first line: '${first_line}')"
    file_ok=0
    if [ "$fix_headings" -eq 1 ]; then
      # Prepend "# Skill: <name>" to the file
      tmp="$(mktemp)"
      printf '# Skill: %s\n\n' "$name" > "$tmp"
      cat "$f" >> "$tmp"
      mv "$tmp" "$f"
      printf '  FIXED   %s — added H1 heading\n' "$name"
    fi
  fi

  # Trigger/Purpose section check
  if ! grep -qiE '^## (Trigger|Purpose|Use When|When to Use|Overview)' "$f" 2>/dev/null; then
    err "$name" "missing ## Trigger / ## Purpose section"
    file_ok=0
  fi

  # Line count check (warn if thin)
  line_count="$(wc -l < "$f")"
  if [ "$line_count" -lt 30 ]; then
    warn "$name" "only ${line_count} lines — consider expanding"
    file_ok=0
  fi

  # Process/Steps section check (warn if absent)
  if ! grep -qiE '^## (Process|Steps|How|Workflow|Approach|Usage|Instructions|What .* Does|Output)' "$f" 2>/dev/null; then
    warn "$name" "no ## Process / ## Steps section found"
    file_ok=0
  fi

  # Trailing newline check
  last_char="$(tail -c 1 "$f" | od -An -tx1 | tr -d ' \n')"
  if [ "$last_char" != "0a" ]; then
    info "$name" "does not end with a newline"
  fi

  [ "$file_ok" -eq 1 ] && ok "$name"
done

# ── summary ───────────────────────────────────────────────────────────────────

printf '\n'
printf 'Scanned: %d skills\n' "$total"
printf 'Errors:  %d\n' "$errors"
[ "$errors_only" -eq 0 ] && printf 'Warnings: %d\n' "$warnings"
[ "$errors_only" -eq 0 ] && printf 'Info:     %d\n' "$infos"

if [ "$errors" -gt 0 ]; then
  printf '\n%d ERROR(s) found — fix before shipping.\n' "$errors" >&2
  exit 1
fi

if [ "$errors_only" -eq 0 ] && [ "$warnings" -gt 0 ]; then
  printf '\n%d WARNING(s) — no blocking issues but review recommended.\n' "$warnings"
  exit 1
fi

printf '\nAll skills passed.\n'
exit 0
