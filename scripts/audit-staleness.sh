#!/usr/bin/env bash
# audit-staleness.sh — Flag rule files whose 'last_reviewed' frontmatter is older than N days.
#
# Rule files should have YAML frontmatter with a last_reviewed field:
#   ---
#   last_reviewed: 2026-04-19
#   version_target: "Python 3.12"
#   ---
#
# Usage:
#   ./scripts/audit-staleness.sh              # flag files older than 180 days (default)
#   ./scripts/audit-staleness.sh --days 90    # custom threshold
#   ./scripts/audit-staleness.sh --missing    # also flag files with no last_reviewed
#
# Exit 0 = all files fresh. Exit 1 = stale or missing files found.

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

threshold_days=180
show_missing=0

while [ $# -gt 0 ]; do
  case "$1" in
    --days)    shift; threshold_days="${1:-180}" ;;
    --days=*)  threshold_days="${1#--days=}" ;;
    --missing) show_missing=1 ;;
    -h|--help)
      printf 'Usage: %s [--days N] [--missing]\n' "$0"
      exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# Compute threshold date in seconds since epoch
today_epoch="$(date +%s)"
threshold_epoch=$((today_epoch - threshold_days * 86400))

tmp_counts="$(mktemp)"
trap 'rm -f "$tmp_counts"' EXIT
printf '0 0\n' > "$tmp_counts"   # stale missing

printf 'Checking rules/ for staleness (threshold: %d days) ...\n' "$threshold_days"

# Use a temp file for counts to avoid subshell variable loss from pipe
while IFS= read -r f; do
  reviewed="$(awk '
    /^---/ { if (++fence == 2) exit }
    fence == 1 && /^last_reviewed:/ {
      gsub(/^last_reviewed:[[:space:]]*/, "")
      gsub(/[[:space:]]/, "")
      print; exit
    }
  ' "$f")"

  if [ -z "$reviewed" ]; then
    if [ "$show_missing" -eq 1 ]; then
      printf '  NO DATE  %s\n' "$f"
      read -r s m < "$tmp_counts"
      printf '%d %d\n' "$s" "$((m + 1))" > "$tmp_counts"
    fi
    continue
  fi

  if date --version >/dev/null 2>&1; then
    file_epoch="$(date -d "$reviewed" +%s 2>/dev/null || echo 0)"
  else
    file_epoch="$(date -j -f '%Y-%m-%d' "$reviewed" +%s 2>/dev/null || echo 0)"
  fi

  if [ "$file_epoch" -eq 0 ]; then
    printf '  BAD DATE %s  (%s)\n' "$f" "$reviewed"
    read -r s m < "$tmp_counts"; printf '%d %d\n' "$((s + 1))" "$m" > "$tmp_counts"
  elif [ "$file_epoch" -lt "$threshold_epoch" ]; then
    age_days=$(( (today_epoch - file_epoch) / 86400 ))
    printf '  STALE    %s  (reviewed: %s, %d days ago)\n' "$f" "$reviewed" "$age_days"
    read -r s m < "$tmp_counts"; printf '%d %d\n' "$((s + 1))" "$m" > "$tmp_counts"
  else
    age_days=$(( (today_epoch - file_epoch) / 86400 ))
    printf '  ok       %s  (%d days ago)\n' "$f" "$age_days"
  fi
done < <(find rules -type f -name '*.md' -not -name 'README.md' | sort)

read -r stale missing < "$tmp_counts"

printf '\n'
if [ "$stale" -gt 0 ] || [ "$missing" -gt 0 ]; then
  printf 'Staleness: %d stale, %d missing last_reviewed.\n' "$stale" "$missing"
  printf 'Add frontmatter to rule files:\n'
  printf '  ---\n'
  printf '  last_reviewed: %s\n' "$(date +%Y-%m-%d)"
  printf '  version_target: "Language X.Y"\n'
  printf '  upstream_ref: "source-README.md"\n'
  printf '  ---\n'
  exit 1
else
  printf 'All reviewed rule files are fresh (within %d days).\n' "$threshold_days"
fi
