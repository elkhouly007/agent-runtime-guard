#!/usr/bin/env bash
# check-zero-deps.sh — Assert runtime/*.js has no third-party require() calls.
#
# Any require() argument in runtime/ must be a Node.js builtin (node:* or
# a known bare builtin name) OR a relative path (starts with . or ..).
# Fails CI if a third-party package import is found.
#
# Usage: bash scripts/check-zero-deps.sh

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; FAILED=1; }

# Node.js built-in module names (bare names, no "node:" prefix required).
# This list covers all modules available in Node 18+.
NODE_BUILTINS="assert|async_hooks|buffer|child_process|cluster|console|constants|crypto|dgram|diagnostics_channel|dns|domain|events|fs|http|http2|https|inspector|module|net|os|path|perf_hooks|process|punycode|querystring|readline|repl|stream|string_decoder|sys|timers|tls|trace_events|tty|url|util|v8|vm|wasi|worker_threads|zlib"

FAILED=0

printf '[check-zero-deps]\n'

# Find all JS files in runtime/.
runtime_files=()
while IFS= read -r f; do runtime_files+=("$f"); done < <(find "$root/runtime" -maxdepth 1 -name "*.js" | sort)

if [ "${#runtime_files[@]}" -eq 0 ]; then
  fail "no runtime/*.js files found"
  exit 1
fi

for file in "${runtime_files[@]}"; do
  base="$(basename "$file")"

  # Extract the string argument from every require("...") or require('...')
  # in the file. We only look at single-level require calls on one line.
  while IFS= read -r line; do
    # Skip comment lines.
    [[ "$line" =~ ^[[:space:]]*/[/*] ]] && continue

    # Extract the module specifier from require("mod") or require('mod').
    if [[ "$line" =~ require\([\'\"]([^\'\"]+)[\'\"] ]]; then
      mod="${BASH_REMATCH[1]}"

      # Relative imports are always allowed (local modules).
      [[ "$mod" == .* ]] && continue

      # "node:" prefix is always a builtin.
      [[ "$mod" == node:* ]] && continue

      # Bare builtin name.
      if echo "$mod" | grep -qE "^(${NODE_BUILTINS})$"; then
        continue
      fi

      # Anything else is a third-party dependency — fail.
      fail "$base: third-party require detected: '$mod'"
    fi
  done < "$file"

  [ "$FAILED" -eq 0 ] && pass "$base: no third-party imports"
done

if [ "$FAILED" -ne 0 ]; then
  printf '\ncheck-zero-deps FAILED — runtime/ must have zero third-party dependencies.\n' >&2
  exit 1
fi

printf '\ncheck-zero-deps passed — runtime/ is dependency-free.\n'
