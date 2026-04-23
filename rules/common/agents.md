---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Rules for Writing Agents

## Frontmatter (Required)

Every agent file must have YAML frontmatter with these fields:

```yaml
---
name: agent-name           # kebab-case, matches the filename
description: |             # One sentence: what triggers this agent + what it does.
  Expert [role]. Activate for [trigger]. Does [action].
tools: Read, Grep, Bash    # Comma-separated list — only tools the agent actually needs
model: sonnet              # Default model. Use 'opus' only for complex multi-step reasoning.
---
```

- `name` must match the filename exactly (without `.md`).
- `description` must be specific enough that an orchestrator can route to this agent correctly — vague descriptions cause misrouting.
- `tools` must be minimal — do not grant tools the agent does not use. Fewer tools = smaller attack surface and clearer intent.
- Omit `model` to inherit the harness default. Only set it if this agent has different requirements.

## Tool Constraints

- Grant only the tools the agent needs for its stated task:
  - Read-only analysis agents: `Read, Grep` — no `Bash`, no `Edit`, no `Write`
  - Code reviewers: `Read, Grep, Bash` (for `git diff`) — no `Edit`, no `Write`
  - Code generators/fixers: `Read, Grep, Bash, Edit, Write`
  - Orchestrators: `Read, Grep, Bash, Agent` (for spawning sub-agents)
- Never grant `WebFetch` or `WebSearch` unless the agent's purpose explicitly requires external lookups.
- Never grant `Agent` unless the agent is an orchestrator that spawns sub-agents.

## Safe Behavior Rules

- **No silent side effects.** Agents that make changes (edit, write, delete) must report what they changed.
- **No destructive operations without explicit justification.** Deleting files, dropping data, or overwriting configs must be requested by the user — not inferred.
- **Validate inputs before acting.** If the agent receives a file path or identifier, verify it exists before operating on it.
- **Scope creep is forbidden.** An agent asked to review a file must not silently edit it. An agent asked to plan must not silently implement.
- **Surface uncertainty.** If the agent cannot determine the correct action with high confidence, it must say so and ask — not guess and act.

## Description Writing Guidelines

Good descriptions enable correct routing. A good description answers:
1. **When to activate** — what user request or context triggers this agent?
2. **What it does** — the specific action or output it produces.
3. **What it does NOT do** — if there's a common confusion, clarify the boundary.

```yaml
# BAD — too vague
description: Helps with code.

# BAD — too long / narrative
description: |
  This agent is an expert in reviewing TypeScript code. It uses its deep knowledge
  of the TypeScript ecosystem to find bugs and suggest improvements. You should use
  it when you want a TypeScript code review.

# GOOD — specific trigger + specific action
description: |
  TypeScript specialist. Activate for TS/TSX code review, type system questions,
  or tsconfig issues. Reviews for type safety, strict-mode compliance, and common
  TS anti-patterns. Does NOT handle runtime logic bugs — use code-reviewer for those.
```

## Prompt Body Structure

Structure the agent's instructions in this order:

1. **Role statement** — one sentence establishing expertise and perspective.
2. **Process** — numbered steps the agent follows for its primary task.
3. **Checklist or criteria** — what the agent looks for / produces.
4. **Output format** — how results should be structured (e.g., severity-ranked findings, structured plan, numbered list).
5. **Constraints** — what the agent must not do (scope boundaries).

## Model Selection

| Task type | Model |
|---|---|
| Syntax/style review, simple transforms | `haiku` |
| Code review, analysis, planning, most agents | `sonnet` (default) |
| Multi-step reasoning, architecture design, complex orchestration | `opus` |

- Default to `sonnet`. Do not use `opus` unless the task demonstrably requires it.
- Do not hardcode model IDs — use the canonical name (`haiku`, `sonnet`, `opus`).

## Anti-Patterns to Avoid

- **God agents** — one agent that does everything. Split by domain or phase (plan vs. implement vs. review).
- **Overlapping descriptions** — two agents with similar descriptions cause routing ambiguity. Make boundaries explicit.
- **Missing output format** — agents without a defined output format produce inconsistent results. Always specify how findings or output should be structured.
- **Unbounded tool grants** — granting all tools "just in case" violates the principle of least privilege.
