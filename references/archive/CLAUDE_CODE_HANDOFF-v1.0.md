# Claude Code Handoff for Agent Runtime Guard

Use this file as the working brief for Claude Code.

---

## Primary Instruction

You are taking over active engineering work inside the **Agent Runtime Guard** repository.

This is not a blank-slate project and not a lightweight review task.
You are continuing a real workstream that already has substantial verified progress.
Your job is to understand the repo deeply, preserve what already works, identify the real remaining gaps, and then implement meaningful improvements with verification.

You must behave like a careful senior engineer working in a live repository:
- inspect before changing,
- preserve existing working behavior,
- fix real problems when you find them,
- improve code, docs, checks, status reporting, and operator usability together,
- and leave the repo in a genuinely stronger state than you found it.

Do not stop at planning.
Do real work.

---

## Repository Identity

Project name:
- **Agent Runtime Guard**

Historical name during earlier work:
- **ECC Safe-Plus**

Historical upstream comparison baseline:
- `affaan-m/everything-claude-code`
- baseline version: `v1.10.0`

Important context:
- This repository started as a conservative adaptation / fork-shape informed by the upstream baseline.
- It is **not** supposed to remain a shallow copy.
- The parity-to-superiority program is already closed.
- The current mission is to push the project forward beyond parity into runtime intelligence, self-maintaining behavior, and practical multi-harness usability.

---

## What Is Already True

Preserve these truths unless direct inspection proves otherwise:

### 1. Upstream parity work is already complete
The repo already reached full upstream content parity for:
- agents
- rules
- skills

And it also includes ECC-only additions beyond upstream.

This means the project is **not** still trying to achieve basic parity.
Do not waste time pretending parity is the main open problem.

### 2. Verification and safety layers already exist
The repo already contains substantial verification, policy, wiring, setup, and status/reporting layers.
This is one of the project’s strengths.

### 3. Runtime follow-on work is already underway
The project already began building a bounded runtime/autonomy layer, including work around:
- decision engine behavior,
- risk scoring,
- policy store,
- session context,
- workflow routing,
- action planning,
- promotion guidance,
- project-shape detection,
- project-config-aware behavior,
- stack-aware routing and verification suggestions.

### 4. The strategic conclusion is already known
A prior review concluded that:
- parity is complete,
- but the main remaining gap is **runtime intelligence and self-maintaining system behavior**, not more parity importing.

Respect that conclusion unless direct technical evidence shows otherwise.

---

## Recent Work You Must Understand

The most recent active phase is:
- **Phase 4: Self-maintaining system**

Recent confirmed milestones include:

### Phase 4 milestone 1
Added:
- `scripts/generate-status-artifact.sh`
- `scripts/check-status-artifact.sh`

Purpose:
- start making the repository more self-observing and self-maintaining,
- generate a unified status artifact plus metadata,
- verify that artifact generation works.

### Phase 4 milestone 2
Status-artifact coverage was integrated into:
- `scripts/status-summary.sh`

During that work, a real issue was discovered:
- a recursion hazard existed between `status-summary.sh` and `check-status-artifact.sh`

That issue was then fixed by making artifact generation skip the recursive status-artifact self-check during generation.

### Phase 4 milestone 3
A real documentation drift was then found:
- `README.md` had stale script counts,
- and was missing proper mention of the new status-artifact scripts.

That README drift was fixed.

### Verified clean state after fixes
After those fixes, clean verification was re-established, including successful checks for:
- `check-status-docs.sh`
- `check-status-artifact.sh`
- `check-superiority-evidence.sh`
- `./scripts/ecc-cli.sh check`

Recent commit of note:
- `5030115` — `tools: harden status artifact self-maintenance`

You must verify this state yourself, but this is the intended continuation point.

---

## Current State at v1.0.0 (2026-04-23)

`VERSION` is `1.0.0`. All 20/20 `ecc-cli check` groups pass on Windows (node in PATH via LMStudio). CI runs 24 check steps on ubuntu-latest.

### Sprint R3 — CLOSED (all acceptance items complete)
- **B.1 Auto-allow-once**: `grantAutoAllowOnce` / `consumeAutoAllowOnce` / `hasAutoAllowOnce` in `runtime/policy-store.js`; CLI verb `ecc-cli runtime auto-allow-once '<key>'`; eligible-stage (pending + approvalCount ≥ 3) gate enforced.
- **B.2 Session-trajectory routing**: `getSessionTrajectory()` in `runtime/session-context.js`; nudges action up one step after `ECC_TRAJECTORY_THRESHOLD` (default 3) escalations in `ECC_TRAJECTORY_WINDOW_MIN` (default 30 min); surfaces "trajectory-nudge" in explain output.
- **C.1 OWASP coverage doc**: `references/owasp-agentic-coverage.md` (ASI01–ASI10 matrix); enforced by `scripts/check-owasp-coverage.sh`.
- **C.2 Path-sensitivity classifier**: `classifyPathSensitivity()` in `claude/hooks/hook-utils.js`; feeds `pathSensitivity` (+1/+2) into `risk-score.js`; advisory only — no standalone block.
- **C.3 Kill switch**: `ECC_KILL_SWITCH=1` forces `action: "block"` for all `runtime.decide()` calls.
- **C.4 Runtime bench**: `scripts/bench-runtime-decision.sh`; p50/p95/p99 over 1000 decisions; platform-aware ceiling (500ms Windows, 5ms Linux CI).
- **C.5 JSONL audit trail**: `hookLog()` emits JSONL; `ecc-cli log --since '<timestamp>'` filter added.
- **E.1 CI completeness**: all 24 check steps wired in `.github/workflows/check.yml` (was 8); 20 ecc-cli check groups wired locally.
- **E.2 Windows state isolation**: `ECC_STATE_DIR` override in `policy-store.js`, `session-context.js`, `decision-journal.js`.

### Known environment notes
- Node path on this machine: `/c/Users/Khouly/.lmstudio/.internal/utils/node.exe` — add to `PATH` before running checks.
- Windows bench p99 ~95ms (FS overhead) vs Linux <5ms; CI uses `ECC_BENCH_P99_MS=10`.
- `os.homedir()` ignores `HOME` on Windows — always use `ECC_STATE_DIR` for test isolation.

---

## What We Actually Want This Project To Become

We want Agent Runtime Guard to become a more powerful, practical, safe, bounded, runtime-aware agent operations kit.

We specifically want the project to become more genuinely usable across these harness ecosystems:
- Claude Code
- OpenClaw
- Codex
- OpenCode
- Claw Code
- antegravity

Do not treat those names as decoration.
Treat them as practical compatibility targets.

That means the repo should become stronger in areas like:
- setup clarity,
- installation guidance,
- wiring guidance,
- harness-specific operational notes,
- trust-model clarity,
- verification expectations,
- runtime behavior explanation,
- and overall operator usability.

The result should not merely mention those harnesses.
It should become more actually usable for them.

---

## Real Goal of This Work Session

Your goal is to push the repo forward in **real, verifiable, implementation-backed ways**.

You should focus on the next meaningful improvements, especially around:
- self-maintaining system behavior,
- runtime intelligence,
- drift resistance,
- stronger observability,
- clearer operator-facing state,
- and real multi-harness usability.

You are expected to make actual repository changes, not just propose them.

---

## Files You Must Inspect Early

At minimum, inspect these files before making major decisions:

Top-level:
- `README.md`
- `CHANGELOG.md`
- `artifacts/status/status-summary.txt`
- `IMPROVEMENT_PLAN.md`
- `SECURITY_MODEL.md`
- `MODULES.md`

Reference/status docs:
- `references/full-power-status.md`
- `references/runtime-autonomy-roadmap.md`
- `references/superiority-evidence.md`
- `references/upstream-sync.md`
- `references/parity-matrix.json`
- `references/parity-report.md`

Core scripts:
- `scripts/ecc-cli.sh`
- `scripts/status-summary.sh`
- `scripts/generate-status-artifact.sh`
- `scripts/check-status-artifact.sh`
- `scripts/check-status-docs.sh`
- `scripts/check-superiority-evidence.sh`
- `scripts/check-runtime-core.sh`
- `scripts/check-runtime-cli.sh`
- `scripts/check-config-integration.sh`
- `scripts/check-installation.sh`

Runtime files:
- inspect the files under `runtime/`, especially:
  - decision engine
  - risk scoring
  - workflow routing
  - action planning
  - project policy
  - session context
  - context discovery
  - policy store
  - promotion guidance
  - decision journal

Also inspect any files needed to understand:
- current install/setup behavior,
- current cross-tool wiring,
- current compatibility surfaces,
- current anti-drift coverage,
- and where docs/status/code may still drift apart.

---

## Required Working Method

Follow this sequence:

### Step 1. Audit honestly
- Run the repo’s current checks.
- Build a real model of the current state.
- Identify real issues, weak points, stale claims, drift risks, and usability gaps.

### Step 2. Preserve working behavior
- Do not casually break verified flows.
- If you refactor, preserve outputs or update the corresponding docs/checks/status truthfully.

### Step 3. Implement meaningful improvements
Focus on improvements that materially strengthen the repo, not cosmetic churn.

### Step 4. Verify what you changed
- Run targeted checks.
- Run broad checks when justified.
- Fix any failures you introduced.

### Step 5. Update docs and status honestly
If behavior changes, docs and status artifacts must reflect that truthfully.

---

## Priority Work Areas

You do not have to do everything below, but your work should hit meaningful items from these areas.

### Priority Area A: Strengthen Phase 4, Self-maintaining system
Improve the repo’s self-maintaining capabilities in concrete ways, for example:
- stronger status artifact generation,
- richer machine-readable metadata,
- clearer generated operational summaries,
- better anti-drift checks,
- tighter sync between README, status docs, generated evidence, and verification outputs,
- stronger repo-health snapshots,
- better generated or semi-generated status surfaces,
- improved maintainability of repo truth.

### Priority Area B: Strengthen runtime intelligence
Push the bounded runtime layer further in ways that create real value, such as:
- better risk scoring behavior,
- stronger workflow routing decisions,
- stronger action plans,
- clearer explanation output,
- better project-shape or tool-context handling,
- better policy lifecycle visibility,
- stronger operator-facing runtime state,
- tighter integration between runtime decisions and status/observability.

### Priority Area C: Improve real multi-harness usability
Make the project more truly usable for:
- Claude Code
- OpenClaw
- Codex
- OpenCode
- Claw Code
- antegravity

This may include:
- harness-specific setup guidance,
- compatibility notes,
- wiring guidance,
- operator instructions,
- explicit limitations,
- safer defaults,
- or checks/docs that make support claims more real.

If you claim a usability or compatibility improvement, back it with actual repo changes.

---

## What You Must Not Do

Do NOT:
- invent progress,
- rewrite history to sound better,
- claim unfinished work is complete,
- add aspirational prose with no implementation backing,
- weaken the conservative trust posture,
- silently broaden permissions,
- add low-value churn that does not improve real usability,
- or spend the session mostly writing plans without implementation.

Do not optimize for appearance.
Optimize for:
- correctness,
- truthfulness,
- usability,
- verification,
- maintainability,
- and bounded safety.

---

## Safety Requirement

The project intentionally keeps a conservative trust model.
Do not dilute that.

Avoid changes that:
- silently increase trust,
- auto-enable risky external behavior,
- bypass review boundaries,
- reduce payload safety,
- or weaken the hook/runtime safety model just to seem more autonomous.

Autonomy here must remain:
- bounded,
- inspectable,
- reviewable,
- and conservative by default.

---

## Verification Requirement

Before finishing, you must:
1. run relevant checks,
2. fix anything broken by your changes,
3. re-run verification,
4. ensure the repo ends in a stronger and cleaner state.

At minimum, use the repository’s own verification flow where appropriate, especially:
- `./scripts/ecc-cli.sh check`

Also run targeted checks relevant to the areas you touched.

---

## Documentation and Status Requirement

If you change behavior:
- update the relevant docs.

If you add a meaningful capability:
- reflect it in the correct status/evidence/reporting surfaces.

If you improve a generated or semi-generated artifact:
- regenerate it correctly.

If you discover stale or misleading claims:
- fix them honestly.

Always ask:
- should status output reflect this?
- should a check verify this?
- should docs explain this?
- should a generated artifact capture this?
- does this introduce a new drift risk?

---

## Definition of Success

A successful outcome means it is truthful to say that:
- Agent Runtime Guard is stronger than before,
- the self-maintaining system is stronger than before,
- the runtime/autonomy layer is stronger than before,
- the repo remains conservative and verifiable,
- docs/status/checks are more aligned than before,
- and practical usability across Claude Code, OpenClaw, Codex, OpenCode, Claw Code, and antegravity is more real than before.

---

## Final Output Expected From You

When you finish, provide a clear engineering summary that includes:
- what you changed,
- what issues you found,
- what you fixed,
- what new capability or improvement you added,
- what checks passed,
- and what remains as future work.

Separate clearly between:
- verified completed work,
- assumptions you validated,
- and future opportunities not yet implemented.

---

## Immediate Start Command

Start by auditing the repository honestly.
Then move quickly into implementation.
Do real work, preserve truth, and leave the repo better than you found it.
