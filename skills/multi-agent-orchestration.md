# Skill: Multi-Agent Orchestration

## Trigger

Use when a task is too large or multi-dimensional for a single agent — e.g., implementing a feature that requires planning, code generation across multiple files, review, and test writing in parallel or in sequence.

## Patterns

### /multi-plan

Break a large requirement into parallel sub-tasks before implementation.

**Process:**
1. Read the requirement and identify independent work streams (e.g., API layer, data model, frontend component, tests).
2. For each stream, define:
   - Input: what the sub-agent needs to know
   - Output: what it must produce
   - Dependencies: which streams must complete first
3. Represent as a dependency graph — sequential where there are dependencies, parallel otherwise.
4. Produce a plan document with: task list, agent assignments, execution order, and acceptance criteria per task.

**Example plan structure:**
```
Phase 1 (parallel):
  - [architect] Design data model for feature X
  - [planner] Draft API contract for feature X

Phase 2 (depends on Phase 1, parallel):
  - [python-reviewer] Implement model layer
  - [typescript-reviewer] Implement API client

Phase 3 (depends on Phase 2):
  - [tdd-guide] Write tests for model + API client
  - [security-reviewer] Review auth and data exposure
```

### /multi-execute

Execute a multi-plan — spawn sub-agents per phase, collect results, and synthesize.

**Process:**
1. Read the plan produced by `/multi-plan` (or a user-provided task breakdown).
2. For each phase:
   a. Spawn sub-agents for all tasks in the phase (parallel if no inter-phase dependency).
   b. Wait for all tasks in the phase to complete before starting the next.
   c. Pass outputs from completed tasks as inputs to dependent tasks.
3. After all phases complete: synthesize a final summary — what was built, what changed, what to verify.

**Spawning pattern:**
```
Agent(task="Implement the User model per the schema in plan.md section 2",
      agent=python-reviewer,
      context=[plan.md, existing models/])
```

### Orchestrator Safety Rules

- **Never spawn an agent without a clear, bounded task.** Vague tasks produce garbage output.
- **Pass only the context each sub-agent needs** — do not flood sub-agents with the entire codebase.
- **Collect and validate outputs** before passing them downstream — a bad output from Phase 1 poisons Phase 2.
- **Do not spawn more than 5 sub-agents in parallel** — beyond this, context management and result synthesis degrade.
- **Log what each sub-agent was asked to do and what it produced** — the orchestrator is responsible for traceability.

## Output Format

### /multi-plan output
- Phased task list with: task name, assigned agent, inputs, expected output, dependencies.
- Dependency graph (text or mermaid diagram).
- Estimated risk points (tasks likely to require rework).

### /multi-execute output
- Per-phase completion status.
- Per-task summary: what was produced, any issues encountered.
- Final synthesis: overall status, files changed, what to test manually.

## When NOT to Use

- Single-language, single-file changes — one agent handles it.
- Tasks where the output of each step is unknowable until the previous step completes — use sequential, not parallel.
- Exploratory spikes — use a single `code-explorer` or `architect` first to reduce uncertainty before orchestrating.
