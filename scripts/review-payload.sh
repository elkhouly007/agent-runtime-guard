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

printf '%s\n' "Reviewing payload: $payload_file"
if [ -x "$(dirname "$0")/classify-payload.sh" ]; then
  "$(dirname "$0")/classify-payload.sh" "$payload_file"
fi
printf '%s\n' "---BEGIN PAYLOAD PREVIEW---"
cat "$payload_file"
printf '%s\n' "---END PAYLOAD PREVIEW---"
printf '%s\n' "Checklist: destination known? non-sensitive? no hidden delete/write?"
printf '%s\n' "If payload_class=C or approval_required=yes, stop unless user approved the external send."
printf '%s\n' "Use redact-payload.sh when sensitive content can be reduced before sending."
