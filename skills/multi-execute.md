# Skill: Multi-Execute

## Trigger

Command: `/multi-execute <plan>`

Use to execute a structured multi-agent plan produced by `/multi-plan`. Coordinates agent spawning per phase, collects and validates results, resolves conflicts, and produces a merged execution report.

Do not use without a plan. If no plan exists, run `/multi-plan` first.

## Process

### 1. Load the plan

Accept the plan as:
- Direct output from `/multi-plan` (preferred)
- A user-provided task breakdown in the same phased format

Before executing, validate the plan:
- Every subtask has a named agent, a bounded task, and defined inputs
- Dependencies between phases are explicit
- No subtask writes to a file another parallel subtask reads (file conflict check)
- Any irreversible or externally visible operations are flagged and approved by Ahmed

Do not proceed if validation fails. Surface the issue and wait for a corrected plan.

### 2. Execute phases in order

For each phase in the plan:

1. Spawn all agents in the phase in parallel using the Agent tool
2. Provide each agent only the context it needs (not the full codebase)
3. Wait for all agents in the phase to complete before starting the next phase
4. Pass each phase's outputs as inputs to dependent phases

**Spawning pattern:**
```
Agent(
  agent="architect",
  task="Design the DB schema for user authentication per the API contract in [contract.md]",
  context=[contract.md, existing migrations/]
)
```

### 3. Validate outputs before passing downstream

After each phase completes, before starting the next:
- Check that each agent produced output (not empty, not malformed)
- Check that outputs are consistent with each other (no contradictions between parallel agents)
- Check that outputs satisfy the acceptance criteria defined in the plan

If any output fails validation: retry that agent once with additional context. If it fails again, stop and escalate to Ahmed.

### 4. Resolve conflicts

If two parallel agents produce conflicting outputs:

| Conflict type | Resolution |
|--------------|-----------|
| Different schema designs | Escalate to `architect` — it decides, not the orchestrator |
| Different security recommendations | Both findings are included; Ahmed decides which to apply |
| Different code quality suggestions | `code-reviewer` output takes precedence; flag the disagreement |
| Contradictory test assertions | Stop — surface to Ahmed, do not proceed with contradictory tests |
| Different performance recommendations | Include both; flag trade-offs explicitly |

Never silently resolve a conflict. Always surface it with both positions stated.

### 5. File write safety

- No agent writes files directly during execution
- All proposed file changes go to a **review queue** — a list of diffs, not applied writes
- Ahmed reviews and approves the merged result before any files are written
- If two agents propose changes to the same file, produce a merged diff and flag the overlap for manual review

### 6. Handle agent failures

| Failure | Response |
|---------|---------|
| Agent returns no output | Retry once with more explicit task framing |
| Agent returns malformed output | Retry once; if it fails again, escalate |
| Agent flags a CRITICAL issue | Stop execution; surface to Ahmed; do not continue |
| Agent times out | Surface the timeout; do not silently skip |
| Two retries both fail | Escalate to Ahmed with the agent name, task, and context provided |

### 7. Produce the merged execution report

After all phases complete, produce a structured report:

```
Execution Report
================
Goal: <goal from plan>
Status: COMPLETE | PARTIAL | BLOCKED

Phase 1 — [parallel]
  architect:        DONE — Designed user table schema (3 columns, 1 FK)
  planner:          DONE — API contract: POST /auth/login, POST /auth/register

Phase 2 — [sequential]
  tdd-guide:        DONE — 12 failing tests written; 0 passing (expected)

Phase 3 — [parallel]
  code-reviewer:    DONE — 2 non-critical findings (see findings below)
  security-reviewer: DONE — 1 CRITICAL finding: password hashed with MD5

Findings:
  [CRITICAL] security-reviewer: MD5 used for password hashing — must fix before merge
  [MINOR] code-reviewer: Missing docstrings on 3 functions
  [INFO] code-reviewer: Consider extracting auth logic to a service class

Proposed file changes (pending Ahmed's approval):
  - models/user.py        (new file)
  - migrations/0042_add_users.py  (new file)
  - tests/test_auth.py    (new file)
  - api/auth.py           (modified)

Agent conflicts: NONE
Blocked on: Ahmed must resolve the CRITICAL security finding before files are written
```

## Example: 3 Parallel Agents in One Phase

**Plan input (Phase 3):**
```
Phase 3 (parallel, requires Phase 2):
  → agent: code-reviewer      task: "Review auth.py implementation"
  → agent: security-reviewer  task: "Security audit of auth flow"
  → agent: typescript-reviewer task: "Review auth API client types"
```

**Execution:**
1. Spawn all three agents simultaneously
2. Each agent receives only its relevant context slice
3. Wait for all three to return
4. Collect outputs — check for contradictions
5. Merge findings into a single list, ranked by severity
6. Surface conflicts (if any) before proceeding to Phase 4

## Safe Behavior

- No files are written without Ahmed's explicit approval.
- Every agent failure is surfaced — nothing is silently skipped.
- Conflicts between agents are always flagged, never silently resolved.
- CRITICAL findings stop execution immediately.
- The execution report is the audit trail — it is surfaced to Ahmed after every run.
