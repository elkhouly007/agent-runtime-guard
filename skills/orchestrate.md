# Skill: Orchestrate

## Trigger

Use when a task:
- Requires coordination across 3 or more agents
- Has multiple independent subtasks that can run in parallel
- Is too complex for a single agent to handle end-to-end
- Needs a chief-of-staff layer to manage sequence, dependencies, and synthesis

Do not use for single-agent tasks — delegate directly instead.

## Process

### 1. Decompose the task
Delegate task analysis to `chief-of-staff` agent. Provide:
- The goal in plain language
- Constraints (deadline, risk tolerance, must-avoid actions)
- The full context (relevant files, recent changes, user requirements)

Decomposition output should include:
- Subtask list with clear, bounded goals
- Dependencies between subtasks (which must complete before others start)
- Parallel vs. sequential order
- Risk level per subtask

### 2. Classify execution order

**Independent → run in parallel:**
- Static analysis + dependency audit can run simultaneously
- Multiple language reviews can run simultaneously
- Documentation generation and test writing can run simultaneously

**Sequential → run in order:**
- Schema migration before API changes
- Plan before implementation
- Tests before refactoring
- Security review before deployment

### 3. Assign agents

| Need | Agent |
|------|-------|
| Plan before coding | `planner` |
| System design / architecture | `architect` |
| General code quality | `code-reviewer` |
| Security vulnerabilities | `security-reviewer` |
| TypeScript / JavaScript | `typescript-reviewer` |
| Python | `python-reviewer` |
| Go | `go-reviewer` |
| Rust | `rust-reviewer` |
| Java / Kotlin | `java-reviewer`, `kotlin-reviewer` |
| Database changes | `database-reviewer` |
| Build failures | `build-error-resolver` |
| Test-driven development | `tdd-guide` |
| Performance bottlenecks | `performance-optimizer` |
| Explore / understand codebase | `code-explorer` |
| Batch / iterate operations | `loop-operator` |
| Documentation updates | `doc-updater` |
| Accessibility | `a11y-architect` |
| Open-source intake | `opensource-sanitizer`, `opensource-forker` |

### 4. Flag high-risk subtasks before executing
Before executing any subtask that is:
- Irreversible (delete, drop table, archive)
- Externally visible (push, publish, send email)
- Involves personal or confidential data leaving the system

→ Surface it explicitly. Get Ahmed's confirmation before proceeding.

### 5. Execute and collect results
- Report each subtask result as it completes.
- Do not silently skip a subtask that fails — surface it and pause.
- If a subtask fails, decide: retry, reassign, or escalate. Do not just continue past a failure.

### 6. Synthesize
Combine subtask outputs into a single coherent result:
- Ranked findings (if reviewing)
- Unified plan (if planning)
- Summary report with agent attribution

## Orchestration Patterns

### Sequential Pipeline
```
plan-feature → implement (TDD) → code-review → security-review → merge
```

### Parallel Review
```
typescript-reviewer ─┐
security-reviewer   ─┼─→ synthesize → verdict
database-reviewer   ─┘
```

### Iterative Loop
```
build → [FAIL] → build-error-resolver → fix → build → [PASS] → test → done
```

### Full Feature Delivery
```
planner + architect (parallel)
  → implement with tdd-guide
  → code-reviewer + security-reviewer (parallel)
  → performance-optimizer (if needed)
  → doc-updater
  → merge
```

## Failure Handling

| Failure type | Response |
|-------------|----------|
| Agent returns low confidence | Add a second agent as a check |
| Agent finds CRITICAL issue | Stop pipeline, escalate to Ahmed |
| Subtask produces no output | Re-run with more context, then escalate |
| Subtasks conflict | Escalate conflict to `architect` for resolution |

## Safe Behavior

- Planning phase is read-only — no code written during decomposition.
- High-risk subtasks are identified before execution begins.
- Each subtask result is reported — no silent skips.
- If any subtask fails, the failure is surfaced before the next subtask starts.
- Orchestration does not approve its own output.
