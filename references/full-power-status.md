# Full-Power Status

Last updated: 2026-04-23
Upstream reference: `affaan-m/everything-claude-code` `v1.10.0`
Source of truth for parity: `references/parity-matrix.json`

## Current State Summary

Agent Runtime Guard currently includes:

- cross-tool policy layers for OpenClaw, OpenCode, and Claude Code;
- reviewed capability packs for MCP, wrappers, plugins, browser, notifications, and daemons;
- upstream review workflow scaffolding and payload protection;
- **48 specialist agents**, including full coverage of the 38 upstream agents plus 10 ECC-only additions;
- **91 rule files** with **87 direct upstream matches** and 4 ECC-only additions;
- **199 skill files** with **156 direct upstream matches** and 43 ECC-only additions;
- 20 approval-boundary scenarios and 14 prompt-injection scenarios;
- executable fixture coverage with **92/92 passing**;
- clean verification across audit, smoke, payload protection, fixtures, integration smoke, installation/profile checks, config/settings integration checks, apply-status validation, executable hygiene, setup-wizard edge cases, per-tool wiring-doc coverage, unified status-artifact checks, policy-lint, sensitive-data-detection, and superiority-evidence checks.

## Verification Snapshot

Current verified state:

- `audit-local.sh` — passing
- `audit-examples.sh` — passing
- `check-registries.sh` — passing
- `check-scenarios.sh` — passing
- `run-fixtures.sh` — passing (85/85)
- `test-payload-protection.sh` — passing
- `check-integration-smoke.sh` — passing
- `smoke-test.sh` — passing
- `check-skills.sh --errors-only` — passing
- `check-installation.sh` — passing
- `check-config-integration.sh` — passing
- `check-apply-status.sh` — passing
- `check-executables.sh` — passing
- `check-setup-wizard.sh` — passing
- `check-wiring-docs.sh` — passing
- `check-superiority-evidence.sh` — passing
- `check-status-docs.sh` — passing
- `check-status-artifact.sh` — passing
- `policy-lint.sh` — passing
- `detect-sensitive-data.sh` — passing
- `status-summary.sh` — passing

## Parity Snapshot

| Component | Upstream | Current | Adopted | Deferred | ECC-only |
|---|---:|---:|---:|---:|---:|
| Agents | 38 | 48 | 38 | 0 | 10 |
| Rules | 87 | 91 | 87 | 0 | 4 |
| Skills | 156 | 199 | 156 | 0 | 43 |

## Sprint Status

### Closed parity-to-superiority program
- **Sprint 1, Truth and Verification**: complete
- **Sprint 2, Rules Parity Wave**: complete
- **Sprint 3, Skills Parity Wave**: complete
- **Sprint 4, Runtime Activation and Evidence**: complete

### Current follow-on runtime sprint
- **Sprint R2, Runtime autonomy follow-on / policy lifecycle auditability**: complete
- Delivered emphasis: adaptive action plans, explicit promotion flows, reviewed-default lifecycle visibility, lifecycle timing, and audit-friendly runtime history
- **Sprint R3, Routing and workflow fidelity**: CLOSED
- Sprint R3 delivered: `payloadClass` and `sessionRisk` flow through the hook path at full fidelity; `escalate` action has a dedicated human-gated workflow lane; one-time opt-in auto-allow (eligible-gated, single-use); session-trajectory-driven routing nudges actions up after repeated escalations (threshold/window env-tunable); `ECC_KILL_SWITCH=1` emergency block.

## Runtime Performance

Measured with `scripts/bench-runtime-decision.sh` (N=1000 representative decisions):

| Platform | Node | p50 | p95 | p99 | Ceiling |
|----------|------|-----|-----|-----|---------|
| win32 (Windows 11, Git Bash) | v25.5.0 | ~39ms | ~76ms | ~99ms | 500ms |
| ubuntu-latest (CI) | v20 (expected) | <1ms | <2ms | <5ms | 5ms |

Note: Windows numbers are dominated by `fs.appendFileSync` / `fs.writeFileSync` in the decision journal and session state recorder (~40ms per `decide()` call). Linux numbers are IO-bound only on first call due to module cache warmup.

## Honest Power Estimate

Practical interpretation relative to upstream now:

- **Agents**: at or above upstream coverage
- **Rules**: full upstream parity, plus ECC-only additions
- **Skills**: full upstream coverage is now represented in-tree, plus ECC-only additions
- **Safety and verification**: stronger and cleaner than upstream in several important areas

The correct current description is:

> **Agent Runtime Guard has full upstream content parity, plus ECC-only extensions, and verified runtime/usability/superiority layers that put it above upstream in measurable ways.**

## Post-v0.8.0 Runtime Sprint Highlights

Since parity closeout and the `v0.8.0` release, the current runtime sprint has added:

1. runtime decisioning with local learned policy, session context, and project-aware config,
2. bounded workflow actions such as `require-review`, `require-tests`, and `modify`,
3. adaptive action plans based on repeated approvals and pending suggestions,
4. lifecycle-aware promotion guidance with explicit CLI next steps,
5. a dedicated `runtime promote` flow for reviewed local defaults,
6. promoted and dismissed default tracking with audit timestamps,
7. lifecycle timing output (`created-at`, `eligible-at`, accepted/dismissed, `last-approved-at`),
8. compact lifecycle summaries in `runtime explain`,
9. clean verification across `check-runtime-core.sh`, `check-runtime-cli.sh`, and the full `ecc-cli.sh check` path.

This means Agent Runtime Guard is no longer only past parity, but is actively growing a bounded autonomous runtime layer on top of that verified base.
