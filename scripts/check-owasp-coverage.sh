#!/usr/bin/env bash
# check-owasp-coverage.sh — Verify the OWASP Agentic Top 10 coverage matrix.
#
# Rules:
#   1. references/owasp-agentic-coverage.md must exist.
#   2. Every ASI01–ASI10 row must be present.
#   3. Every ASI row must either name a specific file (e.g. runtime/decision-engine.js)
#      or explicitly state NOT COVERED or PARTIAL or DEFERRED — never a vague prose claim.
#   4. Every file referenced in the table must exist in the repo.
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }

printf '[check-owasp-coverage]\n'

doc="$root/references/owasp-agentic-coverage.md"
[ -f "$doc" ] || fail "references/owasp-agentic-coverage.md missing"
pass "owasp-agentic-coverage.md exists"

# 1. All 10 ASI rows present
for tag in ASI01 ASI02 ASI03 ASI04 ASI05 ASI06 ASI07 ASI08 ASI09 ASI10; do
  grep -qF "$tag" "$doc" || fail "missing ASI row: $tag"
done
pass "all ASI01-ASI10 rows present"

# 2. Every ASI row names a file or explicitly says NOT COVERED / PARTIAL / DEFERRED / COVERED
while IFS= read -r line; do
  # Only check table rows that start with | ASI
  if printf '%s' "$line" | grep -qE '^\| ASI[0-9]+'; then
    if ! printf '%s' "$line" | grep -qE '(COVERED|PARTIAL|NOT COVERED|DEFERRED)'; then
      fail "ASI row missing coverage verdict (COVERED/PARTIAL/NOT COVERED/DEFERRED): $line"
    fi
  fi
done < "$doc"
pass "all ASI rows have coverage verdict"

# 3. Every path-qualified file reference (dir/file.ext) in the table must exist
referenced_files="$(grep -oE '[a-z][a-zA-Z0-9_-]+/[a-zA-Z0-9/_-]+\.(js|sh|json|md)' "$doc" | sort -u)"
missing=0
while IFS= read -r fpath; do
  [ -z "$fpath" ] && continue
  if [ ! -f "$root/$fpath" ]; then
    printf '  ERROR   referenced file not found: %s\n' "$fpath" >&2
    missing=$((missing + 1))
  fi
done <<< "$referenced_files"
[ "$missing" -eq 0 ] || fail "one or more referenced files not found (see above)"
pass "all referenced files exist"

printf '\nOWASP coverage checks passed.\n'
