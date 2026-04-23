#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
out_dir="${1:-$root/artifacts/status}"
summary_file="$out_dir/status-summary.txt"
meta_file="$out_dir/status-summary.meta"

mkdir -p "$out_dir"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
version="$(tr -d '[:space:]' < "$root/VERSION" 2>/dev/null || echo unknown)"

ARG_SKIP_STATUS_ARTIFACT_CHECK=1 bash "$root/scripts/status-summary.sh" > "$summary_file"

# Count repo contents from filesystem (used by check-status-artifact.sh for drift detection)
agents_count="$(find "$root/agents" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
rules_count="$(find "$root/rules" -name '*.md' | wc -l | tr -d ' ')"
skills_count="$(find "$root/skills" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
scripts_count="$(find "$root/scripts" -maxdepth 1 -type f | wc -l | tr -d ' ')"
fixtures_count="$(find "$root/tests/fixtures" -name '*.input' | wc -l | tr -d ' ')"
checks_count="$(find "$root/scripts" -maxdepth 1 -name 'check-*.sh' | wc -l | tr -d ' ')"

cat > "$meta_file" <<EOF
artifact=status-summary
version=${version}
generated_at=${generated_at}
source=scripts/status-summary.sh
path=${summary_file}
agents=${agents_count}
rules=${rules_count}
skills=${skills_count}
scripts=${scripts_count}
fixtures=${fixtures_count}
checks=${checks_count}
EOF

printf 'Status artifact written to: %s\n' "$summary_file"
printf 'Status artifact metadata: %s\n' "$meta_file"
