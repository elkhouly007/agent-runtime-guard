# Skill: Multi-Workflow

## Trigger

Command: `/multi-workflow "goal"`

Use for complex goals that span multiple domains — frontend, backend, database, infrastructure, security, documentation — where no single specialist agent is sufficient and no pre-built workflow (like `/multi-backend` or `/multi-frontend`) covers the full scope.

This is the general-purpose multi-agent orchestration skill. It composes a custom agent team, defines phases, and executes via the `/multi-execute` pattern.

## When NOT to Use

Do not use `/multi-workflow` for:
- Single-domain tasks — delegate to the appropriate specialist or use `/multi-backend` / `/multi-frontend`
- Small changes (single file, single function) — one agent is faster and cheaper
- Exploratory spikes — use a single `code-explorer` or `architect` first to reduce uncertainty before orchestrating
- Tasks where the next step is unknowable until the previous step completes — sequence tightly, do not try to parallelize prematurely

Context budget warning: each agent in a multi-workflow runs in its own separate context window. A 5-agent workflow consumes 5 context windows. Keep the team lean. 2–5 agents is the effective range.

## Process

### 1. Analyze the goal

Read the goal and identify which domains are involved:

| Domain | Indicator |
|--------|-----------|
| Frontend | UI components, routing, state management, CSS, accessibility |
| Backend | API endpoints, services, business logic, background jobs |
| Database | Schema changes, migrations, query optimization, indexes |
| Infrastructure | Deployment config, environment variables, Docker, CI/CD |
| Security | Auth, authorization, data exposure, dependency vulnerabilities |
| Documentation | API docs, README updates, architecture diagrams, changelogs |

### 2. Select the agent team

Based on domains identified, select 2–5 agents. Use the decision table below as a starting point, then adjust for the specific goal.

**Decision Table — Recommended Teams by Goal Type:**

| Goal type | Recommended team |
|-----------|-----------------|
| Full feature (end-to-end, frontend + backend + DB) | `planner` + `architect` + `tdd-guide` + `security-reviewer` + `code-reviewer` |
| Bug investigation | `code-explorer` + `silent-failure-hunter` + `code-reviewer` |
| Performance audit | `performance-optimizer` + `database-reviewer` + `code-reviewer` |
| Security hardening | `security-reviewer` + `code-reviewer` + `healthcare-reviewer` (if medical data involved) |
| Refactor | `refactor-cleaner` + `code-reviewer` + `tdd-guide` |
| API integration (external service) | `architect` + `security-reviewer` + `code-reviewer` |
| Database optimization | `database-reviewer` + `performance-optimizer` |
| Documentation overhaul | `doc-updater` + `code-explorer` |
| Dependency upgrade | `code-reviewer` + `security-reviewer` |
| Accessibility remediation | `a11y-architect` + `code-reviewer` |

If the goal type is not in this table, compose a custom team:
- Start with `planner` or `architect` if the path forward is unclear
- Add domain specialists for each affected area
- Add `code-reviewer` as the final gate for all implementation work
- Add `security-reviewer` if any auth, data, or external API is touched
- Cap at 5 agents total

### 3. Define phases

Structure the workflow using the same phasing rules as `/multi-plan`:
- Independent tasks run in the same phase (parallel)
- Tasks with dependencies run in separate phases (sequential)
- No more than 3 agents per phase in parallel
- Each phase output is validated before the next phase starts

**Standard phase templates:**

**Full feature (end-to-end):**
```
Phase 1 (sequential): planner — scope and requirements
Phase 2 (parallel):   architect (backend design) + architect (frontend design)
Phase 3 (sequential): tdd-guide — failing tests for both layers
Phase 4 (parallel):   implementation + security-reviewer
Phase 5 (parallel):   database-reviewer + code-reviewer
```

**Bug investigation:**
```
Phase 1 (parallel):   code-explorer (trace the bug) + silent-failure-hunter (find hidden failures)
Phase 2 (sequential): code-reviewer — root cause analysis and fix proposal
```

**Performance audit:**
```
Phase 1 (parallel):   performance-optimizer (application layer) + database-reviewer (query layer)
Phase 2 (sequential): code-reviewer — prioritized remediation plan
```

### 4. Execute

Run each phase using the `/multi-execute` pattern:
- Spawn phase agents in parallel
- Validate outputs before advancing
- Surface conflicts to Ahmed — never silently resolve them
- Collect all findings into the unified report

### 5. Final synthesis

After all phases complete, assign one agent (typically `code-reviewer` or `planner`) to:
- Read all phase outputs
- Produce a single unified report: what was found, what was built, what to verify, what is still open
- Rank all findings by severity
- Identify any gaps where no agent covered a concern

The synthesis agent does not re-do work — it reads and summarizes only.

## Composing Custom Teams

When the decision table does not match your goal exactly:

1. List every domain touched by the goal
2. Pick one specialist per domain (from the agent registry in `orchestrate.md`)
3. Add `code-reviewer` as the final gate (always)
4. Add `security-reviewer` if any of these are true:
   - The feature handles user data
   - The feature calls an external API
   - The feature adds or modifies authentication or authorization
5. If the goal is ambiguous, add `planner` as Phase 1 before any specialist runs
6. If the goal crosses a technology boundary (e.g., frontend + backend), add `architect` before implementation

**Context budget rule:** Each agent in the team consumes one full context window. A 5-agent team = 5 context windows. If cost or latency is a concern, reduce the team size and accept narrower coverage.

## Context Budget Warnings

| Team size | Cost | Coverage | When to use |
|-----------|------|---------|-------------|
| 2 agents | Low | Narrow | Single-domain with one review pass |
| 3 agents | Medium | Good | Most feature work |
| 4 agents | High | Broad | Cross-domain features with security risk |
| 5 agents | Very high | Full | End-to-end features or audits |
| 6+ agents | Excessive | Diminishing returns | Do not use — split the goal instead |

If the goal is too large for 5 agents without each agent being overloaded, split the goal into two separate `/multi-workflow` runs.

## Unified Report Format

```
Multi-Workflow Report
=====================
Goal: <goal>
Team: <agent list>
Status: COMPLETE | PARTIAL | BLOCKED

Phase Summary:
  Phase 1 — planner:           DONE — Scoped to 3 endpoints, 2 DB tables, no infra changes
  Phase 2 — architect (BE):    DONE — Schema and API contract defined
  Phase 2 — architect (FE):    DONE — Component API and state shape defined
  Phase 3 — tdd-guide:         DONE — 34 failing tests (expected)
  Phase 4 — implementation:    DONE — All 34 tests now passing
  Phase 4 — security-reviewer: DONE — 1 CRITICAL, 2 MAJOR findings
  Phase 5 — database-reviewer: DONE — 1 MAJOR finding (missing index)
  Phase 5 — code-reviewer:     DONE — 3 MINOR findings

Findings (ranked by severity):
  [CRITICAL] security-reviewer: JWT secret loaded from environment without validation — can be empty string
  [MAJOR]    security-reviewer: CORS policy allows all origins on /api routes
  [MAJOR]    database-reviewer: Missing index on events.user_id — full table scan on every request
  [MINOR]    code-reviewer: 3 functions missing error handling for null returns
  [MINOR]    code-reviewer: Inconsistent naming convention in service layer
  [MINOR]    code-reviewer: Magic number 3600 should be a named constant

Open questions for Ahmed:
  - Should the CORS policy allow the staging origin only, or all non-production origins?

Proposed changes (pending Ahmed's approval):
  - 12 files modified, 4 files created
  - 1 migration file (new index on events.user_id)

Agent conflicts: NONE
Synthesis by: code-reviewer
```

## Safe Behavior

- Phase 1 is always read-only if it involves planning or exploration.
- No files are written until Ahmed reviews and approves the unified report.
- CRITICAL findings block all writes regardless of which agent produced them.
- The unified report is the audit trail — it is surfaced to Ahmed after every run.
- If the goal expands during execution (scope creep discovered), stop and surface to Ahmed before continuing.
