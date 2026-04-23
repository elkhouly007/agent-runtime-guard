# Agent Runtime Guard — Parity to Superiority Plan

_Last updated: 2026-04-23_

This plan replaces vague “improve the repo” work with a concrete path from the **current safe-plus state** to **upstream parity or better**.

It is based on actual comparison against the upstream reference (`affaan-m/everything-claude-code`) plus local verification runs in this repository.

---

## North Star

We are not aiming for a blind 1:1 mirror.
We are aiming for:

1. **Upstream parity on useful power**
2. **Stronger safety and verification than upstream**
3. **Cleaner install and wiring story than upstream**
4. **A truth-based status system** where docs match reality

Success means:
- the repository can credibly claim **same practical power as upstream or higher**;
- that claim is backed by **file coverage**, **runtime verification**, and **accurate docs**;
- all important gaps are either closed or intentionally documented.

---

## Current Baseline

### Structural baseline vs upstream

- **Agents**
  - Upstream: 38
  - Current: 48
  - Status: **all upstream agents covered, plus 10 extras**

- **Rules**
  - Upstream: 87
  - Current: 50
  - Overlap: 46
  - Gap: **41 upstream rule files not yet represented**

- **Skills**
  - Upstream: 156
  - Current: 129
  - Overlap: 86
  - Gap: **70 upstream skills not yet represented**

- **Verification**
  - Fixtures: strong
  - Integration smoke: passing
  - Audit/smoke: not yet clean because of **false positives** and **over-broad scanners**

### Meaning of the baseline

The project is already strong, but it is **not yet honest to describe it as full parity**.
The fastest path is:

1. fix verification truthfulness,
2. build a formal parity tracker,
3. import or rewrite the highest-value missing upstream rules/skills,
4. then add superiority layers on top.

---

## Execution Strategy

We will move through **4 gates**.
Each gate has a clear deliverable and acceptance criteria.

### Gate 1 — Truth and Verification
Goal: make the repo tell the truth about itself and pass cleanly for the right reasons.

### Gate 2 — Upstream Parity Coverage
Goal: close the real functional/content gaps against upstream.

### Gate 3 — Runtime Applicability
Goal: ensure the repo is not only rich on disk, but also actually installable, wireable, and usable across target tools.

### Gate 4 — Superiority Layer
Goal: exceed upstream with safer behavior, better observability, and more reliable operations.

---

## Phase 1 — Fix Truthfulness and Verification

### Why this phase comes first
There is no point claiming parity while:
- `audit-local.sh` fails on documentation text,
- `audit-examples.sh` flags explanatory prose as if it were dangerous runtime content,
- `smoke-test.sh` inherits those failures,
- status files are more optimistic than the actual repository state.

### Work items

#### 1.1 Build a formal parity tracker
Create a machine-readable and human-readable tracker for:
- all upstream agents,
- all upstream rules,
- all upstream skills,
- decision per item: `adopted`, `adapted`, `replaced`, `deferred`, `rejected`.

Suggested files:
- `references/parity-matrix.json`
- `references/parity-report.md`

#### 1.2 Tighten `audit-local.sh`
Refine the scanner so it distinguishes between:
- risky runtime code,
- hook pattern lists,
- documentation describing blocked behavior,
- intentionally safe references.

Expected outcome:
- docs describing `rm -rf`, `curl | sh`, `npx -y`, or `auto-approve` do **not** fail the audit by default;
- actual executable or live wiring risks still fail.

#### 1.3 Tighten `audit-examples.sh`
Refine prose scanning so it does not flag:
- policy text discussing bad examples,
- evaluation instructions,
- historical notes,
- quoted anti-patterns.

It should only fail on:
- unsafe prose that reads like an instruction,
- dangerous commands inside GOOD examples,
- accidental copy-paste of risky guidance.

#### 1.4 Make status reporting evidence-based
Update:
- `references/full-power-status.md`
- `references/per-tool-apply-status.md`
- `README.md` if needed

So they reflect:
- actual counts,
- actual parity state,
- actual verification state.

### Acceptance criteria
- `bash scripts/audit-local.sh` passes cleanly
- `bash scripts/audit-examples.sh` passes cleanly or fails only on a true issue
- `bash scripts/smoke-test.sh` passes cleanly
- parity tracker exists and covers agents/rules/skills
- docs no longer overstate parity

---

## Phase 2 — Close the Real Upstream Gaps

### Priority principle
Do **not** import everything blindly.
Close gaps in this order:

1. runtime-critical items,
2. frequently used rules/skills,
3. domain expansions,
4. low-value or niche tail items.

### 2.1 Rules parity wave
Current real gap: **41 upstream rule files** missing.

#### Priority A — high-value missing rule families
- `common/code-review.md`
- `common/hooks.md`
- `web/patterns.md`
- `web/performance.md`
- language `patterns.md` where missing
- high-signal hook-oriented guidance where still useful in safe-plus form

#### Priority B — language coverage gaps
- full `dart/*`
- missing `patterns.md` across languages
- missing `hooks.md` coverage, where needed in adapted safe-plus form

#### Priority C — localization tail
- `zh/*` only if strategically useful, otherwise mark explicitly deferred

### 2.2 Skills parity wave
Current real gap: **70 upstream skills** missing.

#### Priority A — practical engineering skills
Import/adapt highest-value missing skills first, such as:
- `agent-eval`
- `ai-regression-testing`
- `android-clean-architecture`
- `architecture-decision-records`
- `browser-qa`
- `codebase-onboarding`
- `dotnet-patterns`
- `kotlin-patterns`
- `rust-patterns`
- `swiftui-patterns`
- `token-budget-advisor`
- `repo-scan`
- `quality-nonconformance`

#### Priority B — domain-specific skills
Adopt only if they add real practical power and can be safely supported.
Examples:
- healthcare-specific tracks
- enterprise-agent ops
- Jira integrations
- open source pipeline flows

#### Priority C — niche or low-value tail
Mark clearly as deferred or intentionally excluded.

### 2.3 Define replacement equivalence
Some missing upstream items may already be functionally covered by our custom files.
That is acceptable only if the parity matrix records them as:
- `replaced_by: <our-file>`
- with short rationale.

### Acceptance criteria
- all upstream agents accounted for as covered or intentionally superseded
- all upstream rules accounted for in the parity matrix
- all upstream skills accounted for in the parity matrix
- high-value missing rules imported/adapted
- high-value missing skills imported/adapted
- remaining unimported items are explicitly justified, not invisible

---

## Phase 3 — Ensure Runtime Power, Not Just File Count

### Why this matters
Parity is meaningless if files exist but:
- installation is partial,
- hook wiring is brittle,
- apply-status claims do not match reality,
- project-local activation is weak.

### Work items

#### 3.1 Finish installation correctness
Strengthen:
- `scripts/install-local.sh`
- `scripts/generate-config.sh`
- `scripts/wire-hooks.sh`
- `scripts/ecc-cli.sh`

Ensure the kit can install:
- minimal profile,
- language-targeted profile,
- full profile,
- tool-specific wiring snippets.

#### 3.2 Add coverage-aware install profiles
Profiles should map cleanly to content families:
- `minimal`
- `rules`
- `agents`
- `skills`
- `full`
- optional language packs if justified

#### 3.3 Make apply-status generated, not hand-waved
Generate apply-status from actual config/wiring evidence where possible.
If generation is not feasible, add a verification helper that validates the claims.

#### 3.4 Expand executable verification
Current fixture coverage is good, but parity work needs more:
- hook tests,
- install tests,
- config generation tests,
- profile coverage tests,
- parity consistency tests.

### Acceptance criteria
- fresh install can produce an actually usable project-local kit
- hook wiring has no silent placeholder failures
- install profiles are testable and documented
- apply-status is validated against real files/config
- verification covers install, hook, payload, and parity logic

---

## Phase 4 — Go Beyond Upstream

This phase starts **after parity is honestly achieved**.

### 4.1 Stronger safety than upstream
- better payload classification and redaction
- stronger prompt-injection resistance
- explicit outbound review boundaries
- clearer approval model

### 4.2 Better observability than upstream
- hook event logging
- parity drift checks
- version drift checks
- staleness reporting for content and policies

### 4.3 Better operator UX than upstream
- cleaner setup wizard
- better routing/indexes
- tool-specific quickstarts
- smaller cognitive load for first-time adopters

### 4.4 Better trust model than upstream
- safe reviewed packs
- explicit module classification
- documented outbound behavior per integration

### Acceptance criteria
At least one measurable superiority claim is backed by evidence in each category:
- safety,
- verification,
- installability,
- observability,
- operator UX.

---

## Concrete Backlog by Priority

## P0 — Immediate
1. Create parity matrix and parity report
2. Fix `audit-local.sh` false positives
3. Fix `audit-examples.sh` false positives
4. Update status docs to match reality

## P1 — High
5. Import/adapt highest-value missing rules
6. Import/adapt highest-value missing skills
7. Define replacement mappings for our custom equivalents
8. Add parity consistency checks

## P2 — Medium
9. Strengthen install profiles and activation config
10. Improve apply-status validation
11. Expand executable verification for hooks/install/config
12. Clean up count drift in docs and summaries

## P3 — Superiority
13. Add observability and drift detection
14. Add staleness governance
15. Add operator-experience improvements
16. Add any net-new safe-plus capability not present upstream

---

## Recommended Work Sequence

### Sprint A — Truth first
- parity matrix
- parity report
- audit cleanup
- status doc cleanup

### Sprint B — Rules parity
- import/adapt missing high-value rules
- mark deferred low-value rules
- verify parity report

### Sprint C — Skills parity
- import/adapt missing high-value skills
- map our custom replacements
- verify parity report

### Sprint D — Runtime activation
- install correctness
- apply-status validation
- hook/config/install tests

### Sprint E — Superiority layer
- observability
- drift detection
- staleness checks
- stronger UX and safety features

---

## Definition of Done

We may claim “same power as upstream or better” only when all of the following are true:

1. **Parity accounting complete**
   - every upstream agent/rule/skill is accounted for

2. **No invisible gaps**
   - anything missing is explicitly marked replaced, deferred, or rejected

3. **Verification clean**
   - audit, smoke, fixtures, and integration checks reflect real status

4. **Docs are honest**
   - no inflated counts, no optimistic status claims unsupported by evidence

5. **Runtime usability proven**
   - install and wiring work cleanly for intended tool targets

6. **Superiority is evidenced**
   - at least one category where safe-plus clearly exceeds upstream and proves it

---

## Progress Update

As of 2026-04-23 (v1.0.0):

- **Sprint A, Truth first**: complete
- **Sprint B, Rules parity**: complete
- **Sprint C, Skills parity**: complete
- **Sprint D, Runtime activation**: complete
- **Sprint E, Superiority layer**: complete
- **Sprint R2, Runtime autonomy follow-on**: complete
- **Sprint R3, Routing and workflow fidelity**: complete (v1.0.0)

Current measured state:
- agents: full upstream parity achieved (48 agents, including 10 ECC-only)
- rules: full upstream parity achieved (91 rules)
- skills: full upstream parity achieved (199 skills)
- verification: 18/18 check groups passing (added OWASP coverage + runtime bench in v1.0.0)
- runtime autonomy: auto-allow-once (B.1), session-trajectory routing (B.2), kill switch (C.3) implemented
- community-informed additions: OWASP Agentic Top 10 coverage doc, path-sensitivity classifier, structured JSONL audit trail, latency bench
- CI: all 24 check steps in `.github/workflows/check.yml` (previously only 8 were wired); 20 ecc-cli check groups locally
- Windows isolation: `ECC_STATE_DIR` override in all three runtime state modules

## Final Outcome

Agent Runtime Guard now meets and exceeds the original goal:

1. **Full upstream practical power parity** across agents, rules, and skills
2. **Higher safety and trust clarity** through the Safe-Plus security model
3. **Higher runtime confidence** through executable verification beyond file-count parity
4. **Lower documentation drift** through semi-generated status artifacts and sync checks
5. **Bounded runtime autonomy** with inspectable policy lifecycle, trajectory routing, and kill switch

The honest current description is now:

> **Agent Runtime Guard has full upstream content parity, plus ECC-only extensions, and verified runtime/usability/superiority layers that put it above upstream in measurable ways.**

## Immediate Next Action

The parity-to-superiority project and Sprint R3 are complete (v1.0.0).

Any next work should be treated as a new improvement cycle, for example:
1. adding more fixture-style checks for new tool integrations,
2. extending semi-generated status to additional docs if they appear,
3. evolving ECC-only capabilities beyond the upstream baseline,
4. adding Ed25519 inter-agent identity (explicitly deferred in OWASP coverage doc — single-host scope).
