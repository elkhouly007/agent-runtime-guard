# Skill: Eval Harness

## Trigger

Use when building an evaluation system for an AI-powered feature: designing eval datasets, scoring criteria, running evals programmatically, or setting up eval-driven development (EDD) to catch regressions in LLM outputs.

## Core Concept

An eval harness is a test suite for AI behavior — it runs a set of inputs through your system and scores the outputs against expected behavior. It enables:
- **Regression detection** — catch when a prompt change degrades behavior
- **Model comparison** — compare models or prompt versions side by side
- **Confidence before shipping** — ship AI features with evidence, not hope

## Eval Dataset Design

### Input Types

```typescript
interface EvalCase {
    id: string;           // unique, stable ID for tracking regressions
    description: string;  // human-readable test name
    input: InputSchema;   // what goes into the system
    expected?: string;    // optional: expected output (for exact/semantic match)
    tags: string[];       // for filtering: ['edge-case', 'happy-path', 'adversarial']
}
```

### Dataset Coverage

A good eval dataset covers:
1. **Golden path** — the common, correct inputs (30-40% of cases)
2. **Edge cases** — empty inputs, long inputs, unusual formatting (20-30%)
3. **Adversarial** — injection attempts, misleading inputs (10-20%)
4. **Regression cases** — specific bugs that were fixed (keep forever)
5. **Domain samples** — real examples from production (with PII removed) (20-30%)

Start with 20-50 eval cases. 200+ cases is a mature suite — don't over-engineer early.

## Scoring Criteria

### Exact Match
```typescript
score = output.trim() === expected.trim() ? 1 : 0;
// Use for: classification, structured output, deterministic answers
```

### Semantic Match (LLM judge)
```typescript
const judgment = await llm.judge({
    instruction: "Does this output correctly answer the question?",
    input: evalCase.input,
    output: actualOutput,
    rubric: ["factually correct", "complete", "no hallucinations"]
});
score = judgment.score; // 0-1
// Use for: open-ended text, summaries, reasoning
```

### Structured Output Validation
```typescript
const parsed = JSON.parse(output);
const result = schema.safeParse(parsed);
score = result.success ? 1 : 0;
// Use for: JSON outputs, function call arguments
```

### Custom Rubric
```typescript
// Multi-criteria scoring
const criteria = {
    relevance: 0.4,      // weight
    accuracy: 0.4,
    conciseness: 0.2,
};
// Score each criterion, apply weights
score = Object.entries(criteria).reduce((total, [key, weight]) => {
    return total + (scores[key] * weight);
}, 0);
```

## Running Evals

```typescript
// Basic eval runner
async function runEval(suite: EvalSuite) {
    const results: EvalResult[] = [];

    for (const evalCase of suite.cases) {
        const output = await system.run(evalCase.input);
        const score = await score(evalCase, output);

        results.push({
            id: evalCase.id,
            input: evalCase.input,
            output,
            expected: evalCase.expected,
            score,
            passed: score >= suite.passingThreshold,
        });
    }

    return {
        total: results.length,
        passed: results.filter(r => r.passed).length,
        score: results.reduce((s, r) => s + r.score, 0) / results.length,
        failures: results.filter(r => !r.passed),
    };
}
```

## Eval-Driven Development (EDD)

The EDD loop:
1. **Write an eval case** for the desired behavior before building it.
2. **Run the eval** — it should fail (red).
3. **Build/improve** the feature until the eval passes (green).
4. **Add to CI** — run evals on every PR that touches the AI layer.

```bash
# Run evals as part of CI
npm run eval:suite -- --suite=summarization --threshold=0.8
# Exit code 1 if suite score < threshold — blocks the PR
```

## Eval File Structure

```
evals/
  datasets/
    summarization-golden.jsonl     ← golden path cases
    summarization-edge.jsonl       ← edge cases
    summarization-regressions.jsonl← known-bad regression cases
  suites/
    summarization.ts               ← suite definition + scoring logic
    extraction.ts
  runners/
    run.ts                         ← CLI runner
  reports/
    2024-01-15-baseline.json       ← saved run results for comparison
```

## Output Format

When designing an eval harness:
- Suite definition: input schema, scoring method, passing threshold, dataset paths.
- Sample of 5-10 eval cases showing distribution across case types.
- Suggested CI integration command.
- Baseline score (first run result) to track progress against.

## Constraints

- Eval cases must be deterministic — same input must always produce the same score (use fixed temperature=0 for LLM outputs under test).
- Do not use LLM judge for cases that have a ground-truth answer — use exact/structural matching instead.
- Evals should be fast enough to run in CI — target under 5 minutes for a suite. Cache expensive LLM calls with a content-hash cache.
