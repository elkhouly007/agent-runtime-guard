#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

sample_ok="$(./scripts/classify-payload.sh tests/sample-payload.txt)"
sample_sensitive="$(./scripts/classify-payload.sh tests/sensitive-payload.txt)"

printf '%s\n' "$sample_ok" | grep -q 'payload_class=A'
printf '%s\n' "$sample_sensitive" | grep -q 'payload_class=C'
printf '%s\n' "$sample_sensitive" | grep -q 'approval_required=yes'

./scripts/redact-payload.sh tests/sensitive-payload.txt | grep -q '\[REDACTED_EMAIL\]'

printf '%s\n' "Payload protection test passed."
