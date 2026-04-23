# Skill: Plan Feature

## Trigger

Use before starting any feature that:
- Spans more than 2 files
- Requires a database schema change
- Touches authentication, authorization, or billing
- Introduces a new external dependency or integration
- Requires architectural decisions

**Do not plan trivial changes.** A one-liner fix or a simple CRUD endpoint does not need a plan.

## Pre-Planning Gate

Answer these before generating a plan:
1. Is the goal clear and unambiguous? If not — clarify first, plan second.
2. Who is the user of this feature? What problem does it solve?
3. Is there existing code that handles something similar?
4. Are there constraints (performance, security, backwards-compat)?

If any answer is "I don't know" — read the relevant code and gather context before proceeding.

## Process

### 1. Understand the current state
```bash
git log --oneline -20                      # recent context
grep -rn "relevant_function" src/          # find related code
```
Read the key files — don't plan against code you haven't read.

### 2. Delegate to planner agent
Pass to `planner` agent:
- The feature goal in plain language
- The relevant existing files
- Constraints (language, framework, APIs to use/avoid)
- Any known risks

### 3. For architectural decisions → consult architect agent
If the feature changes:
- Data model / schema
- API contract (new endpoints, changed signatures)
- Service boundaries
- Caching or queuing strategy
→ Also consult `architect` agent for a second-opinion on the design.

### 4. Risk assessment before finalizing
For each phase in the plan, label:
- `LOW` — isolated change, easy to revert
- `MEDIUM` — affects other components, needs testing coordination
- `HIGH` — database migration, external integration, auth change, irreversible

**Any HIGH-risk step must be explicitly called out in the plan** with a mitigation strategy.

## Output Format

```markdown
## Feature Plan: [Feature Name]

### Overview
What this feature does and why.

### Requirements
- Functional: ...
- Non-functional: performance, security, compat constraints

### Architecture Impact
- New/changed files: list them
- Database changes: yes/no — if yes, migration strategy
- API changes: yes/no — backwards compatible?
- New dependencies: list them with justification

### Implementation Phases

#### Phase 1: [Name] — Risk: LOW/MEDIUM/HIGH
- [ ] Step with file path and what changes
- [ ] Step ...
- Tests: what to verify after this phase

#### Phase 2: ...

### Testing Strategy
- Unit: what to unit test
- Integration: what to integration test
- E2E: what needs end-to-end coverage

### Risk Register
| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| ... | LOW/MED/HIGH | ... | ... |

### Success Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] All tests pass, no regressions
```

## Common Planning Mistakes

- **Overplanning**: A 3-file feature does not need 10 phases. Match depth to complexity.
- **Skipping the read step**: Plans built on assumptions about existing code are wrong.
- **No rollback path**: Every HIGH-risk step needs a way back.
- **Missing test strategy**: A plan without a testing strategy is incomplete.
- **Ignoring migrations**: Schema changes in production need up AND down migrations.

## Safe Behavior

- Planning is read-only — no code written during the planning phase.
- Plan must be reviewed before execution begins.
- HIGH-risk steps are flagged explicitly — they require Ahmed's sign-off before execution.
- Do not execute any part of the plan while still planning another part.
