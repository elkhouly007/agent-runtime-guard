---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Agent Design Rules

Standards for writing well-formed agents in the ARG ecosystem. These rules apply to all agent definitions in `agents/`.

## Frontmatter

Every agent must have a valid YAML frontmatter block:

```yaml
---
name: agent-name
description: [rich description for routing — include what it amplifies and specific trigger conditions]
tools: [minimal set of tools needed]
model: sonnet
---
```

- `name`: lowercase, hyphenated, matches the filename.
- `description`: used by routing systems to decide when to activate this agent. Make it specific. Include domain, trigger conditions, and what the agent produces.
- `tools`: minimum set. Do not include tools the agent does not use. WebSearch requires justification.
- `model`: default to `sonnet`. Use `opus` only for agents requiring extended reasoning on complex problems.

## Structure

Every agent document must have:
1. A **Mission** section: one sentence stating exactly what capability this agent amplifies.
2. An **Activation** section: specific conditions (both when to use and when NOT to use).
3. A **Protocol** section: numbered steps for autonomous execution.
4. An **Amplification Techniques** section: what makes this agent produce 10x the baseline value.
5. A **Done When** section: measurable, specific completion criteria.

## Mission Statement

The mission must be one sentence. It must describe what the agent amplifies, not just what it does. Agents amplify capability — they do not just perform tasks.

Bad: "Reviews Python code."
Good: "Find every bug, vulnerability, and missed opportunity in Python code and provide concrete, runnable fixes."

## Activation Conditions

Activation conditions must be specific enough to be used for automated routing. Vague conditions produce poor routing decisions.

Bad: "Use when reviewing code."
Good: "Activate for PR review, pre-commit quality gate, or any change touching security, auth, data persistence, or external APIs."

Include negative conditions (when NOT to use) for agents with overlapping scope.

## Protocol Steps

- Each step must be actionable without human interpretation.
- Each step produces a verifiable output or state change.
- Steps should be ordered by dependency, not by importance.
- Maximum 8 steps. More steps indicate the agent is doing too many things.

## Done When

The Done When section defines when the agent has completed its work. Criteria must be:
- Specific (not "review is complete")
- Measurable (not "code is better")
- Binary (done or not done, not "mostly done")

## Amplification Mindset

Every agent in the ARG ecosystem is an intelligence amplifier. This means:
- It does not just report — it produces actionable output.
- It does not just identify problems — it proposes specific solutions.
- It does not just complete the task — it leaves the system in a better state than it found it.
- It captures what it learned so the next session starts smarter.
