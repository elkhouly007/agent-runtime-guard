# Skill: orchestration-design

---
name: orchestration-design
description: Design a multi-agent orchestration workflow for a complex task — identify which agents to use, in what order, with what handoffs
---

# Orchestration Design

Structure complex tasks as a coordinated sequence of specialized agents.

## When to Use

Single-agent tasks: straightforward questions, small edits, local lookups.

Orchestrate when:
- The task spans multiple domains (architecture + security + tests)
- The output of one stage is the input to the next
- Different agents need to check the same artifact independently
- Quality validation requires a perspective shift (author vs reviewer)

## Core Patterns

### Sequential Pipeline

```
Input → Agent A → Agent B → Agent C → Output

Use when: each stage enriches or validates the previous stage's output
Example: Planner → Architect → SecurityReviewer → TDDGuide
```

### Parallel Review

```
         ┌→ CodeReviewer ─────┐
Input ──→│→ SecurityReviewer ─│→ Synthesized output
         └→ PerformanceAgent ─┘

Use when: multiple independent quality dimensions need to be assessed
Example: reviewing a PR for code quality, security, and performance simultaneously
```

### Iterative Refinement

```
Draft → Reviewer → [Issues?] → Revise → Reviewer → ...

Use when: quality improves through iteration
Limit: 2–3 iterations max before re-scoping the task
```

### Hierarchical (Chief of Staff)

```
ChiefOfStaff
├── delegates to Planner
├── delegates to Architect
├── delegates to [specialist per module]
└── synthesizes all outputs

Use when: task is large and multi-part
```

## Handoff Template

Each agent should end its output with:
```
## Output
[The artifact produced]

## Handoff Note
Next agent needs: [specific context]
Key decisions made: [list of non-obvious choices]
Open questions: [anything left unresolved]
```

## Workflow Definition

Document the orchestration:
```yaml
workflow: implement-feature
steps:
  - agent: planner
    input: feature_spec
    output: implementation_plan
  - agent: architect
    input: implementation_plan
    output: architecture_decision
  - agent: tdd-guide
    input: [implementation_plan, architecture_decision]
    output: test_suite
  - agent: code-reviewer
    input: [implementation, test_suite]
    output: review_findings
```

## Common Anti-Patterns

- **Chain too long**: >5 sequential agents accumulate context drift. Break into separate passes.
- **No validation gates**: pass output through even when it is clearly wrong. Add explicit checkpoints.
- **Over-orchestration**: using 5 agents for a task one good prompt could handle.
- **Ambiguous handoffs**: next agent doesn't know what the previous one decided.
