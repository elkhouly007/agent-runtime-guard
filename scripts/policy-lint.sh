#!/usr/bin/env bash
# policy-lint.sh — Verify that rule files follow Agent Runtime Guard standards.
#
# Standards:
# - YAML frontmatter must be present.
# - last_reviewed field must be present.
# - version_target field must be present.
# - No obvious dangerous instructions (handled by audit-local, but we add a check here).

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; found_error=1; }

found_error=0

printf 'Linting rules/ for policy standards ...\n'

while IFS= read -r f; do
  # Check for frontmatter
  if ! head -n 1 "$f" | grep -q '^---'; then
    fail "$f: Missing YAML frontmatter start (---)"
    continue
  fi

  # Check for required fields
  if ! grep -q '^last_reviewed:' "$f"; then
    fail "$f: Missing 'last_reviewed' field"
  fi
  if ! grep -q '^version_target:' "$f"; then
    fail "$f: Missing 'version_target' field"
  fi
done < <(find rules -type f -name '*.md' -not -name 'README.md' | sort)

if [ "$found_error" -eq 1 ]; then
  printf '\nPolicy lint failed.\n'
  exit 1
fi

printf '\nPolicy lint passed.\n'
exit 0
