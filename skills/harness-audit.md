# Skill: Harness Audit

## Trigger

Use when auditing Claude Code or OpenClaw harness performance: measuring how effectively the agent harness is working, identifying friction points in the agent workflow, scoring hook reliability, and producing a performance improvement plan.

## What a Harness Audit Measures

A harness audit scores the operational health of your agent harness setup across 5 dimensions:

1. **Context efficiency** — is the context budget used well?
2. **Agent routing accuracy** — do tasks go to the right agent?
3. **Hook reliability** — are hooks firing, passing, and adding value?
4. **Session hygiene** — are sessions clean, compact, and focused?
5. **Skill coverage** — do skills exist for the work being done?

## Audit Checklist

### 1. Context Efficiency

```bash
# Measure total context loaded per session
wc -c ~/.claude/CLAUDE.md
find . -name "CLAUDE.md" | xargs wc -c 2>/dev/null

# Token estimate: characters / 4
# Budget: keep under 8,000 tokens (32,000 chars) for fast sessions
```

Scoring:
- ✅ Green: < 8,000 tokens total context
- ⚠️ Amber: 8,000–15,000 tokens — review for bloat
- ❌ Red: > 15,000 tokens — significant context overhead

**Common issues:**
- CLAUDE.md contains rarely-relevant sections
- Long inline examples that could be file references
- Duplicate rules across CLAUDE.md and rule files
- Outdated documentation still loaded

### 2. Agent Routing Accuracy

Review recent sessions for routing quality:

```bash
# Check what agents were invoked
grep -r "Activate\|delegate\|using agent" ~/.claude/logs/ 2>/dev/null | tail -50
```

Questions:
- Did the right agent handle each task type?
- Were tasks escalated to Opus unnecessarily?
- Were any tasks sent to a generic response instead of a specialist agent?

Scoring:
- ✅ Green: correct agent used in > 90% of logged tasks
- ⚠️ Amber: 70-90% — some routing confusion, tighten agent descriptions
- ❌ Red: < 70% — agent descriptions need significant rewrite

### 3. Hook Reliability

```bash
# Verify hooks are configured
cat ~/.claude/settings.json | python3 -m json.tool | grep -A20 '"hooks"'

# Check if hook scripts are executable
ls -la ~/.claude/hooks/ 2>/dev/null || ls -la tools/ecc-safe-plus/source-hooks/ 2>/dev/null
```

For each hook type (PreToolUse, PostToolUse, Stop, etc.):
- Is it configured?
- Is the script executable?
- Does it complete without error?
- Is it adding observable value (guardrails, logging, reminders)?

Scoring:
- ✅ Green: all configured hooks run without error
- ⚠️ Amber: hooks configured but some failing silently
- ❌ Red: hooks not configured or consistently failing

### 4. Session Hygiene

Review session patterns:
- Are sessions focused on one task or jumping between unrelated work?
- Are sessions being compacted when context grows large?
- Are strategic compacts being used before handoffs?
- Are sessions timing out or hitting context limits unnecessarily?

Good session hygiene indicators:
- Sessions average under 20 turns for most tasks
- Context compaction used when sessions exceed 50% of context window
- Clear task framing at session start

### 5. Skill Coverage

```bash
# Count available skills
ls tools/ecc-safe-plus/skills/*.md | wc -l

# Check for tasks without dedicated skills (from session history)
# Pattern: look for repeated ad-hoc prompts that aren't using /skill
```

Scoring:
- ✅ Green: all common task types have a skill
- ⚠️ Amber: 1-3 common task types lack skills — create them
- ❌ Red: most work done with generic prompts, not skills

## Audit Report

```markdown
## Harness Audit Report — [date]

### Scores
| Dimension | Score | Status |
|---|---|---|
| Context efficiency | [N] tokens / session | ✅/⚠️/❌ |
| Agent routing | [N]% accurate | ✅/⚠️/❌ |
| Hook reliability | [N]/[N] hooks passing | ✅/⚠️/❌ |
| Session hygiene | [avg turns / session] | ✅/⚠️/❌ |
| Skill coverage | [N] skills, [N] gaps | ✅/⚠️/❌ |

### Overall Score: [Green/Amber/Red]

### Top 3 Improvements
1. [specific action] — expected impact: [X]
2. [specific action] — expected impact: [X]
3. [specific action] — expected impact: [X]

### Estimated Cost Impact
Current: ~$[N]/month
After fixes: ~$[N]/month (estimated [X]% reduction)
```

## Improvement Actions by Issue

| Issue | Action |
|---|---|
| Context bloat | Trim CLAUDE.md, split rarely-used sections to on-demand files |
| Routing errors | Rewrite vague agent descriptions with specific triggers |
| Hook failures | Debug with `bash hook.sh` directly; fix exit code handling |
| Long sessions | Add strategic-compact triggers; use /checkpoint more |
| Missing skills | Create skills for any task type that recurs > 3 times |

## Constraints

- Audit is read-only — does not modify any configuration files.
- All recommendations require user approval before implementation.
- Do not delete hooks, agents, or rules based solely on audit findings without confirming with the user.
