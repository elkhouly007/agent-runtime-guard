# Changelog

All notable changes to Agent Runtime Guard are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

---

## [1.3.1] — 2026-04-24

### Added
- `runtime/risk-score.js`: four new risk patterns closing documented engine gaps:
  - `hard-reset-pattern` (`git reset --hard`) — +4 points, medium → `route`
  - `kubectl-delete-pattern` (`kubectl delete|remove`) — +4 points, medium → `route`
  - `git-clean-pattern` (`git clean -f`) — +3 points, medium → `route`
  - `broad-permission-pattern` (`chmod 777/666/o+w/a+w`) — +3 points, medium → `route`
- `tests/eval-corpus.json`: 7 new entries (57 total: 29 safe / 12 dangerous / 16 borderline):
  - borderline-08/09 updated from `allow` (known gap) to `warn` (now caught)
  - borderline-14 (`git clean -fd`), borderline-15 (`chmod 777`), borderline-16 (`kubectl delete namespace`)
  - safe-26 (`git reset HEAD~1` — soft reset, no `--hard`), safe-27 (`kubectl get pods`), safe-28 (`chmod +x`), safe-29 (`git clean --dry-run`)
- `references/decision-quality.md`: baseline updated to v1.3.1 (57 entries, 0.0% FP / 0.0% FN).

---

## [1.3.0] — 2026-04-24

### Added
- `tests/eval-corpus.json` — 50-entry labeled eval corpus: 25 safe, 12 dangerous, 13 borderline. Each entry drives one `runtime.decide()` call and specifies an expected action class and expected reason codes.
- `scripts/eval-decision-quality.sh` — decision quality measurement script. Runs the labeled corpus through `runtime.decide()` in isolation (per-entry `sessionRisk=0`, `ECC_TRAJECTORY_THRESHOLD=9999`), maps outcomes to `allow/warn/block` classes, and reports false-positive rate (safe entries blocked) and false-negative rate (dangerous entries missed). Exits 1 if FP% > `ECC_EVAL_MAX_FP_PCT` (default 10%) or FN% > `ECC_EVAL_MAX_FN_PCT` (default 20%).
- `ecc-cli.sh eval` subcommand — dispatches to `eval-decision-quality.sh`. Supports `--verbose`, `--max-fp-pct`, `--max-fn-pct`, `--corpus`.
- `references/decision-quality.md` — baseline quality report for v1.3.0: 0.0% FP / 0.0% FN against the corpus, with per-entry table and notes on known engine gaps.
- README updated: Quick Start step 8 (`eval`); scripts table updated (count: 50 → 51).

### Baseline (v1.3.0)
- False-positive rate: **0.0%** (0 / 25 safe entries blocked)
- False-negative rate: **0.0%** (0 / 12 dangerous entries missed)

---

## [1.2.0] — 2026-04-24

### Added
- `scripts/install.sh` — single-command install entry point. Validates Node.js and git, copies kit files, generates `ecc.config.json` if missing, prints the wire-hooks snippet. Replaces the three-step wizard → install-local → wire-hooks flow. Flags: `--profile`, `--tool`, `--auto`, `--yes`, `--dry-run`.
- `scripts/upgrade.sh` — in-place upgrade for existing installations. Reads installed `VERSION`, re-runs install with the same profile (from `ecc.config.json`), preserves `ecc.config.json` unconditionally, updates `VERSION`, and reports the version delta. State files in `ECC_STATE_DIR` are never touched.
- `ecc-cli.sh install` now dispatches to `install.sh` (was `install-local.sh`); `ecc-cli.sh upgrade` added as new subcommand.
- `check-installation.sh` extended with sections 10–13: `install.sh --dry-run`, fresh install, same-version no-op, and version-bump upgrade with config preservation.
- README Quick Start updated to lead with `install` + `upgrade` commands; scripts table updated with new entries (count: 48 → 50).

---

## [1.1.0] — 2026-04-24

### Added
- Unified decision path: `secret-warning.js` and `git-push-reminder.js` now route through `runtime.decide()` for unified policy, trajectory tracking, and explainability. Secret and force-push decisions are now subject to session risk escalation, decision journaling, and consistent `[Agent Runtime Guard]` output prefix.
- `references/unified-master-plan.md` — canonical project plan replacing `IMPROVEMENT_PLAN.md`'s stale parity-tracking content. Covers current-state audit, end-state definition, multi-harness support strategy, gap analysis, full phased roadmap, and project score.

### Fixed
- `secret-warning.js` and `git-push-reminder.js` output prefix changed from `[ECC Safe-Plus]` to `[Agent Runtime Guard]` to match `dangerous-command-gate.js`. All 23 fixture `expected_stderr` files updated accordingly.
- `IMPROVEMENT_PLAN.md` deprecated with a notice pointing to `unified-master-plan.md`; stale baselines (129 skills, 48 agents, 50 rules) are now clearly labeled as historical.
- `scripts/hooks-baseline.sha256` regenerated after hook changes.

---

## [1.0.3] — 2026-04-24

### Fixed
- `scripts/check-runtime-core.sh`: use `fs.realpathSync.native` (Windows `GetFinalPathNameByHandleW`) to resolve 8.3 short paths (e.g. `RUNNER~1` → `runneradmin`) before path comparisons in the `discover-git-repo` test. Fixes Windows CI failure where `os.tmpdir()` returns an 8.3 abbreviated path while `git rev-parse --show-toplevel` returns the canonical long form.
- `scripts/check-runtime-core.sh`: suppress decision-journal file writes during tests via `ECC_DECISION_JOURNAL=0`; eliminates potential AV-locking failures on the Windows CI runner.

---

## [1.0.2] — 2026-04-23

### Added
- Enforce/block-mode fixtures: 4 new DCG enforce pairs (curl-pipe-sh, force-push, dd-device, drop-table) and 3 new secret-warning enforce pairs (private-key-block, aws-access-key-id, openai-key). Total fixtures: 85 → 92/92.
- Windows CI runner added to check workflow matrix (`windows-latest`, 500ms bench ceiling). All check steps now run on both Ubuntu and Windows.
- `check-scenarios.sh` now verifies scenario counts: 20 approval-boundary and 14 prompt-injection (was existence-only check).

### Fixed
- `dangerous-command-gate.js`: `runtimeDecision()` now runs in its own isolated try/catch with severity fallback — a corrupted policy file or runtime throw can no longer silently bypass the gate. All `hookLog()` calls in the block path moved to after `console.error()` and wrapped in try, ensuring `process.exit(2)` is always reached.
- `secret-warning.js`: `hookLog()` moved after `console.error()` and wrapped in try in the ENFORCE block, ensuring `process.exit(2)` is always reached.
- `git-push-reminder.js`: same `hookLog()` ordering fix in the ENFORCE block.
- `runtime/policy-store.js`: module-level cache eliminates 4+ redundant `fs.readFileSync` calls per `decide()` invocation. Cache is invalidated on every write.
- `runtime/session-context.js`: same read-cache pattern — eliminates 2 redundant state reads per `decide()` call.
- OWASP matrix ASI04 verdict corrected from `COVERED` to `PARTIAL`: `redact-payload.sh` is an offline audit tool, not wired into hook execution. `secret-warning.js` is the real runtime control.

---

## [1.0.1] — 2026-04-23

### Added
- Expanded fixture coverage from 54 to 85/85: added positive fixtures for all 21 dangerous-command-gate patterns (was 10/21) and all 23 secret-warning patterns (was 4/23). Private-key block, certificate block, and 17 other patterns now have explicit test inputs.
- `classifyPathSensitivity` unit tests in `check-runtime-core.sh` covering low/medium/high tiers.
- JSONL audit trail end-to-end assertion in `check-hook-edge-cases.sh`.
- Trajectory-nudge negative tests: verified learned-allow and auto-allow-once remain exempt under 3+ escalation seeds.
- `check-status-artifact.sh` wired into `ecc-cli.sh check` (was CI-only); `check-scenarios.sh` wired into both `ecc-cli.sh check` and CI.
- `check-owasp-coverage.sh` and `bench-runtime-decision.sh` added to README scripts table.

### Fixed
- Fixture count in README, full-power-status.md updated to 85/85.
- IMPROVEMENT_PLAN.md `Last updated` header corrected from 2026-04-21 to 2026-04-23.
- CLAUDE_CODE_HANDOFF.md: CI check step count corrected from "20" to "24"; broken `STATUS.md` link replaced with `artifacts/status/status-summary.txt`.
- `hookLog` and `rateLimitCheck` now route through `ECC_STATE_DIR` when set (back-compat fallback preserved).
- `ECC_DECISION_JOURNAL=0` added as primary kill switch for decision journal; `ARG_DECISION_JOURNAL=0` kept as deprecated alias.
- `workflow-router.js` `primaryStack` priority aligned to `action-planner.js` (explicit input wins over auto-detected).

---

## [1.0.0] — 2026-04-23

### Added
- **B.1 — Auto-allow-once**: `grantAutoAllowOnce(key)`, `consumeAutoAllowOnce(key)`, `hasAutoAllowOnce(key)` in `runtime/policy-store.js`. Only policies with a pending suggestion (approvalCount ≥ 3) may receive a single-use grant. `runtime.decide()` checks and consumes the token for non-critical, non-high-risk commands; emits `auto-allow-once=consumed` in explanation. CLI verb: `ecc-cli.sh runtime auto-allow-once '<policy-key>'`.
- **B.2 — Trajectory-driven routing**: `getSessionTrajectory()` in `runtime/session-context.js` returns `{ recentEscalations, recentReviews, lastDecisionAt }` bounded to a configurable window (`ECC_TRAJECTORY_WINDOW_MIN`, default 30 min). `runtime/decision-engine.js` nudges actions up one step (allow→route, route→require-review, require-review→escalate) when `recentEscalations >= ECC_TRAJECTORY_THRESHOLD` (default 3); learned-allow and auto-allow-once sources are exempt; nudge appears in `explanation` and new `trajectoryNudge` result field. Sprint R3 acceptance items now closed.
- Tests for B.1 and B.2 in `scripts/check-runtime-core.sh` and B.1 CLI test in `scripts/check-runtime-cli.sh`.
- **C.1 — OWASP Agentic Top 10 2026 coverage matrix**: `references/owasp-agentic-coverage.md` maps each ASI01–ASI10 risk to specific files or explicit NOT COVERED / PARTIAL / DEFERRED verdicts. `scripts/check-owasp-coverage.sh` enforces all 10 rows exist, each has a verdict, and every referenced file exists. Wired into CI and `ecc-cli.sh check`.
- **C.2 — Path-sensitivity classifier**: `classifyPathSensitivity(path)` in `claude/hooks/hook-utils.js` returns `low | medium | high` based on SSH keys, cloud credentials, vault paths, `.env` files, infra dirs, etc. `dangerous-command-gate.js` computes it from `targetPath` and passes `pathSensitivity` to `runtime.decide()`; `runtime/risk-score.js` adds +1 (medium) or +2 (high) to risk score; hook prints "Sensitive path detected" when ≥ medium. Advisory only — does not block unilaterally.
- **C.3 — Kill switch**: `ECC_KILL_SWITCH=1` env var causes `runtime.decide()` to return `action: "block"` for every input immediately, regardless of risk score. Documented in `claude/hooks/README.md` with full env-var reference table. Test case added to `check-runtime-core.sh`.
- **C.4 — Runtime decision latency bench**: `scripts/bench-runtime-decision.sh` runs 1000 representative `decide()` calls and prints p50/p95/p99. Platform-aware ceiling: 5ms on Linux CI, 500ms on Windows (file-system overhead). Documented in `references/full-power-status.md`. Wired into CI (`ECC_BENCH_P99_MS=10`) and `ecc-cli.sh check`.
- **C.5 — JSONL audit trail**: `hookLog()` in `claude/hooks/hook-utils.js` now emits structured JSONL (`{"ts":"...","hook":"...","event":"...","label":"..."}`) instead of tab-separated text. `ecc-cli.sh log --since '<timestamp>'` filter added to select entries by ISO timestamp using inline Node.js.

### Release Summary
- Sprint R3 fully closed: auto-allow-once lifecycle and trajectory-driven routing complete all R3 acceptance criteria.
- OWASP Agentic Top 10 2026 coverage mapped and machine-verified.
- Kill switch, path-sensitivity classifier, JSONL audit trail, and latency bench complete community-informed improvement cycle.
- CI workflow now covers all 18 check groups (was 8 at v0.9.0).

---

## [0.9.0] — 2026-04-23

### Added (Tier A — self-maintaining hardening follow-up)
- `scripts/check-fixture-count.sh` now also validates the fixture count in the `CHANGELOG.md` current section, closing the gap where the docstring claimed CHANGELOG coverage but the grep was absent.
- `scripts/ecc-cli.sh check` now preflights `node` on PATH and exits 2 with a clear message (including the known LMStudio bundled path hint) when `node` is absent; removes the previous silent-failure mode for node-dependent check groups.

### Changed (Tier A — self-maintaining hardening follow-up)
- `scripts/check-harness-support.sh` Supported-harness assertion now uses a single anchored regex (`\| *<Harness> *\|[^|]*Supported`) and fails loudly if a Supported label is dropped; the previous `|| true` softness is removed.

### Added (Sprint R3 opener — hook fidelity + multi-harness honesty)
- `classifyCommandPayload()` in `claude/hooks/hook-utils.js` — in-process payload classification (A/B/C) for command strings, mirroring `classify-payload.sh` tier logic without spawning a shell.
- `readSessionRisk()` in `claude/hooks/hook-utils.js` — explicit session-risk reader wrapping `runtime.getSessionRisk()` for hook integration.
- Dedicated `escalation` workflow lane in `runtime/workflow-router.js` — action `escalate` now routes to `lane=escalation`, `suggestedSurface=security-reviewer`, `suggestedTarget=human-gate`; remains human-gated with `enforcementAction=block`.
- `scripts/check-fixture-count.sh` — verifies fixture `.input` count matches `README.md` and `references/full-power-status.md`.

### Changed (Sprint R3 opener)
- `claude/hooks/dangerous-command-gate.js` now computes `payloadClass` and `sessionRisk` in the hook process and passes both to `runtime.decide()`, closing the hook/engine fidelity gap from R2; hook stderr now prints payload class (if non-A), session risk (if non-zero), workflow route lane (if non-direct), and an explicit ESCALATION ROUTE marker when action is `escalate`.
- `scripts/check-runtime-core.sh` extended with three new cases: escalate lane routing, payloadClass-C-to-review routing, sessionRisk bump reflected in decision explanation, and in-process `classifyCommandPayload` classification.
- `scripts/check-runtime-cli.sh` extended with escalate-lane routing test via `runtime explain`.
- `scripts/status-summary.sh` now prints disk-count summary lines after the [Agents], [Rules], and [Skills] sections, making uncovered drift immediately visible.
- `scripts/check-status-docs.sh` now validates per-tool table row counts in `references/per-tool-apply-status.md` against parity-matrix values.
- `scripts/ecc-cli.sh check` and `scripts/status-summary.sh` [Verification] block now include `check-fixture-count.sh`.
- `references/runtime-autonomy-roadmap.md` updated to record Sprint R3 opener as landed and explicitly call out what remains open in Sprint R3.

### Added (W3 — multi-harness honesty)
- Stub harness directories `codex/`, `clawcode/`, `antegravity/` — each with `README.md` (explicit NOT YET SUPPORTED marker + integration contract sketch) and `COMPATIBILITY_NOTES.md` (full list of unknowns and path to support).
- `scripts/check-harness-support.sh` — verifies the Harness Support Matrix in README.md, stub directory presence and NOT YET SUPPORTED markers, wizard rejection behavior, and per-tool-apply-status Planned Harnesses section.

### Changed (W3 — multi-harness honesty)
- `README.md` now includes a "Harness Support Matrix" section distinguishing Supported (Claude Code, OpenCode, OpenClaw) from Planned (Codex, Claw Code, antegravity) harnesses.
- `scripts/setup-wizard.sh` now exits non-zero with a clear "NOT YET SUPPORTED" message for planned harness tool names (`codex`, `clawcode`, `antegravity`) and a pointer to the Harness Support Matrix; completely unknown tool names also exit non-zero.
- `scripts/check-setup-wizard.sh` extended to assert that planned harness tool names produce the non-zero exit + not-yet-supported message.
- `scripts/generate-apply-status.sh` extended with a "Planned Harnesses" section listing Codex, Claw Code, and antegravity with explicit `status=planned, wiring=not-implemented` entries.
- `scripts/ecc-cli.sh check` and `scripts/status-summary.sh` [Verification] block now include `check-harness-support.sh`.

### Added (earlier in Unreleased)


- `references/runtime-autonomy-roadmap.md` to define the next improvement cycle around bounded autonomy, risk scoring, local learning, and self-maintaining runtime behavior.
- `runtime/decision-engine.js`, `runtime/risk-score.js`, and `runtime/decision-journal.js` as the first autonomy-layer scaffold.
- `runtime/workflow-router.js` for initial workflow-lane recommendations across review, checks, setup, payload, wiring, and direct execution paths.
- `runtime/policy-store.js` and `runtime/session-context.js` for learned local policy and rolling session-risk state.
- `runtime/promotion-guidance.js` for structured lifecycle-aware policy promotion guidance (stages: new, approaching, eligible, promoted, dismissed, ineligible) with concrete CLI hints surfaced in hook output, runtime explain, and runtime state.
- `scripts/check-runtime-core.sh` to verify runtime decisioning primitives, learned policy behavior, session context, and promotion guidance.
- `scripts/generate-status-artifact.sh` and `scripts/check-status-artifact.sh` to produce and verify a unified repo status artifact with metadata.

### Changed
- `claude/hooks/hook-utils.js` now exposes a lightweight runtime decision entry point for hook integration.
- `scripts/status-summary.sh`, `README.md`, `references/full-power-status.md`, and `references/superiority-evidence.md` now include status-artifact-aware self-maintenance coverage, and the artifact generator now avoids recursive self-check execution during generation.
- `claude/hooks/dangerous-command-gate.js` now consults the runtime decision layer and surfaces learned-allow versus block/escalate behavior.
- `runtime/policy-store.js` now promotes repeated approvals into pending learned-policy suggestions instead of silently relying on implicit state only, and reviewed-default lifecycle history is now surfaced as both raw timestamps and compact per-decision summaries.
- `references/runtime-autonomy-roadmap.md` and `references/full-power-status.md` now record Sprint R2 policy-lifecycle auditability as complete and identify Sprint R3 routing/workflow autonomy as the next runtime step.
- `ecc-cli.sh` now exposes runtime state, suggestion acceptance, suggestion dismissal, explicit approval recording, and decision explanation flows.
- runtime decisions now load per-project runtime config from `ecc.config.json`, including trust posture, protected branches, and sensitive path patterns.
- runtime context discovery now auto-detects project root and git branch, and decision actions now include bounded orchestration states like `require-review`, `require-tests`, and `modify`.
- workflow-style runtime actions now carry action plans with suggested commands, review types, or safer modification hints for hooks and CLI surfaces.
- action plans now adapt to local approval/suggestion history so recurring patterns can surface stronger policy-promotion guidance instead of staying static.
- `runtime/decision-engine.js` now attaches structured `promotionGuidance` (stage, guidance text, CLI hint) to every decision output.
- `runtime/decision-engine.js` and `scripts/runtime-state.js` now surface initial workflow routing guidance (`workflow-lane`, `workflow-surface`, `workflow-target`, `workflow-command`) for common low-risk paths, including review and audit flows alongside checks, setup, payload, wiring, a source-file-to-checks default, strict-trust escalation of source-file work toward review, tool-aware routing for direct settings/hook edits, and payload-class-aware review defaults for Class B/C work.
- `runtime/action-planner.js` now includes `promotionHint` in action plans when the pattern has promotion history.
- `claude/hooks/dangerous-command-gate.js` now surfaces promotion stage and CLI hints in hook stderr output.
- `scripts/runtime-state.js` now shows promotion stage, guidance, CLI hints, reviewed-default lifecycle timing (`created-at`, `eligible-at`, accepted/dismissed), and a compact lifecycle summary in `explain` output, plus explicit `promote` commands and lifecycle summaries in state output.
- `scripts/check-runtime-core.sh` and `scripts/check-runtime-cli.sh` now verify promotion guidance in decisions, explicit promotion flows, and CLI output.
- `ecc-cli.sh check` and `status-summary.sh` now include runtime-core verification.

---

## [0.8.1] — 2026-04-22

### Fixed
- **MODULES.md** — expanded from 3 hooks to all 12 hooks plus 2 shared libraries and 2 pattern configs. Each entry now documents event type and `ECC_ENFORCE=1` blocking behavior.
- **SECURITY_MODEL.md** — hook contract updated to document: 5 MB stdin cap, `ECC_ENFORCE=1` exit-code-2 blocking mode, rate limiting via `rateLimitCheck()`, and which hooks support blocking.
- **risk-register.md** — copied from main repo and expanded from 10 to 15 risks covering dangerous shell commands, prompt injection, hook file tampering, hook spawn rate, and command obfuscation.
- **audit-notes.md** — copied from main repo to close documentation gap.

---

## [0.8.0] — 2026-04-21

### Added
- `check-config-integration.sh` for end-to-end verification of `generate-config.sh`, config-driven `install-local.sh`, and `wire-hooks.sh --check`.
- `check-hook-edge-cases.sh` for empty stdin, oversized payload, malformed config, and multi-line dangerous-command coverage.
- `generate-apply-status.sh`, `generate-parity-report.sh`, and `generate-superiority-evidence.sh` to reduce documentation drift.
- `check-status-docs.sh` to guard key count claims and generated report sync.
- `references/final-comparison-audit.md` to record the two-round closeout audit against both internal docs and the upstream baseline.

### Changed
- `ecc-cli.sh check` and `status-summary.sh` now include config integration, hook edge cases, status-doc sync, and quantified superiority verification.
- `references/per-tool-apply-status.md`, `references/parity-report.md`, and `references/superiority-evidence.md` now follow semi-generated anti-drift workflows.
- Sprint 4 is now closed, and the repo status is documented as full parity plus measured superiority.

### Release Summary
- Full upstream content parity is now complete: 38/38 agents, 87/87 rules, and 156/156 skills adopted.
- Agent Runtime Guard now carries 57 ECC-only extensions beyond upstream.
- Runtime/usability verification is now enforced by 17 verification layers, including installation, config integration, hook edge cases, apply-status sync, superiority evidence, and status-doc sync.
- This release closes the parity-to-superiority project scope and marks the start of any future work as a new improvement cycle.

---

## [0.7.3] — 2026-04-20

### Fixed
- **classify-payload.sh** — Class B and C detection now uses multi-word / specific phrases to eliminate false positives. "internal combustion engine" no longer classifies as B; "customer service FAQ" no longer classifies as C. High-risk action wording section (additive, non-blocking) retains broad single-word matching by design.
- **audit-local.sh** — URL scan narrowed from bare `https?://` to fetch/download context (`curl`, `wget`, `fetch`, `http.get`, `axios.get`, `requests.get` + URL). Documentation links and example URLs no longer trigger false positives.
- **rules/python/security.md** — Anti-patterns table corrected: `random.token_hex()` (which doesn't exist in the `random` module) replaced with `random.randint()` as the BAD example, `secrets.token_hex()` / `secrets.token_bytes()` as the GOOD example.
- **strategic-compact.js** — Added `hookLog("strategic-compact", "INFO", ...)` when a compaction suggestion fires. Events now appear in `hook-events.log` when `ECC_HOOK_LOG=1`.
- **skills/README.md** — Updated from listing 6 skills to documenting all 130 across 10 categories with a full category overview table.

---

## [0.7.2] — 2026-04-20

### Security
- **dangerous-patterns.json** — added 4 prompt injection patterns (medium severity): ignore-instructions, override-policy, exfiltrate-data, jailbreak-framing. Detected by `dangerous-command-gate.js` in warn mode (or block in `ECC_ENFORCE=1`).
- **dangerous-command-gate.js** — replaced `.find()` with `.filter()` + sort by severity. Highest-severity pattern now always wins regardless of JSON ordering. Prevents silent severity downgrade when a medium pattern appears before a critical one.
- **SECURITY_MODEL.md** — added "Known Limitations" section documenting: command obfuscation bypass, rate limiter TOCTOU race, and heuristic-only prompt injection detection.

### Performance
- **build-reminder.js** — added `rateLimitCheck("build-reminder")`. All four PreToolUse hooks now participate in rate limiting.

### Testing
- **3 new DCG prompt injection fixtures** — `dcg-pi-ignore-instructions`, `dcg-pi-override-policy`, `dcg-pi-jailbreak-framing`. Total: 54 fixtures, 54/54 passing.

### Correctness
- **wire-hooks.sh `--verify`** — added `dangerous-command-gate.js` to the verification list (was the only hook missing).
- **hook-utils.js `rateLimitCheck`** — added detailed TOCTOU race condition comment with analysis of why it is accepted as benign.

---

## [0.7.1] — 2026-04-20

### Security (Tier 1 bug fixes from multi-model review)
- **secret-warning.js** — removed duplicated `readStdin`/`collectText` functions that lacked the 5 MB cap. Now imports `readStdin`, `collectText`, and `ENFORCE` directly from `hook-utils.js`. Oversized payloads are now correctly rejected before secret scanning begins.
- **setup-wizard.sh** — replaced hardcoded `/tmp/ecc_wizard_config.json` with `mktemp` to eliminate the symlink attack vector (same class of bug fixed in `strategic-compact.js` in v0.6.0).
- **instinct-utils.js** — `ensureDir()` now passes `mode: 0o700` to `mkdirSync`. The `~/.openclaw/instincts/` directory is no longer world-readable.
- **install-local.sh** — `minimal_files()` now includes all hook files (`session-start.js`, `session-end.js`, `strategic-compact.js`, `memory-load.js`, `pr-notifier.js`). Previously, a minimal install wired all hooks from `hooks.json` but only copied 10 of 15, causing runtime failures.

---

## [0.7.0] — 2026-04-20

### Added
- **setup-wizard.sh** — Interactive onboarding wizard (5 questions → ready-to-run install command + starter ecc.config.json). Supports `--non-interactive` mode for automation.
- **check-skills.sh** — Validates all 130 skill files for required H1 heading and Trigger/Purpose section. `--errors-only` flag for CI. Zero errors across all 129 skills.
- **ecc-cli.sh** — Unified CLI entry point consolidating 14 individual scripts into one interface with subcommands: `install`, `setup`, `audit`, `check`, `fixtures`, `integrity`, `status`, `review`, `classify`, `redact`, `wire`, `log`, `version`.

### Observability
- **hook-utils.js: hookLog()** — Append-only event log at `~/.openclaw/ecc-safe-plus/hook-events.log`. Activated by `ECC_HOOK_LOG=1`. Records metadata only (hook name, timestamp, event type, detection label — never payload content or commands). Wired into `dangerous-command-gate.js`, `git-push-reminder.js`, and `secret-warning.js`.
- **ecc-cli.sh log** — View log with `--tail N` or clear it with `--clear`.

### Performance
- **hook-utils.js: rateLimitCheck()** — File-based token-bucket rate limiter (60 token capacity, 30 tokens/s refill). Prevents 3000+ Node.js process spawns per minute during high-velocity sessions. Wired into all three PreToolUse hooks. Disable with `ECC_RATE_LIMIT=0`.

### Audit
- **session-end.js instinct fields** — Verified: `extractSafeMetadata()` reads only `tool_name` and `event_type`; `trigger`/`behavior` fields are hardcoded placeholders filled by user on review. No auto-extracted session content, commands, or file paths captured.

---

## [0.6.0] — 2026-04-20

### Security
- **dangerous-command-gate.js** (new hook) — blocks `rm -rf`, `git push --force`, `curl | sh`, `DROP TABLE`, `npx -y`, `sudo rm`, and 13 other dangerous shell command patterns. `ECC_ENFORCE=1` blocks critical/high-severity commands; default mode warns.
- **dangerous-patterns.json** — 17 extensible patterns with severity levels (critical/high/medium) and reasons. Add project-specific patterns without editing the hook.
- **git-push-reminder.js** — upgraded from warn-only to enforce-capable. `ECC_ENFORCE=1` now blocks force pushes entirely.
- **secret-patterns.json** — fixed misleading `"The hook never blocks"` comment. Block mode with `ECC_ENFORCE=1` was always supported but undocumented.
- **strategic-compact.js** — counter file moved from `/tmp/ecc-session-counter.json` to `~/.openclaw/ecc-safe-plus/session-counter.json` to eliminate Linux symlink attack risk.

### Added
- **hook-utils.js** — shared hook utilities: `readStdin` with 5 MB cap (prevents memory exhaustion), `commandFrom`, `collectText`, `ENFORCE`. Eliminates 9 identical copies of these functions across all hooks.
- **verify-hooks-integrity.sh** — SHA-256 baseline for all 15 hook files. Run `--update` after intentional changes; commit baseline to git so tampered hooks are visible in diffs.
- **scripts/hooks-baseline.sha256** — initial baseline for integrity checking.

### Fixed
- **quality-gate.js** — removed duplicate `.rs` key (cargo clippy only); unified to `cargo clippy && cargo test`. Added `.c` and `.h` file support.
- **quality-gate.js** — now imports `readStdin` from `hook-utils.js` instead of inline copy.

### Testing
- **run-fixtures.sh** — expanded from 2 fixture sections to 5: classify, secret-warning, dangerous-command-gate, git-push-reminder, redact-payload.
- **45 fixtures** total (was 22): 26 classify (20 new approval-boundary + 6 existing), 8 secret-warning (3 new prompt-injection), 7 dangerous-command-gate (all new), 4 git-push-reminder (all new), 6 redact-payload (all new).

### Rules
- **rust/security.md** — 67 → 333 lines. Added OWASP map, path traversal, command injection, JWT, rate limiting, secrecy crate, anti-patterns table.
- **kotlin/security.md** — 71 → 336 lines. Added OWASP map, open redirect, JWT verification, coroutine safety, log injection, anti-patterns table.
- **csharp/security.md** — 68 → 312 lines. Added OWASP map, XSS (Razor/Blazor), open redirect, AES-GCM, JWT config, anti-patterns table.
- **cpp/security.md** — 98 → 307 lines. Added OWASP map, format strings, RAII patterns, path traversal, fuzzing setup, compiler security flags, anti-patterns table.

### Install
- **install-local.sh** — reads `ecc.config.json` from target directory; respects `profile` and `languages` fields. New hooks added to `minimal_files()`.
- **audit-examples.sh** — Pass 2 added: flags dangerous patterns inside GOOD-labeled code blocks (previously only scanned prose).
- **redact-payload.sh** — added IPv4 address redaction pattern.

---

## [0.5.0] — 2026-04-19

### Rules
- 12 thin rule files rewritten to production depth (150–400 lines each).
- Affected: common/patterns, common/performance, common/coding-style, common/security, common/testing, common/development-workflow, python/coding-style, python/testing, java/security, golang/security, swift/security, web/coding-style.

### Infrastructure
- hooks.json: /ABS_PATH/ placeholder guidance added.
- wire-hooks.sh: generates ready-to-paste settings.json snippet.
- audit-examples.sh: initial version for prose scanning.
- run-fixtures.sh: initial 22-fixture test runner.

---

## [0.4.0] — 2026-04-18

### Added
- 23 thin agent/skill files deepened to production quality.
- secret-patterns.json: expanded from 5 to 23 patterns.
- install-local.sh: profiles (minimal/rules/agents/skills/full), --auto language detection, --list dry-run.
- ecc.config.json.example: per-project config template.
- agents/index.json, agents/ROUTING.md: agent routing and dispatch guide.
- classify-payload.sh, redact-payload.sh, review-payload.sh: payload protection pipeline.
- modules/daemon-pack/: scoped background helper patterns.

---

## [0.3.0] — 2026-04-17

### Added
- Initial 38 agents, 48 rules, 60 skills from ECC v1.10.0 source review.
- Phase 1/2/3 policy structure (trusted-agents, MCP, shell, plugins, browser, notifications, installers, wrappers, daemons).
- 9 hooks: secret-warning, build-reminder, git-push-reminder, quality-gate, strategic-compact, memory-load, session-start, session-end, pr-notifier.
- scripts: install-local.sh, audit-local.sh, check-registries.sh, smoke-test.sh, status-summary.sh.
- SECURITY_MODEL.md, MODULES.md, DECISIONS.md.
- references/: phase policies, upstream-sync, vendor-policy, import-checklist, payload guides.
