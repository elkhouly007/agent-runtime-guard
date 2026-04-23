# Skill: Memory Persistence

## Trigger

Use when:
- Starting a new session that continues prior work.
- Ending a session with decisions or context worth preserving.
- Resuming after a `/compact` that may have dropped important state.
- Handing off work to another agent or session.

## What Memory Persistence Does

Memory persistence ensures the important context from a session — decisions made, patterns discovered, current position in a task — survives across sessions without requiring Claude to re-read the entire codebase.

It has two halves:
- **Session-start load**: inject saved memory into the new session so work can resume immediately.
- **Session-end save**: extract and write what is worth keeping before the session ends.

## Process

### Session-End: What to Save

At the end of a session, decide what to persist:

```
1. Was a decision made that is not obvious from the code?
   → Save to memory/project_*.md

2. Was a pattern confirmed that should influence future work?
   → Save to memory/feedback_*.md or use /learn

3. Did the project scope or deadline change?
   → Update memory/project_*.md

4. Was a reference found that will be needed again?
   → Save to memory/reference_*.md
```

Do NOT save:
- Information already clear from reading the code.
- Step-by-step progress that will be obvious from git history.
- Temporary debugging notes.

### Writing a Memory File

Memory files live at:
```
~/.claude/projects/<project-path>/memory/
```

Each file has frontmatter + content:

```markdown
---
name: [short title]
description: [one-line description — used for relevance decisions]
type: user | feedback | project | reference
---

[content]

**Why:** [reason this matters — context for future sessions]
**How to apply:** [when this should influence behavior]
```

Types:
| Type | When to use |
|------|-------------|
| `user` | Ahmed's role, preferences, expertise level |
| `feedback` | Corrections or confirmations about approach |
| `project` | Ongoing work, decisions, deadlines, stakeholders |
| `reference` | Where to find things: dashboards, repos, docs, channels |

### Session-End Hook

The `session-end.js` hook fires automatically on Stop. It records metadata.
For richer memory, manually write files at the end of important sessions:

```bash
# Check current memory files
ls ~/.claude/projects/-home-khouly--openclaw-workspace-sand/memory/

# View the memory index
cat ~/.claude/projects/-home-khouly--openclaw-workspace-sand/memory/MEMORY.md
```

### Session-Start Load

The `memory-load.js` hook fires on SessionStart and prints a summary to stderr:

```
[Agent Runtime Guard] Memory: 5 items loaded.
  • Agent Runtime Guard Build Progress & Plan
  • Agent Runtime Guard Operating Policy
  • (+ 3 more)
```

This gives Ahmed immediate orientation without re-reading everything.

### Manual Reload in a Running Session

If you suspect memory is stale, re-read the index:

```bash
cat ~/.claude/projects/-home-khouly--openclaw-workspace-sand/memory/MEMORY.md
```

Then read specific files as needed.

## Memory File Naming

```
user_<topic>.md          # user preferences, background
feedback_<topic>.md      # approach corrections and confirmations
project_<topic>.md       # project state, decisions, deadlines
reference_<topic>.md     # pointers to external systems
```

Examples:
```
memory/
├── MEMORY.md                          ← index (always loaded)
├── user_role.md
├── feedback_testing_approach.md
├── project_ecc_safe_plus_progress.md
└── reference_dashboards.md
```

## MEMORY.md — The Index

`MEMORY.md` is always loaded. Keep it under 200 lines. Each entry is one line:

```markdown
# Memory Index

- [Agent Runtime Guard Build Progress](project_ecc_safe_plus_progress.md) — current state: agents, skills, rules counts and what's pending
- [Operating Policy](project_ecc_safe_plus_policy.md) — what Sand auto-handles vs needs approval
```

Format: `- [Title](file.md) — one-line hook (why this matters now)`

## Anti-Patterns

| Anti-pattern | Problem |
|-------------|---------|
| Saving code snippets to memory | Code is in the repo — read it there |
| Saving git history summaries | `git log` is authoritative |
| Writing long prose in MEMORY.md | Index lines should be ≤ 150 chars |
| Saving debugging steps | The fix is in the commit; message has context |
| Saving everything | Memory bloat slows future sessions |

## Safe Behavior

- Memory files are written locally only — never sent externally.
- Memory files do not contain secrets, API keys, or personal data.
- The `memory-load.js` hook is read-only — it never modifies memory files.
- Deleting a memory file is safe — nothing breaks, future sessions just lose that context.
- Ahmed approves any new memory file that contains project decisions or policy changes.
