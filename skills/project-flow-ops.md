# Skill: Project Flow Ops

## Trigger

Use when managing project operations: setting up task tracking systems, running sprint ceremonies, prioritizing backlogs, defining project workflows, or improving team execution velocity.

## Core Framework

### Project Health Dimensions

A healthy project has clarity on all five:
1. **Goal** — what are we trying to achieve? (measurable outcome, not activity)
2. **Status** — where are we right now? (% complete, blockers, risks)
3. **Next** — what is the immediate next action? (specific, assigned, time-bounded)
4. **Blockers** — what is preventing progress? (each needs an owner and a plan)
5. **Timeline** — is the current pace compatible with the deadline? (burn-up/down)

### Task Lifecycle

```
Idea → Backlog → Ready → In Progress → Review → Done
                  ↑                        |
         (Definition of Ready)      (Definition of Done)
```

**Definition of Ready** (before starting):
- [ ] Clear description of what done looks like
- [ ] Dependencies identified
- [ ] Size estimated
- [ ] Owner assigned

**Definition of Done** (before closing):
- [ ] Feature works as specified
- [ ] Tests written and passing
- [ ] Documentation updated (if applicable)
- [ ] Reviewed by at least one other person

## Sprint Operations

### Sprint Planning

1. Review backlog — confirm top items are Ready.
2. Size items (story points or T-shirt sizes — pick one and be consistent).
3. Commit to a realistic sprint goal — don't over-commit.
4. Assign owners — not "the team will do X," but "Alice owns X."

```markdown
## Sprint [N] Goal
[One sentence: what we will achieve by end of sprint]

## Committed Items
| Task | Owner | Points | Notes |
|------|-------|--------|-------|
| [task] | Alice | 5 | Depends on API contract from Bob |

## Not In Sprint (Backlog)
- [items explicitly deferred]
```

### Daily Standup (async or sync)

Three questions:
1. What did I do yesterday? (completed tasks only)
2. What am I doing today? (specific, not "working on X")
3. Any blockers? (specific, not "might have some challenges")

### Sprint Retrospective

Four quadrants:
- **Went well** — do more of this
- **Didn't go well** — do less or fix
- **Puzzles** — things we don't understand yet
- **Action items** — specific changes to make next sprint (max 3, each with an owner)

## Backlog Prioritization

**RICE score** (Reach × Impact × Confidence / Effort):
- Reach: how many users/customers does this affect? (0-100)
- Impact: how much does it move the needle? (0.25, 0.5, 1, 2, 3)
- Confidence: how sure are we about R and I? (50%, 80%, 100%)
- Effort: person-weeks to complete

```
RICE = (Reach × Impact × Confidence) / Effort
Higher = higher priority
```

## Tracking Templates

### Weekly Status Report

```markdown
## Week of [date]

### Highlights
- [Key win 1]
- [Key win 2]

### Progress vs. Plan
- [Milestone 1]: [On track / At risk / Delayed] — [% complete]
- [Milestone 2]: [On track / At risk / Delayed]

### Blockers
- [Blocker]: [Owner] — [Plan to resolve]

### Next Week
- [Priority 1]
- [Priority 2]
```

### Project Risk Register

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|-----------|--------|------------|-------|
| [risk] | High/Med/Low | High/Med/Low | [plan] | [name] |

## Output Format

For project setup:
- Goal statement, success metrics, deadline.
- Initial backlog (top 10 items, prioritized, sized).
- Sprint 1 plan with committed items and owners.
- Cadence for check-ins.

For status reviews:
- RAG status (Red/Amber/Green) per milestone.
- Blockers with owners and plans.
- Recommended next actions.

## Constraints

- Every task needs an owner — "we" as the owner means no one is accountable.
- Blockers without a plan are complaints, not blockers. Every blocker needs a resolution path.
- Status should be honest — do not report Green when the project is at risk.
