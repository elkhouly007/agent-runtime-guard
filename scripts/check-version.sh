#!/usr/bin/env bash
# check-version.sh — Compare VERSION in an installed copy against the source repo.
#
# Usage:
#   ./scripts/check-version.sh                         # print current source version
#   ./scripts/check-version.sh <installed-dir>         # compare installed vs source
#
# Exit 0 = up to date (or no installed copy given).
# Exit 1 = installed version differs from source.

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
source_version_file="$root/VERSION"

[ -f "$source_version_file" ] || { printf 'ERROR: VERSION file not found at %s\n' "$source_version_file" >&2; exit 2; }

source_version="$(cat "$source_version_file" | tr -d '[:space:]')"

if [ -z "${1:-}" ]; then
  printf 'Agent Runtime Guard version: %s\n' "$source_version"
  exit 0
fi

installed_dir="$1"
installed_version_file="$installed_dir/VERSION"

if [ ! -f "$installed_version_file" ]; then
  printf 'WARNING: No VERSION file found in installed copy at: %s\n' "$installed_dir"
  printf '         Run install-local.sh to get a versioned copy.\n'
  exit 1
fi

installed_version="$(cat "$installed_version_file" | tr -d '[:space:]')"

if [ "$installed_version" = "$source_version" ]; then
  printf 'Installed: %s  |  Source: %s  →  up to date\n' "$installed_version" "$source_version"
  exit 0
else
  printf 'Installed: %s  |  Source: %s  →  UPDATE AVAILABLE\n' "$installed_version" "$source_version"
  printf 'Run: ./scripts/install-local.sh <target-dir> --profile <profile>\n'
  exit 1
fi
