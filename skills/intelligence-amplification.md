# Skill: intelligence-amplification

---
name: intelligence-amplification
description: Techniques for getting 10x more value from agent interactions — prompt construction, context management, agent chaining, and feedback loops
---

# Intelligence Amplification

How to structure work so agents deliver maximum value rather than minimum viable output.

## When to Use


## Core Principle

Agents amplify what you give them. Vague input produces vague output. Precise, context-rich input produces precise, high-leverage output.

## Prompt Construction

**Before**: `Review this code`

**After**: `Review the authentication flow in src/auth/login.ts for security vulnerabilities. Focus on: session handling, input validation, and timing attack exposure. Output findings as: severity (critical/high/medium), location (file:line), and specific remediation.`

The second prompt:
1. Scopes to a specific file and concern
2. Names exactly what to look for
3. Specifies the output format

## Context Injection

Use the full context window deliberately:

```
1. Paste the relevant code (not the whole repo)
2. State the architectural decision already made (so the agent doesn't re-litigate it)
3. State what you've already tried (so the agent doesn't repeat it)
4. State the specific question (so the agent answers it, not something adjacent)
```

## Agent Chaining

Chain agents for compound problems:

1. `planner` → creates structured implementation plan
2. `architect` → validates architecture decisions in the plan
3. `security-reviewer` → audits security surface before implementation
4. `tdd-guide` → writes tests first
5. `code-reviewer` → reviews the implementation
6. `doc-updater` → updates documentation

Each agent sees the output of the previous step as context.

## Feedback Loop

After each agent output:
1. Note what was useful (so you ask for it again)
2. Note what was generic (so you provide more constraints next time)
3. Note what was wrong (so you correct it explicitly)

## When Agents Get It Wrong

- Restate the constraint they missed — they didn't ignore it, they lacked it
- Add a negative example: `Do NOT suggest X because Y`
- Reduce scope: one function, not one module; one question, not five

## Measurement

Track agent output quality over time:
- How often does the first output need significant revision?
- How many back-and-forth turns to reach a useful answer?
- What prompt additions consistently improve quality for your domain?
