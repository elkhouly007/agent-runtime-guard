#!/usr/bin/env bash
# upstream-diff.sh — Compare the local tree against an upstream source path.
#
# Usage:
#   ./scripts/upstream-diff.sh <upstream-dir>
#   ./scripts/upstream-diff.sh <upstream-dir> agents/
#
# Requires 'diff' to be available.

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
upstream_dir="${1:-}"
subpath="${2:-.}"

[ -n "$upstream_dir" ] || { printf 'Usage: %s <upstream-dir> [subpath]\n' "$0" >&2; exit 2; }
[ -d "$upstream_dir" ] || { printf 'Upstream directory not found: %s\n' "$upstream_dir" >&2; exit 2; }

printf 'Comparing local %s against upstream %s ...\n\n' "$subpath" "$upstream_dir/$subpath"

diff -uNr "$upstream_dir/$subpath" "$root/$subpath" || {
  printf '\nDifferences found.\n'
  exit 1
}

printf '\nNo differences found (perfect parity).\n'
