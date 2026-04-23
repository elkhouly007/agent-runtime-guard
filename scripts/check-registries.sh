#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

status=0

for file in \
  modules/mcp-pack/registry.json \
  modules/wrapper-pack/registry.json \
  modules/plugin-pack/registry.json \
  modules/browser-pack/registry.json \
  modules/notification-pack/registry.json \
  modules/daemon-pack/registry.json
 do
  if [ ! -f "$file" ]; then
    printf '%s\n' "Missing registry: $file" >&2
    status=1
    continue
  fi
  if ! grep -q '"version"' "$file"; then
    printf '%s\n' "Missing version field: $file" >&2
    status=1
  fi
 done

if [ "$status" -eq 0 ]; then
  printf '%s\n' "Registry check passed."
else
  printf '%s\n' "Registry check found problems." >&2
fi

exit "$status"
