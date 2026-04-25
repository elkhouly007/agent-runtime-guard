#!/usr/bin/env bash
# redact-payload.sh — Redact sensitive content from a payload file before external sends.
#
# Usage:
#   ./scripts/redact-payload.sh <payload-file>           # print redacted output to stdout
#   ./scripts/redact-payload.sh <payload-file> --diff    # show before/after side-by-side
#
# Patterns redacted:
#   Email addresses, phone numbers, generic secrets/tokens/passwords,
#   API keys (Anthropic, OpenAI, Stripe, AWS, GitHub), JWTs, database URIs,
#   GCP service account emails, Azure connection strings, PEM key blocks,
#   local file paths (Unix + Windows), IPv4 addresses in log-style context.

set -eu

usage() {
  printf '%s\n' "Usage: $0 <payload-file> [--diff]"
}

diff_mode=0
payload_file=""

for arg in "$@"; do
  case "$arg" in
    --diff)    diff_mode=1 ;;
    -h|--help) usage; exit 0 ;;
    -*)        printf 'Unknown option: %s\n' "$arg" >&2; usage; exit 2 ;;
    *)         payload_file="$arg" ;;
  esac
done

[ -n "$payload_file" ] || { usage; exit 2; }
[ -f "$payload_file" ] || { printf 'Missing payload file: %s\n' "$payload_file" >&2; exit 2; }

# ── redaction pipeline ────────────────────────────────────────────────────────

redact() {
  sed -E \
    -e 's/sk-ant-[A-Za-z0-9_-]{20,}/[REDACTED_ANTHROPIC_KEY]/g' \
    -e 's/sk_(live|test)_[A-Za-z0-9]{20,}/[REDACTED_STRIPE_KEY]/g' \
    -e 's/sk-[A-Za-z0-9_-]{20,}/[REDACTED_OPENAI_KEY]/g' \
    -e 's/AKIA[A-Z0-9]{16}/[REDACTED_AWS_KEY]/g' \
    -e 's/github_pat_[A-Za-z0-9_]{40,}/[REDACTED_GITHUB_PAT]/g' \
    -e 's/gh[pousr]_[A-Za-z0-9_]{20,}/[REDACTED_GITHUB_TOKEN]/g' \
    -e 's/SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}/[REDACTED_SENDGRID_KEY]/g' \
    -e 's/xox[baprs]-[A-Za-z0-9-]{20,}/[REDACTED_SLACK_TOKEN]/g' \
    -e 's/pypi-[A-Za-z0-9_-]{40,}/[REDACTED_PYPI_TOKEN]/g' \
    -e 's/eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/[REDACTED_JWT]/g' \
    -e 's/DefaultEndpointsProtocol=https;AccountName=[^;[:space:]]*/[REDACTED_AZURE_CONN]/g' \
    -e 's|-----BEGIN [A-Z ]* KEY-----|[REDACTED_PRIVATE_KEY_BEGIN]|g' \
    -e 's|-----END [A-Z ]* KEY-----|[REDACTED_PRIVATE_KEY_END]|g' \
    -e 's|-----BEGIN CERTIFICATE-----|[REDACTED_CERT_BEGIN]|g' \
    -e 's|-----END CERTIFICATE-----|[REDACTED_CERT_END]|g' \
    -e 's|[a-z]+://[^:@[:space:]]+:[^@[:space:]]{3,}@[^[:space:]]+|[REDACTED_DB_URI]|g' \
    -e 's/[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+\.iam\.gserviceaccount\.com/[REDACTED_GCP_SA]/g' \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/[REDACTED_EMAIL]/g' \
    -e 's/\+?[0-9][0-9() -]{7,}[0-9]/[REDACTED_PHONE]/g' \
    -e 's#/home/[^[:space:]"'"'"']+#[REDACTED_UNIX_PATH]#g' \
    -e 's#/Users/[^[:space:]"'"'"']+#[REDACTED_UNIX_PATH]#g' \
    -e 's#[A-Za-z]:\\\\[^[:space:]"'"'"']+#[REDACTED_WIN_PATH]#g' \
    -e 's/(api[_ -]?key|token|password|passwd|secret|auth_key)[[:space:]]*[:=][[:space:]]*[^[:space:]]{8,}/\1=[REDACTED_SECRET]/gi' \
    -e 's/((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/[REDACTED_IP]/g' \
    "$1"
}

# ── diff mode ─────────────────────────────────────────────────────────────────

if [ "$diff_mode" -eq 1 ]; then
  tmp_redacted="$(mktemp)"
  trap 'rm -f "$tmp_redacted"' EXIT

  redact "$payload_file" > "$tmp_redacted"

  # Count redacted fields
  original_lines="$(wc -l < "$payload_file")"
  redacted_count="$(diff "$payload_file" "$tmp_redacted" | grep -c '^>' || true)"

  printf '%s\n' "━━━ ORIGINAL ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cat "$payload_file"
  printf '\n%s\n' "━━━ REDACTED ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  cat "$tmp_redacted"
  printf '\n%s\n' "━━━ DIFF ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  diff "$payload_file" "$tmp_redacted" || true
  printf '\n%s\n' "Redaction complete. Review the REDACTED version above before sending."
else
  redact "$payload_file"
fi
