#!/usr/bin/env bash
# bench-runtime-decision.sh — Measure runtime.decide() latency over 1000 calls.
# Prints p50/p95/p99 in ms and fails if p99 exceeds P99_CEILING_MS (default 5).
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
workdir="$(mktemp -d)"
cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

# Default ceiling: 5ms on Linux (CI), 500ms on Windows (file-system overhead).
# Override with ECC_BENCH_P99_MS=<n> to set explicitly.
if [ -n "${ECC_BENCH_P99_MS:-}" ]; then
  P99_CEILING_MS="$ECC_BENCH_P99_MS"
elif uname -s 2>/dev/null | grep -qi mingw; then
  P99_CEILING_MS=500
else
  P99_CEILING_MS=5
fi

printf '[bench-runtime-decision]\n'

node - <<'NODE' "$root" "$workdir" "$P99_CEILING_MS" || exit 1
"use strict";
const path = require('path');
const root = process.argv[2];
const workdir = process.argv[3];
const p99Ceiling = Number(process.argv[4]);

process.env.ECC_STATE_DIR = workdir;
const { decide } = require(path.join(root, 'runtime/decision-engine.js'));

const inputs = [
  { command: 'npm test',                   tool: 'Bash', targetPath: 'src/app.ts',      sessionRisk: 0, repeatedApprovals: 0 },
  { command: 'npm run build',              tool: 'Bash', targetPath: 'src/',             sessionRisk: 0, repeatedApprovals: 0 },
  { command: 'git status',                 tool: 'Bash', targetPath: '.',                sessionRisk: 0, repeatedApprovals: 0 },
  { command: 'sudo systemctl restart app', tool: 'Bash', targetPath: 'ops/service',      sessionRisk: 0, repeatedApprovals: 2 },
  { command: 'npx -y tsx scripts/run.ts',  tool: 'Bash', targetPath: 'scripts/run.ts',   sessionRisk: 0, repeatedApprovals: 0 },
  { command: 'cat .env',                   tool: 'Bash', targetPath: '.env',             sessionRisk: 0, repeatedApprovals: 0 },
  { command: 'edit module',                tool: 'Edit', targetPath: 'src/runtime.ts',   sessionRisk: 0, repeatedApprovals: 0 },
  { command: 'update docs',               tool: 'Bash', targetPath: 'docs/readme.md',   sessionRisk: 1, repeatedApprovals: 0 },
  { command: 'rm -rf /tmp/build',          tool: 'Bash', targetPath: '/tmp/build',       sessionRisk: 0, repeatedApprovals: 0 },
  { command: 'git push origin main',       tool: 'Bash', targetPath: 'src/',             sessionRisk: 0, repeatedApprovals: 0 },
];

const N = 1000;
const latencies = [];

for (let i = 0; i < N; i++) {
  const input = inputs[i % inputs.length];
  const start = process.hrtime.bigint();
  decide(input);
  const end = process.hrtime.bigint();
  latencies.push(Number(end - start) / 1e6); // nanoseconds → ms
}

latencies.sort((a, b) => a - b);
const p50  = latencies[Math.floor(N * 0.50)];
const p95  = latencies[Math.floor(N * 0.95)];
const p99  = latencies[Math.floor(N * 0.99)];

const nodeVer = process.version;
const platform = process.platform;

console.log(`  platform: ${platform}  node: ${nodeVer}`);
console.log(`  N=${N}  p50=${p50.toFixed(3)}ms  p95=${p95.toFixed(3)}ms  p99=${p99.toFixed(3)}ms`);

if (p99 > p99Ceiling) {
  console.error(`  ERROR   p99 ${p99.toFixed(3)}ms exceeds ceiling ${p99Ceiling}ms — severe regression detected`);
  process.exit(1);
}
console.log(`  ok      p99 ${p99.toFixed(3)}ms within ${p99Ceiling}ms ceiling`);
NODE

printf '\nRuntime decision bench passed.\n'
