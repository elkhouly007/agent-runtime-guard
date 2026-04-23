# Skill: Workspace Surface Audit

## Trigger

Use when auditing an AI agent harness workspace: reviewing what's loaded, what's active, what's unused, and identifying opportunities to reduce complexity, improve performance, or close security gaps.

## Audit Dimensions

### 1. Context Surface (Token Cost)

What is loaded in every session:

```bash
# Measure CLAUDE.md size
wc -w ~/.claude/CLAUDE.md
cat ~/.claude/CLAUDE.md | wc -c

# Find all auto-loaded context files
find ~/.claude -name "CLAUDE.md" | sort
find . -name "CLAUDE.md" | sort  # project-level too

# Estimate token cost: characters / 4 ≈ tokens
# Typical budget: keep total under 8,000 tokens for fast sessions
```

**What to look for:**
- Sections that are never read or referenced
- Examples that are too long — shorten or link out
- Rules that duplicate each other
- Out-of-date documentation

### 2. Agent Registry

Review all registered agents:

```bash
ls agents/ | wc -l                    # total agents
cat agents/*.md | grep "^name:" | sort # all agent names
```

**For each agent, check:**
- Is the description specific enough for correct routing?
- Does the tool list match actual tool usage?
- Is the model assignment appropriate?
- Has this agent been used in the last 30 days?

Flag for review:
- Agents with vague descriptions (routing ambiguity)
- Agents with `tools: *` or more tools than needed
- Agents that duplicate another agent's scope
- Agents never invoked (dead weight)

### 3. Rules Coverage

```bash
ls rules/**/*.md | sort               # all rule files
wc -l rules/**/*.md | sort -rn        # size ranking
```

**Check:**
- Every language in the codebase has rules
- No duplicate rules across files
- Rule files are current (not referencing deprecated APIs/versions)
- Rules are actionable (not vague general principles)

### 4. Skills Inventory

```bash
ls skills/ | wc -l
```

**For each skill, check:**
- Is the trigger condition specific? Would a user know when to invoke it?
- Does it produce a consistent, useful output?
- Has it been invoked in the last 30 days?
- Is it duplicated by another skill?

### 5. Hooks and Automation

```bash
cat ~/.claude/settings.json | python3 -m json.tool | grep -A5 '"hooks"'
```

**Check:**
- Every hook has a clear purpose
- Hooks are not silently failing (check hook logs)
- Hook outputs are not leaking into unrelated contexts
- No hooks that no longer apply

### 6. MCP Servers

```bash
cat ~/.claude/settings.json | python3 -m json.tool | grep -A10 '"mcpServers"'
```

**For each MCP server:**
- Is it still in use?
- Is it running and healthy?
- Does it have appropriate scope (not over-permissioned)?
- Is the data it accesses still sensitive/relevant?

## Audit Report Template

```markdown
## Workspace Surface Audit — [date]

### Summary
- Total agents: [N] | Active (30d): [N] | Unused: [N]
- Total skills: [N] | Active (30d): [N] | Unused: [N]
- Context load: ~[N] tokens/session (target: <8,000)
- MCP servers: [N] | Healthy: [N] | Stale: [N]

### High Priority Findings
1. [Finding] — [Impact] — [Recommended action]
2. ...

### Optimization Opportunities
| Item | Current | Change | Estimated savings |
|------|---------|--------|-------------------|
| CLAUDE.md | 12,000 tokens | Trim to 5,000 | $8/month |
| [agent] | unused | Remove | Cleaner registry |

### Action Items
- [ ] [action] — [owner] — [by when]
```

## Constraints

- Do not delete agents, rules, or skills based solely on inactivity — confirm with the user that the item is genuinely unneeded.
- Do not modify MCP server configs without understanding the downstream impact.
- Audit is read-only by default — all changes require explicit user approval.
