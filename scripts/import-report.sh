#!/usr/bin/env bash
set -eu

usage() {
  printf '%s\n' "Usage: $0 <source-name> <output-file>"
}

case "${1:-}" in
  -h|--help|"")
    usage
    exit 0
    ;;
esac

if [ "$#" -lt 2 ]; then
  usage
  exit 2
fi

source_name="$1"
output_file="$2"

cat > "$output_file" <<EOF
# Import Report

## Source

- repo or module: $source_name
- revision or date:
- files reviewed:

## Classification

- docs/prompts:
- hooks:
- plugins:
- MCP:
- installers:
- wrappers/daemons:
- config defaults:

## Findings

- outbound data flow:
- hidden downloads or installs:
- file writes or deletes:
- permission model impact:
- prompt or payload mutation:

## Decision Per Area

- adopt directly:
- adapt into safe-plus:
- defer:
- reject:

## Verification

- audit passed:
- docs updated:
- policy match confirmed:
EOF

printf '%s\n' "Wrote import report template to: $output_file"
