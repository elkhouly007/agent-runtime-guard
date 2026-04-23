# Skill: Evolve

## Trigger

Use when:
- Ahmed runs `/evolve`
- There are enough confident instincts to cluster into a reusable skill
- After promoting several related instincts, to consolidate them into a single skill file

Command: `/evolve`

## Pre-Conditions

Before starting:
- [ ] `~/.openclaw/instincts/confident.json` exists and is readable
- [ ] At least 3 confident instincts are present (fewer than 3 is not enough signal)
- [ ] Ahmed is available to review the proposed skill before it is written

## Process

### 1. Read confident instincts

```bash
cat ~/.openclaw/instincts/confident.json
```

If the file has fewer than 3 entries, stop:

```
Not enough confident instincts to evolve a skill.
Current count: N
Minimum required: 3

Run /instinct-status to see what's pending promotion.
Promote more instincts first, then re-run /evolve.
```

### 2. Cluster instincts by similarity

Group instincts that share a common theme. Use these signals in order:

1. **`tool_name`** — instincts from the same tool belong together (e.g., all from `code-reviewer`)
2. **`event_type`** — instincts triggered by the same class of event (e.g., `pre-commit`, `pr-review`, `debug-session`)
3. **`tags`** — any shared tag values across instincts
4. **Keyword overlap in `trigger` and `behavior` fields** — look for shared nouns and verbs

Clustering pseudocode:

```
clusters = {}

for each instinct I:
    key = (I.tool_name, I.event_type)
    clusters[key].append(I)

# Merge clusters with the same dominant tags
for each cluster C:
    common_tags = intersection of all tag sets in C
    if common_tags is not empty:
        label cluster with common_tags

# Filter: only keep clusters with >= 2 instincts
clusters = [C for C in clusters if len(C) >= 2]

# Sort clusters by size descending (strongest signal first)
clusters.sort(key=len, reverse=True)
```

If no cluster has 2 or more instincts, report:

```
Instincts are too varied to cluster automatically.
Suggest manually grouping related instincts and promoting more on each theme.
```

### 3. Propose a skill name and structure for each cluster

For each cluster, derive:

- **Skill name**: combine `tool_name` + dominant `event_type` or tag (e.g., `pr-review-checklist`, `debug-session-opener`, `commit-hygiene`)
- **Title**: humanized version of the skill name
- **Trigger**: summarize the common trigger pattern across the cluster's instincts
- **Process steps**: extract the `behavior` field from each instinct and order them logically (not by date — by workflow position)
- **Evidence**: list the instinct `id` values the cluster was built from

Present the proposed structure to Ahmed before writing anything:

```
Proposed skill: pr-review-checklist
Based on 4 instincts: [a1b2c3d4, f9e87654, 00cc1122, 3344aabb]

Title: PR Review Checklist
Trigger: Use at the start of any PR review session.
Process:
  1. Ask for the linked ticket if none is provided.
  2. Read the full diff before commenting on any single line.
  3. Check for missing tests on any new exported function.
  4. Run lint locally before leaving a style comment.

Write this skill to ~/.claude/skills/evolved-pr-review-checklist.md?
(yes / no / edit)
```

If Ahmed says **edit**: prompt for what to change, revise, and show again.
If Ahmed says **no**: discard that cluster and move to the next.
If Ahmed says **yes**: proceed to step 4.

### 4. Write the evolved skill file

Write to `~/.claude/skills/evolved-[name].md` using the following template:

```markdown
# Skill: [Title]

> Evolved from instincts: [id1, id2, id3, ...]
> Evolved on: [today's date]

## Trigger

[Trigger text derived from cluster]

## Process

[Numbered steps extracted from behavior fields]

## Evidence

This skill was derived from the following confident instincts:

| ID | Trigger summary | Behavior summary |
|----|-----------------|------------------|
| id1 | ... | ... |
| id2 | ... | ... |

## Notes

- This skill was auto-generated. Review and adjust steps to match your workflow.
- To update: edit this file directly or re-run /evolve after promoting new instincts.
```

### 5. Mark source instincts as evolved

After writing the file, update `confident.json`: for each instinct in the cluster, set `status: "evolved"`.

Do not remove them from the file — they stay in the store as a record.

```bash
# Verify the evolved skill was written
cat ~/.claude/skills/evolved-[name].md

# Verify status was updated
cat ~/.openclaw/instincts/confident.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
evolved = [i for i in data if i['status'] == 'evolved']
print(f'{len(evolved)} instincts marked as evolved')
for i in evolved:
    print(f'  {i[\"id\"][:8]} — {i[\"behavior\"][:60]}')
"
```

### 6. Report completion

```
Evolved skill written: ~/.claude/skills/evolved-pr-review-checklist.md
Source instincts marked as evolved: 4
Remaining confident instincts available for future /evolve runs: N
```

## Example Evolved Skill Output

```markdown
# Skill: PR Review Checklist

> Evolved from instincts: a1b2c3d4, f9e87654, 00cc1122, 3344aabb
> Evolved on: 2026-04-19

## Trigger

Use at the start of any PR review session, especially when the PR has no linked ticket
or when reviewing code with shared utility functions.

## Process

1. Ask for the linked ticket number if the PR description does not include one.
2. Read the full diff before commenting on any single line — context matters.
3. Check every new exported function for a corresponding test.
4. Run the linter locally before leaving any style-related comment.

## Evidence

| ID | Trigger summary | Behavior summary |
|----|-----------------|------------------|
| a1b2c3d4 | PR with no linked issue | Ask for ticket before starting |
| f9e87654 | First look at PR diff | Read full diff before commenting |
| 00cc1122 | New exported function | Check for missing test coverage |
| 3344aabb | Style comment about formatting | Run lint before commenting on style |

## Notes

- This skill was auto-generated. Review and adjust steps to match your workflow.
- To update: edit this file directly or re-run /evolve after promoting new instincts.
```

## Safe Behavior

- Does not write any file without Ahmed's explicit approval.
- Does not modify `confident.json` until after the file has been successfully written.
- Does not delete or hard-remove any instinct — only sets `status: "evolved"`.
- If the target skill file already exists, warn before overwriting: "File already exists. Overwrite? (yes/no)"
