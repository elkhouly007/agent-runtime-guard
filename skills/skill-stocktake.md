# Skill: skill-stocktake

## Purpose

Audit the current set of skills, agents, and rules in Agent Runtime Guard — identify duplicates, gaps, stale content, and coverage relative to project needs. Produce a prioritized improvement list.

## Trigger

- Periodically (e.g., after adding several new skills) to keep the toolkit coherent
- Before onboarding a new technology stack — check what's already covered
- When a skill is suspected to be outdated or redundant

## Trigger

`/skill-stocktake` or `audit the skills and agents`

## Steps

1. **Inventory current content**
   ```bash
   ls skills/*.md | grep -v README
   ls agents/*.md | grep -v README
   ls rules/**/*.md | grep -v README
   ```
   Record counts and names.

2. **Check for duplicates**
   - Do any two skills cover the same trigger?
   - Do any two agents have overlapping descriptions?
   - Flag and propose merges.

3. **Check for gaps**
   - What languages/frameworks are used in the project but have no dedicated rule set?
   - What common tasks are performed but have no skill?
   - Cross-reference with `references/full-power-status.md` for known gaps.

4. **Check for staleness**
   - Skills referencing deprecated APIs or old patterns.
   - Agents with tool lists that don't match current available tools.
   - Rules referencing library versions that are no longer current.

5. **Assess coverage quality**
   - Do existing skills have clear triggers, steps, and safe-behavior sections?
   - Do agents have proper frontmatter (name, description, tools, model)?
   - Are rules actionable with examples?

6. **Produce output**

```markdown
## Skill Stocktake — YYYY-MM-DD

### Inventory
- Skills: N
- Agents: N
- Rule files: N

### Duplicates / Merge Candidates
- ...

### Gaps (prioritized)
1. [highest value missing skill/rule]
2. ...

### Stale Content
- ...

### Quality Issues
- ...

### Recommended Actions
1. ...
```

## Safe Behavior

- Read-only analysis — does not modify any files.
- Produces a report only; all changes require explicit follow-up action.
