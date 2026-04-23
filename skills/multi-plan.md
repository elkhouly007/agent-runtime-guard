# Skill: Multi-Plan

## Trigger

Command: `/multi-plan "task description"`

Use when a task is complex enough that no single agent can handle it end-to-end without context overflow, conflicting concerns, or domain gaps. Produces a structured execution plan consumed by `/multi-execute`.

Do not use for single-domain tasks, small changes, or tasks that can be handed directly to one specialist agent.

## Process

### 1. Analyze the task

Read the task description and extract:
- The **goal** (what done looks like)
- **Domain boundaries** (frontend, backend, database, infra, security, docs)
- **Risk surface** (irreversible operations, data exposure, external side effects)
- **Constraints** (deadline, must-avoid actions, known unknowns)

### 2. Identify subtasks

Break the goal into subtasks that are:
- **Bounded** — each subtask has a clear input, output, and acceptance criterion
- **Assignable** — each maps to exactly one specialist agent
- **Sized** — each fits in a single agent context window (no subtask spans the entire codebase)

Flag any subtask that is ambiguous or requires human clarification before proceeding.

### 3. Classify dependencies

For each pair of subtasks, determine:

| Relationship | Execution |
|-------------|-----------|
| No dependency between them | Parallel — run in the same phase |
| B needs A's output as input | Sequential — A in Phase N, B in Phase N+1 |
| B validates A's output | Sequential — A before B |
| Both need the same read-only context | Parallel — safe to run together |
| Both would write the same files | Sequential — never parallel |

Maximum recommended parallel agents per phase: **3**. Beyond this, result synthesis degrades and context budget pressure increases.

### 4. Assign agents

| Need | Agent |
|------|-------|
| High-level planning | `planner` |
| System / data model design | `architect` |
| Test-driven development | `tdd-guide` |
| General code quality | `code-reviewer` |
| Security vulnerabilities | `security-reviewer` |
| TypeScript / frontend | `typescript-reviewer` |
| Python | `python-reviewer` |
| Go | `go-reviewer` |
| Database schema / queries | `database-reviewer` |
| Performance bottlenecks | `performance-optimizer` |
| Codebase exploration | `code-explorer` |
| Accessibility | `a11y-architect` |
| Documentation | `doc-updater` |
| Batch / iteration loops | `loop-operator` |

### 5. Estimate context requirements

For each subtask, estimate context budget:
- **Small** — single file or function, no cross-cutting concerns (<10k tokens)
- **Medium** — a module or feature slice (10k–50k tokens)
- **Large** — cross-cutting feature, multiple modules (50k–100k tokens)

If any subtask is estimated **Large**, split it further. No agent should receive the full codebase as context.

### 6. Output the plan

Produce a structured plan in this exact format:

```
Goal: <one-sentence goal>

Phase 1 (parallel):
  → agent: planner        task: "Define API contracts for X"
  → agent: architect      task: "Design DB schema for X"

Phase 2 (sequential, requires Phase 1):
  → agent: tdd-guide      task: "Write failing tests based on Phase 1 contracts"

Phase 3 (parallel, requires Phase 2):
  → agent: code-reviewer  task: "Review implementation against contracts"
  → agent: security-reviewer  task: "Security audit of Phase 2 implementation"

Risk points:
  - Phase 2: schema migration is irreversible — requires Ahmed's approval before apply
  - Phase 3: security-reviewer may block merge if critical findings

Context notes:
  - Phase 1 agents: provide requirements doc + existing models only
  - Phase 2 agent: provide Phase 1 outputs + test scaffolding only
  - Phase 3 agents: provide implementation diff + Phase 1 contracts only
```

### 7. Delegate for execution

Hand the plan to `/multi-execute` or surface it to Ahmed for approval if any phase involves:
- Irreversible operations (migrations, deletions, publishes)
- External side effects (API calls, emails, payments)
- Sensitive data handling

## Decision Table: Parallelize vs. Serialize

| Situation | Decision |
|-----------|---------|
| Two agents read the same files, write nothing | Parallel |
| Agent B needs Agent A's output as its input | Sequential |
| Two agents write to different files | Parallel |
| Two agents write to the same file | Sequential — never parallel |
| One agent does security review of another's output | Sequential |
| Two independent language reviews | Parallel |
| Schema design + test writing | Sequential (schema first) |
| Code review + security review of the same diff | Parallel |

## Handling Phase Failures

| Failure | Response |
|---------|---------|
| Agent returns empty or malformed output | Retry once with additional context; escalate if it fails again |
| Agent output contradicts another agent's output | Do not proceed — surface conflict, assign `architect` to resolve |
| Agent flags a CRITICAL finding | Stop the plan; escalate to Ahmed before continuing |
| Phase 1 output is insufficient for Phase 2 | Re-run Phase 1 with a narrower, more specific task |
| Context budget exceeded | Split the failing subtask into two smaller subtasks |

## Safe Behavior

- Planning is read-only. No files are written during `/multi-plan`.
- High-risk subtasks are identified and flagged before execution begins.
- Ahmed approves before any phase that writes, migrates, deploys, or publishes.
- The plan document is the record of intent — it is surfaced to Ahmed before execution starts.
