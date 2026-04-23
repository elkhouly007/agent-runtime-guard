# Skill: continuous-learning

## Purpose

Extract reusable patterns and lessons from a completed work session and save them as skills, rules, or memory entries so future sessions benefit from what was learned.

## Trigger

- At the end of a significant coding session
- After solving a non-obvious bug or architectural problem
- After discovering a library's quirk or an API's behavior
- When a pattern was used repeatedly in a session and would be useful again

## Trigger

`/continuous-learning` or `extract learnings from this session`

## Steps

1. **Review what happened**
   - What problems were solved?
   - What patterns were applied that worked well?
   - What assumptions were wrong that had to be corrected?
   - What library/API behavior was discovered that isn't obvious from docs?

2. **Classify the learning**

   | Type | Save As |
   |------|---------|
   | Reusable code pattern or approach | New skill file in `skills/` |
   | Language/framework rule | New or updated rule in `rules/` |
   | User preference or working style | Memory (`feedback` type) |
   | Project-specific context | Memory (`project` type) |
   | External resource location | Memory (`reference` type) |

3. **Write the artifact**
   - For skills: use the standard skill frontmatter format (name, purpose, trigger, steps, safe behavior).
   - For rules: add to the appropriate language rule file under `rules/`.
   - For memory: save to `/home/khouly/.claude/projects/.../memory/` with correct frontmatter.

4. **Validate the artifact**
   - Does it generalize beyond the current session?
   - Is it non-obvious — would a competent developer already know this?
   - If yes to both, save it. If no, skip — avoid saving noise.

5. **Update the index**
   - If saving a skill: add it to `scripts/status-summary.sh`.
   - If saving to memory: update `MEMORY.md` index.

## What NOT to Save

- Things that are in official documentation and easily findable.
- Session-specific details that don't generalize (e.g., "we used user ID 42 for testing").
- Things already covered by existing rules or skills.
- Debugging steps that only apply to a one-off error.

## Output Format

```markdown
## Session Learnings — YYYY-MM-DD

### Saved as Skills
- `skills/foo-patterns.md` — [one-line description]

### Saved as Rules
- Added to `rules/python/testing.md` — [what was added]

### Saved as Memory
- `memory/feedback_foo.md` — [one-line description]

### Discarded (too specific / already documented)
- [list any items considered but not saved]
```

## Safe Behavior

- Only writes to `skills/`, `rules/`, or `memory/` — does not modify source code.
- Never saves credentials, tokens, or personal data.
- Requires confirmation before saving to memory — memory persists across all future sessions.
