# Skill: Eval

## Trigger

Use when you need to verify that code, output, or an agent response meets explicit stated requirements. Different from `/code-review`: eval checks against a spec, code-review checks for quality and correctness in the abstract.

| Use `/eval` when | Use `/code-review` when |
|-----------------|------------------------|
| You have stated requirements ("it must do X") | You want general quality feedback |
| Verifying an agent's output before accepting it | Reviewing a PR or changed file |
| Acceptance criteria come from a ticket or prompt | No spec exists, just the code |
| Scoring is needed (pass/fail per criterion) | Narrative feedback is sufficient |
| Chaining into an automated pipeline | Human review workflow |

## Default Criteria

If no custom criteria are provided, evaluate against these five defaults:

| Criterion | Question |
|-----------|----------|
| **Correctness** | Does it do what was asked? Does it produce correct output for the described inputs? |
| **Completeness** | Are all requirements addressed? Are any edge cases or constraints missing? |
| **Security** | No obvious vulnerabilities: injection, hardcoded secrets, improper auth, exposed data? |
| **Performance** | No obvious bottlenecks: N+1 queries, missing indexes, unbounded loops, unnecessary synchronous I/O? |
| **Style** | Follows project conventions: naming, formatting, file structure, idiomatic patterns for the language? |

## Process

### 1. Define the subject

Identify what is being evaluated:
- A code snippet
- A file or set of files
- An agent's response
- A generated artifact (SQL query, config, API response, test suite)

### 2. Extract or accept criteria

If criteria are passed as arguments, use them. Otherwise:
- Extract from the user's original prompt (look for "it should", "must", "required", "expect")
- Extract from a linked ticket or spec
- Fall back to the five default criteria

### 3. Score each criterion

For each criterion, assign one of three verdicts:

| Verdict | Meaning |
|---------|---------|
| **PASS** | Criterion is fully met with no gaps |
| **PARTIAL** | Criterion is partly met — something is missing or has a flaw that does not break functionality |
| **FAIL** | Criterion is not met, or a critical flaw is present |

Provide a one-line finding explaining the score. If FAIL or PARTIAL, cite the specific location (file:line, or quote the relevant text).

### 4. Calculate overall score

```
score = (PASS × 2 + PARTIAL × 1 + FAIL × 0) / (total_criteria × 2) × 100
```

Round to the nearest integer.

### 5. Produce verdict

| Score | Decision |
|-------|----------|
| 90–100 | Approve — meets all criteria |
| 75–89 | Approve with minor fixes (PARTIAL only, no FAILs) |
| 50–74 | Request changes (one or more PARTIAL/FAIL) |
| 0–49 | Reject — significant criteria failures |

## Output Format

```
## Eval: [subject description]

| Criterion       | Score   | Finding                                      |
|-----------------|---------|----------------------------------------------|
| Correctness     | PASS    | Returns correct totals for all test cases.   |
| Completeness    | PARTIAL | Missing: error case when input list is empty.|
| Security        | PASS    | No injection vectors; input is parameterized.|
| Performance     | FAIL    | N+1 query on line 42 — runs one SELECT per   |
|                 |         | row; use a JOIN or batch fetch instead.       |
| Style           | PASS    | Follows project naming and formatting rules. |

Overall: 60/100 — Request changes (FAIL present)

### Required Fixes
1. **Performance — line 42**: Replace per-row SELECT with a JOIN on `orders`.
2. **Completeness**: Add handling for empty `items` list — currently throws uncaught.

### Optional Improvements
- Consider extracting the query into a repository method for testability.
```

## Custom Criteria

Pass custom criteria as a comma-separated list or structured block:

```
/eval --criteria "handles concurrent writes, idempotent on retry, returns 422 on invalid input"
```

Or define them inline at the top of your eval request:

```
Criteria:
- Must paginate results (max 100 per page)
- Must accept both snake_case and camelCase field names
- Must return 404 (not 500) when resource not found
- Response time < 200ms for typical payloads
```

Each custom criterion is scored the same way as default criteria.

## Chaining with Other Skills

| Next step | When to chain |
|-----------|--------------|
| `/code-review` | After eval passes — do a full quality review before merge |
| `/security-review` | Security criterion FAIL or PARTIAL |
| `/test-coverage` | Completeness FAIL because tests are missing |
| `/refactor` | Style FAIL or Performance FAIL requiring structural change |
| `/tdd` | Output fails correctness and no tests exist to define correct behavior |

Example chain:

```
/eval → score 65 → Request changes
  → /security-review (Security was PARTIAL)
  → /test-coverage (Completeness FAIL — missing tests)
  → re-run /eval after fixes → score 90 → Approve
```

## Safe Behavior

- Read-only analysis — no files are modified.
- Does not auto-approve its own output or the output of another agent without going through the eval process.
- FAIL findings on Security or Correctness require Ahmed's attention before the output is used in production.
- When evaluating agent responses, applies the same rigor as evaluating human-written code.
