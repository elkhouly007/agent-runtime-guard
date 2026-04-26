#!/usr/bin/env bash
# bench-runtime-decision.sh — Measure runtime.decide() latency over 1000 calls.
# Prints p50/p95/p99 in ms and fails if p99 exceeds P99_CEILING_MS (default 5).
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
workdir="$(mktemp -d)"
cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

# Default ceiling: 5ms on Linux (CI), 500ms on Windows (file-system overhead).
# Override with HORUS_BENCH_P99_MS=<n> to set explicitly.
if [ -n "${HORUS_BENCH_P99_MS:-}" ]; then
  P99_CEILING_MS="$HORUS_BENCH_P99_MS"
elif [ "${OS:-}" = "Windows_NT" ] || uname -s 2>/dev/null | grep -qiE 'mingw|msys|cygwin'; then
  P99_CEILING_MS=500
elif uname -r 2>/dev/null | grep -qi 'microsoft' && pwd | grep -q '^/mnt/'; then
  # WSL on a Windows-mounted filesystem (/mnt/c/…) — IO is Windows-class.
  P99_CEILING_MS=500
else
  P99_CEILING_MS=5
fi

slow_fs=0; [ "$P99_CEILING_MS" = "500" ] && slow_fs=1

printf '[bench-runtime-decision]\n'

node - <<'NODE' "$root" "$workdir" "$P99_CEILING_MS" "$slow_fs" || exit 1
"use strict";
const path = require('path');
const fs   = require('fs');
const root = process.argv[2];
const workdir = process.argv[3];
const p99Ceiling = Number(process.argv[4]);

process.env.HORUS_STATE_DIR = workdir;
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
const slowFs = process.argv[5] === "1";
const platformKey = slowFs ? `${process.platform}-slowfs` : process.platform;

// Split cold-cache (first 10) vs warm-cache reporting
const coldLatencies = latencies.slice(0, 10).sort((a, b) => a - b);
const coldP99 = coldLatencies[coldLatencies.length - 1] ?? p99;

console.log(`  platform: ${platformKey}  node: ${nodeVer}`);
console.log(`  N=${N}  p50=${p50.toFixed(3)}ms  p95=${p95.toFixed(3)}ms  p99=${p99.toFixed(3)}ms (warm)`);
console.log(`  cold-cache p99=${coldP99.toFixed(3)}ms (first 10 calls)`);

// Persist baseline for regression detection (1.5× rule)
const baselineDir  = path.join(root, "artifacts", "bench");
const baselineFile = path.join(baselineDir, "baseline.json");
let baseline = null;
try {
  if (fs.existsSync(baselineFile)) {
    baseline = JSON.parse(fs.readFileSync(baselineFile, "utf8"));
  }
} catch { /* baseline is optional */ }

if (baseline && baseline[platformKey] && baseline[platformKey].p99) {
  const baseP99 = Number(baseline[platformKey].p99);
  const cap = Math.min(p99Ceiling, baseP99 * 1.5);
  if (p99 > cap) {
    console.error(`  ERROR   p99 ${p99.toFixed(3)}ms exceeds 1.5× baseline (${baseP99.toFixed(3)}ms → cap ${cap.toFixed(3)}ms)`);
    process.exit(1);
  }
  console.log(`  ok      p99 within 1.5× baseline (baseline=${baseP99.toFixed(3)}ms cap=${cap.toFixed(3)}ms)`);
}

try {
  if (!fs.existsSync(baselineDir)) fs.mkdirSync(baselineDir, { recursive: true });
  const existing = fs.existsSync(baselineFile)
    ? JSON.parse(fs.readFileSync(baselineFile, "utf8"))
    : {};
  const prior = existing[platformKey];
  if (prior && Number(prior.p50) > 0 && p50 > Number(prior.p50) * 3) {
    console.log(`  WARN    p50 is 3× slower than prior baseline — skipping overwrite (likely wrong FS context)`);
  } else {
    existing[platformKey] = { p50: p50.toFixed(3), p95: p95.toFixed(3), p99: p99.toFixed(3), updatedAt: new Date().toISOString(), node: nodeVer };
    fs.writeFileSync(baselineFile, JSON.stringify(existing, null, 2) + "\n");
  }
} catch { /* baseline write is best-effort */ }

if (p99 > p99Ceiling) {
  console.error(`  ERROR   p99 ${p99.toFixed(3)}ms exceeds ceiling ${p99Ceiling}ms — severe regression detected`);
  process.exit(1);
}
console.log(`  ok      p99 ${p99.toFixed(3)}ms within ${p99Ceiling}ms ceiling`);
NODE

printf '\nRuntime decision bench passed.\n'
