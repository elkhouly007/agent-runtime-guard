# Skill: multi-agent-debug

---
name: multi-agent-debug
description: Debug multi-agent workflows where one agent's output is feeding another and the pipeline is producing wrong results
---

# Multi-Agent Debug

Diagnose failures in agent pipelines where output from one agent is the input to another.

## When to Use


## Common Failure Modes

1. **Context corruption**: Agent A's output is too long or malformed for Agent B to process
2. **Scope creep**: Agent A's output includes assumptions Agent B contradicts
3. **Format mismatch**: Agent A outputs prose; Agent B expects structured data
4. **Compounding errors**: Agent A makes a subtle mistake that Agent B amplifies
5. **Missing handoff**: Agent A doesn't include the artifact Agent B needs

## Step 1: Isolate the Stage

```
Pipeline: Planner → Architect → SecurityReviewer → TDDGuide → CodeReviewer

Failure observed: CodeReviewer output is generic and misses the architecture

Hypothesis: CodeReviewer is not receiving the Architect output as context
```

Run each stage manually and inspect output before passing to the next.

## Step 2: Validate Handoff Format

Each agent's output should include:
- A clear summary of what was decided/produced
- Specific artifacts (file names, function signatures, test cases)
- Explicit "handoff note" for the next agent

Add this to the prompting chain:
```
End your output with:
## Handoff to Next Agent
[State what the next agent needs to know to continue]
```

## Step 3: Reduce Context Window Pressure

If the pipeline is N agents deep, each accumulating context:
- Extract only the relevant artifact from each stage
- Pass just the plan (not the planning discussion) to the architect
- Pass just the architecture decision (not the analysis) to the security reviewer

## Step 4: Add Checkpoints

After each agent in the pipeline:
```
Does this output answer: [specific question]?
YES → proceed
NO → re-run agent with: [correction]
```

## Step 5: Trace the Error Origin

If the final output is wrong, binary-search the pipeline:
- Does Agent A's output alone look correct?
- Does Agent B's output (given A's) look correct?
- Does Agent C's output (given A+B's) look correct?

The first stage where the output looks wrong is where the fix belongs.
