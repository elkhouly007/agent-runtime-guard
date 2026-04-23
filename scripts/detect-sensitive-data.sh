#!/usr/bin/env bash
# detect-sensitive-data.sh — Scan a file or stdin for common sensitive data patterns.
#
# Usage:
#   ./scripts/detect-sensitive-data.sh <file>
#   printf 'my password is secret' | ./scripts/detect-sensitive-data.sh
#
# Exit 0 = no sensitive data found. Exit 1 = sensitive data found.

set -eu

input_file="${1:-/dev/stdin}"

# Patterns to detect
# - API Keys: common patterns like 'sk-...' or 'key-...'
# - Credentials: 'password', 'secret', 'token'
# - PII: email addresses, phone numbers (simple regex)
# - Infrastructure: connection strings

patterns=(
  "sk-[a-zA-Z0-9]{32,}"          # OpenAI style keys
  "password[[:space:]]*[:=]"      # Password assignments
  "secret[[:space:]]*[:=]"        # Secret assignments
  "token[[:space:]]*[:=]"         # Token assignments
  "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}" # Email
  "mongodb\\+srv://"              # MongoDB URI
  "postgres://"                   # Postgres URI
  "amqp://"                       # RabbitMQ
  "redis://"                      # Redis
)

found=0
tmp_matches="$(mktemp)"
trap 'rm -f "$tmp_matches"' EXIT

for p in "${patterns[@]}"; do
  grep -Ei "$p" "$input_file" >> "$tmp_matches" || true
done

if [ -s "$tmp_matches" ]; then
  printf 'WARNING: Potential sensitive data detected:\n' >&2
  cat "$tmp_matches" | sed 's/^/  /' >&2
  exit 1
fi

exit 0
