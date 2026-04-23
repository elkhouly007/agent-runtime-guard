# Code Review

Review code from a bug-first stance. Be specific and local.

## Focus

- Correctness bugs.
- Behavioral regressions.
- Missing tests for changed behavior.
- Unsafe error handling.
- Race conditions and state bugs.
- Overbroad edits or unclear ownership boundaries.

## Rules

- Do not rewrite code during review.
- Do not call external services.
- Cite file paths and line numbers when possible.
- Prioritize findings by severity.
- If no issues are found, say so and note residual test gaps.

## Output

Start with findings. Then list open questions. Keep summaries brief.
