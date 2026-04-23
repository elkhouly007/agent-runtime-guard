# Skill: everything-claude-code

## Trigger

Use when someone asks:
- "What is ECC?" / "What is Everything Claude Code?"
- "How does this toolkit work?"
- "What's the ECC way to do X?"
- "How do I extend ECC with a new skill / agent / rule?"
- "What's the philosophy behind this setup?"
- "Show me everything this toolkit can do"

Also auto-triggered as a reference when writing new agents, skills, or rules — ensures new content matches the ECC architecture and conventions.

## Overview

**Everything Claude Code (ECC)** is a structured toolkit that makes Claude Code (and compatible AI coding assistants) dramatically more capable by providing:

| Layer | What it is | How it works |
|---|---|---|
| **Skills** | Slash commands invoked by the user | `/skill-name` → Claude reads the skill file and follows its process |
| **Agents** | Specialist sub-agents | Orchestrator spawns agent with the agent file as its system prompt |
| **Rules** | Always-apply coding guidelines | Injected into context for relevant file types via `CLAUDE.md` imports |
| **Hooks** | Automation scripts | Triggered by Claude Code events (session start/end, tool use) |

**Agent Runtime Guard** is the safety-hardened fork. It adds:
- Hooks that never capture content or make network calls
- Instinct learning system (local-only, privacy-preserving)
- Payload protection pipeline for external agent calls
- Strategic compaction and quality gate automation

---

## Architecture

```
tools/ecc-safe-plus/
├── agents/          ← specialist sub-agents (one .md per agent)
├── skills/          ← slash commands (one .md per skill)
├── rules/           ← coding guidelines (organized by language/domain)
│   ├── common/      ← applies everywhere
│   ├── python/
│   ├── typescript/
│   ├── java/
│   └── ...
├── scripts/         ← setup, audit, smoke-test scripts
├── references/      ← status docs, changelogs
└── claude/
    └── hooks/       ← automation (Node.js, stdlib only)
```

**Wiring:**
- Skills → wired in `claude/settings.json` as slash commands
- Agents → invoked via the Agent tool or orchestration skills
- Rules → imported in `CLAUDE.md` per language/directory
- Hooks → registered in `claude/hooks/hooks.json`

---

## The ECC Philosophy

### 1. Depth over breadth
Every skill, agent, and rule must have:
- A clear, specific trigger (when to use it — not a vague description)
- A concrete process (what to do, step by step)
- BAD/GOOD examples where relevant
- Safe behavior constraints (what it will never do)

A thin file with no examples is not production-ready.

### 2. Separation of concerns
- **Skills** = user-facing workflows (what you invoke)
- **Agents** = specialist executors (what gets spawned)
- **Rules** = ambient standards (applied automatically)
- **Hooks** = event-driven automation (fires without user input)

Never collapse these: a skill that does what an agent should do is hard to compose; a rule that triggers like a skill breaks discoverability.

### 3. Safety by design (Safe-Plus additions)
Hook contract — every hook must:
- Pass stdin → stdout unchanged
- Write only to stderr for messages
- Use only stdlib (no npm installs)
- Make no network calls
- Capture no prompt content
- Fail silently (never break the session)

### 4. Local-first learning
The instinct system (`/learn`, `/evolve`, `/prune`) captures session patterns locally. Nothing leaves the machine. Promotion from `pending.json` → `confident.json` requires human review via `/instinct-status`.

---

## Writing a New Skill

```markdown
# Skill: skill-name

## Trigger
[Exact phrases that should invoke this skill]

## Process
1. Step one
2. Step two

## Output
[What the user sees when done]

## Safe Behavior
- [What this skill will never do]
```

Rules:
- Name: kebab-case, verb-noun preferred (`fix-build`, `plan-feature`, `code-review`)
- Trigger: specific enough that two skills don't fight for the same phrase
- Process: numbered steps; include code examples for technical steps
- Safe Behavior: at least one constraint (what it won't do without confirmation)
- File: `skills/<name>.md`

---

## Writing a New Agent

Agent files use YAML frontmatter:

```markdown
---
name: my-specialist
description: One sentence — what this agent does and when to invoke it
tools: [Read, Grep, Glob, Bash]
model: claude-sonnet-4-5
---

You are a specialist in X. Your job is to Y.

## Process
...

## Output Format
...

## Constraints
- Never modify files
- Report findings only
```

Rules:
- `tools`: list only what the agent actually needs — principle of least privilege
- `model`: use `claude-sonnet-4-5` for most agents; `claude-haiku-4-5` for fast/cheap classification
- Description must be specific enough for an orchestrator to pick the right agent

---

## Writing a New Rule File

```markdown
# [Language/Domain] [Category] Rules

## [Section Name]

[One-sentence principle]

​```language
// BAD — why this is wrong
bad_example_code

// GOOD — the correct approach
good_example_code
​```

## Tooling Commands
​```bash
tool --flag               # what it does
​```

## Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| ... | ... | ... |
```

Rules:
- Minimum 150 lines for a production-ready rule file
- Every section needs BAD/GOOD code examples
- Include tooling commands (format, lint, type-check, audit)
- End with an anti-patterns table
- File: `rules/<language>/<category>.md`

---

## Core Skills Reference

| Skill | Purpose |
|---|---|
| `/configure-ecc` | Set up ECC in a new environment |
| `/skill-stocktake` | Audit agents/skills/rules for gaps and staleness |
| `/skill-create` | Create a new skill file interactively |
| `/instinct-status` | Review pending instincts from session learning |
| `/evolve` | Cluster instincts into new skill candidates |
| `/learn` | Manually record a new instinct |
| `/prune` | Remove expired or low-value instincts |
| `/code-review` | Full code review with severity table |
| `/security-review` | OWASP-mapped security audit |
| `/tdd` | Test-driven development workflow |
| `/plan-feature` | Feature planning with risk assessment |
| `/refactor` | Safe refactoring with pre-gate checks |
| `/performance-audit` | Profile and fix performance bottlenecks |
| `/deep-research` | Multi-source research with citation |
| `/orchestrate` | Spawn and coordinate multiple agents |

---

## Safe Behavior

- This skill is read-only — it explains the system, does not modify it.
- When invoked during agent/skill/rule creation, it informs the output format but does not auto-create files.
- Does not expose internal hook implementations to external agents.
