#!/usr/bin/env bash
# scripts/horus-rebrand.sh — one-time rename: ECC_* → HORUS_*, ecc.* → horus.*.
# NOTE: This script self-modified during the rebrand run (ECC_ → HORUS_ in comments).
# The rebrand has been applied. This file is retained as historical documentation.
#
# Usage:
#   bash scripts/horus-rebrand.sh           # preview (dry run, default)
#   bash scripts/horus-rebrand.sh --apply   # apply changes
#   bash scripts/horus-rebrand.sh --verify  # check remaining old-brand refs
#
# What this script applied:
#   1. Content: ECC_ env-var prefix → HORUS_ in all tracked source files
#   2. Content: ecc.{config,contract}.json → horus.{config,contract}.json refs
#   3. Content: ecc.*.schema.json → horus.*.schema.json refs
#   4. Content: ecc-cli.sh / ecc-cli → horus-cli.sh / horus-cli refs
#   5. Content: .openclaw/agent-runtime-guard → .horus  (primary state dir)
#   6. Content: .openclaw/ecc-safe-plus → .horus  (legacy hook state dir)
#   7. Content: contractId prefix arg- → hap- in contract.js and schema
#   8. File renames: schemas/ecc.*.json → schemas/horus.*.json
#   9. File renames: scripts/ecc-cli.sh → scripts/horus-cli.sh
#  10. File renames: scripts/ecc-diff-decisions.sh → scripts/horus-diff-decisions.sh
#  11. File renames: ecc.*.example → horus.*.example
#  12. Code: state-paths.js default paths → ~/.horus

set -euo pipefail

# ── Config ─────────────────────────────────────────────────────────────────────

DRY_RUN=1

for arg in "$@"; do
  case "$arg" in
    --apply)  DRY_RUN=0 ;;
    --verify) DRY_RUN=1 ;;
    --dry-run) DRY_RUN=1 ;;
    *) printf 'Unknown option: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$0")")"
cd "$ROOT"

changed=0
skipped=0

# ── Helpers ────────────────────────────────────────────────────────────────────

info()    { printf '  %s\n' "$*"; }
changed() { changed=$((changed + 1)); printf '  CHANGE  %s\n' "$*"; }
rename_f() { changed=$((changed + 1)); printf '  RENAME  %s → %s\n' "$1" "$2"; }
skip()    { skipped=$((skipped + 1)); printf '  SKIP    %s\n' "$*"; }

# Apply a sed substitution to a file (dry-run aware, cross-platform).
# sed_replace FILE PATTERN REPLACEMENT
sed_replace() {
  local file="$1" pat="$2" rep="$3"
  if grep -qF -- "$pat" "$file" 2>/dev/null || grep -qP -- "$pat" "$file" 2>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
      changed "would replace '$pat' in $file"
    else
      # GNU sed (Linux + git-bash on Windows): sed -i works directly
      sed -i "s|${pat}|${rep}|g" "$file"
      changed "replaced '$pat' in $file"
    fi
  fi
}

# Portable bulk sed across all matching files (uses grep -rl).
# bulk_replace GREP_PATTERN SED_PATTERN SED_REPLACEMENT [extra_find_args]
bulk_replace() {
  local grep_pat="$1" sed_pat="$2" sed_rep="$3"
  local files
  files=$(grep -rl --include="*.js" --include="*.sh" --include="*.json" \
    --include="*.md" --include="*.jsonc" --include="*.yaml" --include="*.yml" \
    --include="*.txt" --include="*.example" \
    --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir=".claude" \
    --exclude-dir="artifacts" \
    -- "$grep_pat" . 2>/dev/null || true)
  if [ -z "$files" ]; then return; fi
  for f in $files; do
    f="${f#./}"
    if [ "$DRY_RUN" -eq 1 ]; then
      changed "would replace '$grep_pat' in $f"
    else
      sed -i "s|${sed_pat}|${sed_rep}|g" "$f"
      changed "replaced '$grep_pat' in $f"
    fi
  done
}

# Rename a file if source exists and destination does not.
rename_file() {
  local src="$1" dst="$2"
  if [ ! -f "$src" ]; then return; fi
  if [ -f "$dst" ]; then
    skip "rename $src → $dst (destination already exists)"
    return
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    rename_f "$src" "$dst"
  else
    git mv "$src" "$dst" 2>/dev/null || mv "$src" "$dst"
    rename_f "$src" "$dst"
  fi
}

# ── Phase 0: Verify mode ────────────────────────────────────────────────────────

if [[ "${1:-}" == "--verify" ]]; then
  printf '\n=== Verification: remaining HORUS_ references ===\n'
  count=$(grep -r "HORUS_" --include="*.js" --include="*.sh" --include="*.json" \
    --include="*.md" --include="*.jsonc" \
    --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir=".claude" \
    . 2>/dev/null | wc -l || echo 0)
  printf 'HORUS_ occurrences remaining: %s\n' "$count"
  ecc_files=$(grep -rl "HORUS_" --include="*.js" --include="*.sh" --include="*.json" \
    --include="*.md" --include="*.jsonc" \
    --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir=".claude" \
    . 2>/dev/null | wc -l || echo 0)
  printf 'Files with HORUS_ remaining: %s\n' "$ecc_files"
  [ "$count" -eq 0 ] && printf 'Rebrand complete.\n' || printf 'Rebrand incomplete — run with --apply.\n'
  exit 0
fi

# ── Phase 1: Bulk env-var prefix replacement (HORUS_ → HORUS_) ──────────────────

printf '\n=== Phase 1: env-var prefix HORUS_ → HORUS_ ===\n'

if [ "$DRY_RUN" -eq 1 ]; then
  ecc_files=$(grep -rl "HORUS_" --include="*.js" --include="*.sh" --include="*.json" \
    --include="*.md" --include="*.jsonc" --include="*.yaml" --include="*.yml" \
    --include="*.txt" --include="*.example" \
    --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir=".claude" \
    --exclude-dir="artifacts" \
    . 2>/dev/null || true)
  for f in $ecc_files; do
    changed "would replace HORUS_ → HORUS_ in ${f#./}"
  done
else
  # Apply HORUS_ → HORUS_ across all tracked source files.
  grep -rl "HORUS_" --include="*.js" --include="*.sh" --include="*.json" \
    --include="*.md" --include="*.jsonc" --include="*.yaml" --include="*.yml" \
    --include="*.txt" --include="*.example" \
    --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir=".claude" \
    --exclude-dir="artifacts" \
    . 2>/dev/null | while IFS= read -r f; do
    sed -i 's/HORUS_/HORUS_/g' "$f"
    changed "HORUS_ → HORUS_ in ${f#./}"
  done
fi

# ── Phase 2: Config file name references ───────────────────────────────────────

printf '\n=== Phase 2: file name references ===\n'

# horus.contract.json.draft/.example before horus.contract.json to avoid partial match
bulk_replace "ecc\.contract\.json\.draft" 'ecc\.contract\.json\.draft' 'horus.contract.json.draft'
bulk_replace "ecc\.contract\.json\.example" 'ecc\.contract\.json\.example' 'horus.contract.json.example'
bulk_replace "ecc\.contract\.json" 'ecc\.contract\.json' 'horus.contract.json'
bulk_replace "ecc\.config\.json" 'ecc\.config\.json' 'horus.config.json'
bulk_replace "ecc\.contract\.schema\.json" 'ecc\.contract\.schema\.json' 'horus.contract.schema.json'
bulk_replace "ecc\.config\.schema\.json" 'ecc\.config\.schema\.json' 'horus.config.schema.json'

# CLI script references (longest match first)
bulk_replace "horus-cli\.sh" 'horus-cli\.sh' 'horus-cli.sh'
bulk_replace "horus-cli" 'horus-cli' 'horus-cli'

# horus-diff-decisions references
bulk_replace "horus-diff-decisions" 'horus-diff-decisions' 'horus-diff-decisions'

# ── Phase 3: State directory paths ─────────────────────────────────────────────

printf '\n=== Phase 3: state directory paths ===\n'

# Longest/most specific patterns first to avoid double-replacement.
bulk_replace '\.horus' '\.horus' '.horus'
bulk_replace '\.horus' '\.horus' '.horus'
bulk_replace '\.horus/instincts' '\.horus/instincts' '.horus/instincts'

# ── Phase 4: contractId prefix arg- → hap- ─────────────────────────────────────

printf '\n=== Phase 4: contractId prefix arg- → hap- ===\n'

# Only in specific files where arg- means a contractId prefix, not a CLI argument.
# contract.js: the newContractId() function
# horus.contract.schema.json (already renamed to horus.contract.schema.json after phase 2/8)
# horus.contract.json.example (already renamed)

for f in runtime/contract.js schemas/horus.contract.schema.json horus.contract.json.example; do
  [ -f "$f" ] || continue
  if grep -qF 'arg-' "$f" 2>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
      changed "would replace arg- prefix in $f"
    else
      # Only replace: return `arg-`, "arg-", ^arg- (not things like require("./arg-extractor"))
      sed -i \
        -e 's/return `arg-\${/return `hap-${/g' \
        -e 's/\^arg-/^hap-/g' \
        -e 's/"arg-20/"hap-20/g' \
        "$f"
      changed "replaced arg- prefix in $f"
    fi
  fi
done

# Also update the fixture test contract that uses arg- prefix
for f in tests/fixtures/contract/*.input; do
  [ -f "$f" ] || continue
  if grep -qF '"arg-' "$f" 2>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
      changed "would replace arg- contractId in $f"
    else
      sed -i 's/"arg-/"hap-/g' "$f"
      changed "replaced arg- contractId in $f"
    fi
  fi
done

# ── Phase 5: state-paths.js default path literals ──────────────────────────────

printf '\n=== Phase 5: state-paths.js default path literals ===\n'

# These multi-part path.join() calls need targeted replacement.
if [ -f "runtime/state-paths.js" ]; then
  if grep -qF '".openclaw", "agent-runtime-guard"' runtime/state-paths.js 2>/dev/null || \
     grep -qF '".openclaw", "ecc-safe-plus"' runtime/state-paths.js 2>/dev/null || \
     grep -qF '".openclaw", "instincts"' runtime/state-paths.js 2>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
      changed "would update default paths in runtime/state-paths.js"
    else
      sed -i \
        -e 's/path\.join(os\.homedir(), "\.openclaw", "agent-runtime-guard")/path.join(os.homedir(), ".horus")/g' \
        -e 's/path\.join(os\.homedir(), "\.openclaw", "ecc-safe-plus")/path.join(os.homedir(), ".horus")/g' \
        -e 's/path\.join(os\.homedir(), "\.openclaw", "instincts")/path.join(os.homedir(), ".horus", "instincts")/g' \
        runtime/state-paths.js
      changed "updated default paths in runtime/state-paths.js"
    fi
  fi
fi

# ── Phase 6: File renames ───────────────────────────────────────────────────────

printf '\n=== Phase 6: file renames ===\n'

rename_file "schemas/horus.config.schema.json"    "schemas/horus.config.schema.json"
rename_file "schemas/horus.contract.schema.json"  "schemas/horus.contract.schema.json"
rename_file "scripts/horus-cli.sh"                "scripts/horus-cli.sh"
rename_file "scripts/horus-diff-decisions.sh"     "scripts/horus-diff-decisions.sh"
rename_file "horus.config.json.example"           "horus.config.json.example"
rename_file "horus.contract.json.example"         "horus.contract.json.example"

# ── Phase 7: Update schema $id fields ──────────────────────────────────────────

printf '\n=== Phase 7: schema \$id fields ===\n'

for schema in schemas/horus.config.schema.json schemas/horus.contract.schema.json; do
  [ -f "$schema" ] || continue
  if grep -qF '"ecc.' "$schema" 2>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
      changed "would update \$id in $schema"
    else
      sed -i 's/"\$id": "ecc\./"\$id": "horus./g' "$schema"
      changed "updated \$id in $schema"
    fi
  fi
done

# ── Summary ────────────────────────────────────────────────────────────────────

printf '\n=== Summary ===\n'
if [ "$DRY_RUN" -eq 1 ]; then
  printf 'Dry run complete. %d changes would be made, %d skipped.\n' "$changed" "$skipped"
  printf 'Run with --apply to execute.\n'
else
  printf 'Rebrand applied: %d changes, %d skipped.\n' "$changed" "$skipped"
  printf 'Next steps:\n'
  printf '  1. Run: bash scripts/run-fixtures.sh\n'
  printf '  2. If fixtures pass: git add -A && git commit -m "chore(rebrand): HORUS_ → HORUS_, rename ecc.* files"\n'
  printf '  3. Run: bash scripts/horus-rebrand.sh --verify\n'
fi
