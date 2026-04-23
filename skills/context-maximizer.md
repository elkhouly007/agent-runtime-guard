# Skill: context-maximizer

---
name: context-maximizer
description: Structure the context window for maximum agent performance — what to include, what to exclude, and how to organize information for different agent types
---

# Context Maximizer

Get more from every agent interaction by loading the right context in the right order.

## When to Use


## The Context Window Budget

Every agent has a finite context window. Spending it on irrelevant content degrades output quality. Budget deliberately:

- 20% — problem statement and constraints
- 40% — relevant code (the actual files/functions involved)
- 20% — relevant rules/patterns
- 10% — examples of desired output format
- 10% — negative examples (what NOT to do)

## What to Always Include

1. **The question or task** — stated precisely at the top
2. **The relevant code** — not the whole repo; the specific functions/files
3. **The constraint** — what you cannot change, what the requirements are
4. **The output format** — what structure you want back

## What to Exclude

- Files you aren't asking about
- Verbose stack traces (summarize them: "TypeError at line 42: cannot read 'id' of undefined")
- Repeated history of what has already been tried (mention it once concisely)
- Large blobs of configuration that are irrelevant to the question

## Ordering Matters

Place the most important information early. Models attend more strongly to content at the beginning and end of context:

```
[Task description]
[Most relevant code]
[Secondary context]
[Output format specification]
```

## For Code Review Agents

Include:
- The diff (not the whole file unless the whole file is context-sensitive)
- The PR description or commit message
- The rules/standards the code is supposed to follow

Exclude:
- Unrelated files that happen to be in the same PR
- CI output for checks that passed

## For Architecture Agents

Include:
- Current structure (directory tree is often sufficient)
- The specific decision to make
- Constraints (performance requirements, team size, existing technology choices)

## For Debug Agents

Include:
- The exact error message and stack trace
- The exact code that triggers it
- What you expected vs what happened
- What you have already ruled out

Exclude: Speculation. State facts, not theories.

## Context Compression Technique

When a file is too long to include fully:
1. Include the function signature + first 10 lines
2. Add `// ... [150 lines omitted — this function only reads from db, no side effects]`
3. Include the relevant section in full
