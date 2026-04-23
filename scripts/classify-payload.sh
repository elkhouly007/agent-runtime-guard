#!/usr/bin/env bash
set -eu

usage() {
  printf '%s\n' "Usage: $0 <payload-file>"
}

case "${1:-}" in
  -h|--help|"")
    usage
    exit 0
    ;;
esac

payload_file="$1"
if [ ! -f "$payload_file" ]; then
  printf '%s\n' "Missing payload file: $payload_file" >&2
  exit 2
fi

text="$(cat "$payload_file")"
class="A"
reason="non-sensitive operational"
approval_required="no"

# Class C — personal or secret content.
# Uses multi-word / specific phrases to reduce false positives.
# Deliberately avoids single words like "token" (too common in code) or
# "customer" (matches "customer service FAQ", "customer segment", etc.).
if printf '%s' "$text" | grep -Eiq \
  '(api[_ -]?key[[:space:]]*[:=]|password[[:space:]]*[:=]|secret[[:space:]]*[:=]|auth[_ -]?token[[:space:]]*[:=]|customer[[:space:]]+(data|record|pii|info|email|list)|passport (number|scan)|national[[:space:]]+id[[:space:]]+(number|card)|salary[[:space:]]+(data|info|record|details)|private[[:space:]]+(message|email)|employee[[:space:]]+(id|record|data)|iban[[:space:]]|credit[[:space:]]+card[[:space:]]+(number|data)|-----BEGIN[[:space:]]+(RSA|EC|OPENSSH)?[[:space:]]*PRIVATE)'; then
  class="C"
  reason="possible personal or secret content"
  approval_required="yes"
# Class B — sensitive operational content.
# Multi-word phrases only to avoid "internal combustion", "private equity", etc.
elif printf '%s' "$text" | grep -Eiq \
  '(internal[[:space:]]+(only|project|roadmap|document|memo|policy)|private[[:space:]]+(repo|repository|key)|system[[:space:]]+architecture|non[-]?public|security[[:space:]]+incident|product[[:space:]]+roadmap|legal[[:space:]]+(advice|document|contract|opinion)|financial[[:space:]]+(data|report|forecast)|hr[[:space:]]+(policy|record|data))'; then
  class="B"
  reason="possible sensitive operational content"
fi

# High-risk action wording (additive — applies to any class, only appends to reason).
# Kept broad intentionally: this section never changes the class or approval_required,
# it just adds a note so the reviewer knows to look closely.
if printf '%s' "$text" | grep -Eiq '\b(delete|destroy|overwrite|drop[[:space:]]+table|drop[[:space:]]+database|shutdown|terminate|rm[[:space:]]+-rf|git[[:space:]]+push[[:space:]]+--force)\b'; then
  reason="$reason; contains potentially high-risk action wording"
fi

printf 'payload_class=%s\n' "$class"
printf 'reason=%s\n' "$reason"
printf 'approval_required=%s\n' "$approval_required"
