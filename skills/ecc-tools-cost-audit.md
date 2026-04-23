# Skill: ECC Tools Cost Audit

## Trigger

Use when auditing AI/LLM costs across an agent harness setup: identifying what's driving token spend, finding optimization opportunities, setting budgets, or explaining a billing spike.

## What to Audit

### 1. Token Usage by Component

Identify the largest token consumers:

```
Component          | Tokens/day | % of total | Cost/month
--------------------|-----------|------------|------------
CLAUDE.md context  | 48,000     | 35%        | $14.40
Long conversations | 32,000     | 23%        | $9.60
Agents (spawned)   | 28,000     | 20%        | $8.40
Rules context      | 18,000     | 13%        | $5.40
Skills invocations | 12,000     | 9%         | $3.60
Total              | 138,000    | 100%       | $41.40/mo
```

### 2. CLAUDE.md / Context File Audit

CLAUDE.md is loaded in every conversation — it's often the biggest cost driver:

```bash
# Count tokens in CLAUDE.md
wc -w ~/.claude/CLAUDE.md
# Rough estimate: words × 1.3 ≈ tokens

# Check all context files loaded
find ~/.claude -name "*.md" | xargs wc -l | sort -rn | head -20
```

**Optimization targets:**
- Remove sections that are rarely relevant (they still cost tokens every time).
- Replace long examples with references to files — agents can read on demand.
- Use conditional includes if the harness supports them.

### 3. Model Selection Audit

Check if expensive models are used where cheaper ones would work:

| Task | Current model | Could use | Savings |
|---|---|---|---|
| Syntax checks | sonnet | haiku | ~75% |
| Simple formatting | sonnet | haiku | ~75% |
| Architecture review | sonnet | opus | — |

Audit agent files for model assignments:
```bash
grep -r "model:" agents/ | sort | uniq -c | sort -rn
```

### 4. Context Injection Pattern Review

Each tool call that injects context adds tokens:
- Long file reads on every invocation
- Full file reads when only a section is needed
- Repeated reads of the same file in one session

**Fix:** use targeted reads (`Read` with `offset`/`limit`) instead of full file reads.

### 5. Loop and Re-entry Detection

Agent loops that re-enter unnecessarily multiply costs:
```bash
# Check for runaway loop patterns in logs
grep -c "Starting new session" ~/.claude/logs/*.log 2>/dev/null | sort -t: -k2 -rn | head -5
```

## Cost Reduction Playbook

| Issue | Impact | Fix |
|---|---|---|
| Bloated CLAUDE.md | High | Trim to <2,000 tokens; move rarely-used content to separate files |
| Using opus for simple tasks | High | Route to haiku or sonnet with `/model-route` |
| Full file reads in every session | Medium | Use `Read` with offsets; cache reads in-session |
| Long conversation context | Medium | Use `/checkpoint` to compact context before it grows |
| Unused agents loaded | Low | Remove from registry if not used in last 30 days |
| Redundant rule files | Low | Merge thin rules files |

## Monthly Budget Template

```
Budget: $[N]/month
─────────────────────────────────────
Baseline (CLAUDE.md + rules): $[X]
Agent invocations:             $[X]
Active development sessions:   $[X]
Buffer (10%):                  $[X]
─────────────────────────────────────
Total projected:               $[X]
```

## Output Format

- Current cost estimate broken down by component.
- Top 3 optimization opportunities with estimated savings.
- Recommended model routing changes.
- Trimming recommendations for high-cost context files.
- Projected cost after optimizations.

## Constraints

- Cost estimates are approximations — actual token counts require instrumentation or Anthropic console data.
- Do not delete rule or agent files solely to reduce cost without confirming they're genuinely unused.
