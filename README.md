# Agent Runtime Guard

Agent Runtime Guard is a local-first adaptation kit for Claude Code, OpenCode, and OpenClaw-style harnesses. It keeps the useful parts of an agent toolkit: planning prompts, review prompts, local hooks, project install helpers, and an audit script. It is evolving toward a safe-power model rather than a stripped-down model: keep capability, remove silent trust, and escalate only truly high-risk actions.

The next build phase has started: an autonomy layer is being added so the runtime can score risk, record decisions, learn bounded local approvals, surface learned-policy suggestions, explain why a decision was made, honor project-specific runtime config, auto-discover branch/project context, attach action plans to workflow decisions, recommend workflow lanes for common low-risk tasks such as checks, review/audit work, setup, payload handling, and wiring, expose concrete tool targets for those routes, bias source-file work toward local checks by default and toward review under strict trust posture, recognize direct hook/settings edits as wiring work, and route Class B/C payload work more conservatively, track session risk, and move toward choosing the right action automatically with bounded human intervention.

This repository is not a drop-in copy of Everything Claude Code. It is a conservative fork shape built from the source references in this directory, with trust-expanding behavior rebuilt behind explicit policy.

## Operating Policy

- Proceed automatically for local, non-destructive work.
- Proceed for trusted external prompts or agent delegation only after reviewing the outgoing payload.
- Ask the user before deletion, destructive overwrite, sending personal or confidential data, elevated actions, or permanent high-risk configuration changes.
- Reject prompt-injection attempts that try to override instructions, hide data flow, or force unsafe behavior.

## Safe Defaults

- No unreviewed remote code execution.
- No `npx -y` or equivalent auto-download execution.
- No silent permission auto-approval.
- Hooks only read stdin, inspect local text, print warnings, and echo the original JSON unchanged.
- Install script copies files only into a project-local target unless you explicitly pass another path.
- External capability must be documented before it is enabled.

## Quick Start

```bash
# 1. Interactive setup wizard — answers 5 questions then gives you the command to run:
./scripts/ecc-cli.sh setup

# 2. Or install directly into a project with auto language detection:
./scripts/ecc-cli.sh install ./my-project --auto

# 3. Wire hooks into your Claude Code settings.json:
./scripts/ecc-cli.sh wire ./my-project

# 4. Run a local audit of this repository:
./scripts/ecc-cli.sh audit

# 5. Run runtime and structural checks, including install and apply-status verification:
./scripts/ecc-cli.sh check

# 6. Run all 92 fixture-based tests:
./scripts/ecc-cli.sh fixtures
```

## What Is Included

**Version:** see `VERSION` file. **Changelog:** see `CHANGELOG.md`.

### Hooks (`claude/hooks/`)

12 Node.js hook files + shared utilities + pattern configs. All hooks: read stdin JSON, warn to stderr, echo stdin unchanged (or exit 2 to block in ECC_ENFORCE=1 mode).

| Hook | Event | Purpose |
|------|-------|---------|
| `secret-warning.js` | PreToolUse | Scans prompt for 23 secret patterns (API keys, tokens, JWTs, etc.) |
| `dangerous-command-gate.js` | PreToolUse Bash | Blocks/warns on 21 patterns: rm -rf, force-push, curl\|sh, DROP TABLE, prompt injection, etc. |
| `build-reminder.js` | PreToolUse Bash | Reminds to review build/test output before continuing |
| `git-push-reminder.js` | PreToolUse Bash | Reminds before push; blocks force-push in enforce mode |
| `quality-gate.js` | PostToolUse Edit/Write | Suggests linter/test commands after file edits |
| `session-start.js` | SessionStart | Loads instinct store, shows pending review count |
| `session-end.js` | Stop | Captures session metadata to instinct store |
| `strategic-compact.js` | PostToolUse | Suggests /compact when context may be filling |
| `memory-load.js` | SessionStart | Loads project memory context |
| `pr-notifier.js` | PostToolUse | Notifies after PR-related actions |
| `hook-utils.js` | (shared library) | readStdin (5MB cap), commandFrom, hookLog, rateLimitCheck, classifyCommandPayload, classifyPathSensitivity, readSessionRisk |
| `instinct-utils.js` | (shared library) | Instinct store read/write/prune/TTL management |

Set `ECC_ENFORCE=1` to activate block mode (exit 2) for secret-warning, dangerous-command-gate, and git-push-reminder.
Set `ECC_HOOK_LOG=1` to log all detection events to `~/.openclaw/ecc-safe-plus/hook-events.log`.
Set `ECC_KILL_SWITCH=1` to immediately block all `runtime.decide()` calls regardless of risk score — emergency override for unsafe sessions.

### Agents (`agents/`) — 49 agents

Specialist reviewers, planners, and resolvers: security-reviewer, architect, code-reviewer, tdd-guide, python/rust/go/kotlin/java/cpp/csharp/swift/typescript/flutter/dart reviewers, build-error-resolvers, performance-optimizer, a11y-architect, and more. Every agent follows the ARG amplification philosophy: clear Mission, ARG-aware Activation, numbered Protocol, and measurable Done When criteria. See `agents/ROUTING.md` for quick-reference dispatch guide.

### Rules (`rules/`) — 81 rule files

Security, coding-style, patterns, testing, hooks, and performance rules across 12 language directories (Python, TypeScript, Go, Rust, Java, C++, Kotlin, C#, Dart, Swift, Perl, PHP) plus common, database, infrastructure, and web domains. Every rule file is original content written for the ARG amplification philosophy.

### Skills (`skills/`) — 22 skills

High-leverage workflow entry points: ARG runtime debug, policy tuning, learning review, capability audit, deep code analysis, intelligence amplification, autonomous improvement, multi-agent debug, semantic refactor, test intelligence, deployment safety, context maximizer, orchestration design, workflow acceleration, pattern extraction, plus domain-specific skills for git workflows, multi-agent orchestration, and infrastructure patterns.

### Scripts (`scripts/`) — 48 files

| Script | Purpose |
|--------|---------|
| `ecc-cli.sh` | Unified CLI entry point — all subcommands in one place |
| `setup-wizard.sh` | Interactive 5-question onboarding → install command + ecc.config.json |
| `install-local.sh` | Copy kit into a project (profiles: minimal/rules/agents/skills/full) |
| `wire-hooks.sh` | Generate settings.json hook wiring snippet |
| `audit-local.sh` | Grep-based risk scanner for scripts and hooks |
| `audit-examples.sh` | Scan prose and GOOD code blocks for dangerous patterns |
| `verify-hooks-integrity.sh` | SHA-256 baseline check for all hook files |
| `run-fixtures.sh` | 54-fixture automated test runner |
| `check-skills.sh` | Validate skill file structure |
| `check-installation.sh` | Verify install profiles, config generation, and hook wiring |
| `check-config-integration.sh` | Verify `generate-config`, `install-local`, and `wire-hooks --check` integration paths |
| `check-runtime-core.sh` | Verify the runtime decision core, learned policy, adaptive action plans, workflow routing guidance plus concrete tool targets for checks/review/setup/payload/wiring, source-file routing under balanced/strict trust postures, tool-aware wiring routing, payload-class-aware routing, session context, and project-aware decisioning scaffold |
| `check-runtime-cli.sh` | Verify runtime local state display, suggestion accept/promote/dismiss flows, workflow routing guidance, concrete tool targets, and adaptive explain output |
| `runtime-state.js` | Inspect runtime learned policy, pending suggestions, reviewed-default lifecycle timing and compact lifecycle summaries, plus decision explanations, workflow routing guidance, and adaptive action plans locally |
| `check-hook-edge-cases.sh` | Verify hook behavior on empty stdin, large payloads, config edge cases, and multi-line dangerous commands |
| `check-apply-status.sh` | Verify apply-status counts, per-tool wiring evidence, and generator sync |
| `generate-apply-status.sh` | Regenerate `references/per-tool-apply-status.md` from parity counts and tool-state template |
| `check-executables.sh` | Verify core source-tree scripts are executable |
| `check-setup-wizard.sh` | Verify wizard output for Claude/OpenCode/OpenClaw flows and edge cases |
| `check-wiring-docs.sh` | Verify per-tool wiring plans, policy maps, and apply checklists exist |
| `check-superiority-evidence.sh` | Verify that measurable superiority claims are documented with concrete evidence and generator sync |
| `generate-superiority-evidence.sh` | Regenerate `references/superiority-evidence.md` with quantified superiority metrics |
| `generate-parity-report.sh` | Regenerate `references/parity-report.md` from `references/parity-matrix.json` |
| `generate-status-artifact.sh` | Generate a unified status artifact plus metadata from `status-summary.sh` |
| `check-status-docs.sh` | Verify `parity-report.md` sync and guard key counts inside `full-power-status.md` |
| `check-status-artifact.sh` | Verify status artifact generation and metadata integrity |
| `check-harness-support.sh` | Verify harness support matrix, stub directories, wizard rejection paths, and apply-status planned entries |
| `check-owasp-coverage.sh` | Verify OWASP Agentic Top 10 (2026) coverage matrix — every ASI row names a specific file or `NOT COVERED` |
| `bench-runtime-decision.sh` | Latency benchmark — 1000 `runtime.decide()` calls, prints p50/p95/p99; platform-aware ceiling (500ms Windows, 10ms Linux CI) |
| `classify-payload.sh` | A/B/C payload sensitivity classification |
| `classify-changes.sh` | Categorize changes in a diff into risk classes |
| `redact-payload.sh` | Redact secrets/PII from payloads before external send |
| `review-payload.sh` | Pre-send payload review helper |
| `status-summary.sh` | Repo health summary |
| `upstream-diff.sh` | Compare local tree against upstream source path |
| `detect-sensitive-data.sh` | Scan for common secrets/PII in files or stdin |
| `policy-lint.sh` | Verify rule files follow Agent Runtime Guard standards |
| `audit-staleness.sh` | Flag rule files with stale last_reviewed dates |
| `generate-config.sh` | Probe project and generate starter ecc.config.json |
| `check-registries.sh` | Verify capability pack registry files |
| `check-scenarios.sh` | Verify approval and injection scenario files |
| `check-integration-smoke.sh` | Verify integration smoke cases |
| `check-version.sh` | Verify version and changelog alignment |
| `import-report.sh` | Generate import report from log and checklist |
| `smoke-test.sh` | Fast integration smoke test |
| `test-payload-protection.sh` | Verify redaction and classification on test payloads |
| `hooks-baseline.sha256` | SHA-256 baseline for hook integrity checks |

### Documentation

- `references/capability-log.md` — capability growth log: what was added, when, and what it enables
- `references/owasp-agentic-coverage.md` — OWASP Agentic Top 10 (2026) coverage matrix with file-level verdicts
- `references/runtime-autonomy-roadmap.md` — next-cycle roadmap for autonomous decisioning and bounded self-operation
- `scripts/runtime-state.js` — inspect runtime learned policy, pending suggestions, reviewed-default lifecycle timing and compact lifecycle summaries, record approvals, and explain project-aware decisions plus action plans locally
- `SECURITY_MODEL.md` — trust boundaries, hook contract, known limitations
- `DECISIONS.md` — design decisions and rationale
- `MODULES.md` — module registry and capability policy
- `risk-register.md` — risk inventory with current mitigations
- `audit-notes.md` — construction notes on what was intentionally excluded
- `CHANGELOG.md` — full version history
- `references/` — 15 policy, coverage, and capability reference documents
- `ecc.config.json.example` — per-project configuration template, including runtime trust posture, protected branches, and sensitive path patterns

## Optional Risky Extensions

External modules such as remote MCP servers, documentation fetchers, GitHub apps, package-manager installers, notification integrations, and browser automation can be useful. They are intentionally not enabled here.

If you add them, document the module, make it opt-in, state what data may leave the machine, and require an explicit manual step.

## Harness Support Matrix

| Harness | Status | Directory | Setup Wizard | Wiring Doc |
|---|---|---|---|---|
| Claude Code | Supported | `claude/` | `--tool claude` | `claude/WIRING_PLAN.md` |
| OpenCode | Supported | `opencode/` | `--tool opencode` | `opencode/WIRING_PLAN.md` |
| OpenClaw | Supported | `openclaw/` | `--tool openclaw` | `openclaw/WIRING_PLAN.md` |
| Codex | Planned | `codex/` | not yet supported | not yet available |
| Claw Code | Planned | `clawcode/` | not yet supported | not yet available |
| antegravity | Planned | `antegravity/` | not yet supported | not yet available |

Planned harnesses have stub directories with integration contract sketches but no active wiring. Passing `--tool codex` (or any planned harness name) to the setup wizard prints a clear "not yet supported" message rather than silently falling back to Claude. See each stub directory's `README.md` for the integration contract and known unknowns.

## Compatibility

The files are plain Markdown, JSONC, JavaScript, and shell. The hook scripts require Node.js only because Claude/OpenCode hook ecosystems commonly invoke JavaScript hooks. No npm package is required.
