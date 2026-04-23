# Skill: Strategic Compact

## Trigger

Use when approaching context window limits in a long session, when resuming work after a break, or when handing off work to another agent/session. Produces a compact, structured summary of the current state that lets the next context slot in without re-reading the full conversation.

## Process

### 1. Capture Current State

Extract and organize:

- **Goal:** what are we trying to accomplish? (1-2 sentences)
- **Progress:** what has been completed so far? (bulleted, specific)
- **Current position:** where exactly are we in the work right now?
- **Immediate next action:** the single next step to take
- **Open decisions:** anything we were mid-thought on or undecided
- **Constraints and context:** key facts that aren't obvious from the code (deadlines, dependencies, gotchas discovered)

### 2. State Snapshot

```markdown
## Strategic Compact — [date/time]

### Goal
[1-2 sentence statement of what we're trying to accomplish]

### Completed
- [specific item 1]
- [specific item 2]
- [specific item 3]

### Current Position
[Exactly where we stopped — file, function, step in a process]

### Next Action
[The single immediate next step — specific enough to act on without re-reading]

### Open Decisions
- [decision 1]: [options being considered]
- [decision 2]: [constraint or blocker]

### Key Context
- [non-obvious fact 1]
- [non-obvious fact 2]
- [relevant file paths, commands, or references]
```

### 3. Context Management Techniques

**Rolling summary:** periodically compact completed work into a single paragraph, dropping the detail — "phases 1-3 complete, all tests green, see commit abc1234" rather than re-describing each step.

**Pointer approach:** for large artifacts (specs, plans, schemas), reference by file path rather than repeating content — "schema is in `db/schema.sql`" not the full schema text.

**Decision log:** keep a running log of decisions made and their rationale — prevents re-litigating the same questions as context rolls.

**Staged handoff:** when handing off to another agent, provide: goal, compact, and a list of the 3 most important files to read first.

## Output Format

Produce a self-contained compact that a fresh context (new conversation, new agent, tomorrow-you) can act on immediately:

- No pronouns or "we" without antecedents — spell out what you mean.
- Specific file paths and line numbers, not "the file we were editing."
- Specific commands, not "run the tests."
- Decisions recorded as facts, not discussion — "chose Postgres over MySQL because X" not "we were debating Postgres vs MySQL."

## When to Trigger

- Context token count above 80% of the window.
- Switching from one major phase to another (planning → implementation, implementation → review).
- End of a working session before stopping.
- Before spawning a sub-agent that needs to continue a task.

## Constraints

- A strategic compact is a snapshot, not a full journal — be ruthlessly concise.
- Include the minimum information needed to resume, not a complete record of everything that happened.
- Always include the "next action" — the compact is useless without it.
