# Full-Power Status

Last updated: 2026-04-23
Source of truth for counts: `references/parity-matrix.json`

## Current State Summary

Agent Runtime Guard currently includes:

- cross-tool policy layers for OpenClaw, OpenCode, and Claude Code;
- reviewed capability packs for MCP, wrappers, plugins, browser, notifications, and daemons;
- ARG amplification philosophy throughout: every agent, rule, and skill is purpose-built for this project;
- **49 specialist agents** following the ARG amplification philosophy — Mission, ARG-aware Activation, numbered Protocol, measurable Done When;
- **81 rule files** covering 12 language directories plus common, database, infrastructure, and web domains;
- **22 skills** for ARG debug, policy tuning, capability auditing, code analysis, orchestration design, and more;
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

## Capability Snapshot

| Component | Prior Baseline | Current | Original | Notes |
|---|---:|---:|---:|---|
| Agents | 0 | 49 | 49 | All written for ARG amplification philosophy |
| Rules | 0 | 81 | 81 | 12 languages + common/database/infra/web domains |
| Skills | 0 | 22 | 22 | ARG debug, policy, analysis, orchestration |

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
