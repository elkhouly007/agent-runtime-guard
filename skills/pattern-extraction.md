# Skill: pattern-extraction

---
name: pattern-extraction
description: Extract reusable patterns from a codebase — identify recurring logic that should be abstracted, standardized, or documented
---

# Pattern Extraction

Turn ad-hoc solutions into reusable, documented patterns.

## When to Use


## Step 1: Find Repetition

```bash
# Functions with similar signatures
grep -rn "async function fetch\|async function get\|async function load" \
  --include="*.ts" | head -30

# Similar error handling patterns
grep -rn "try {" --include="*.ts" -A 5 | head -60

# Similar validation logic
grep -rn "if.*null\|if.*undefined\|if.*length === 0" --include="*.ts" | wc -l
```

## Step 2: Classify the Repetition

For each repeated structure, determine:
- **Accidental duplication**: same code written independently — extract to shared function
- **Intentional variation**: similar structure, different behavior — keep, but document the pattern
- **Structural pattern**: an architectural approach worth standardizing

## Step 3: Extract the Pattern

```typescript
// BEFORE: repeated in every service
async function getUser(id: string) {
  try {
    const result = await db.query('SELECT * FROM users WHERE id = $1', [id]);
    return result.rows[0] ?? null;
  } catch (err) {
    logger.error('getUser failed', { id, err });
    throw new DatabaseError('Failed to fetch user', { cause: err });
  }
}

// AFTER: extracted query wrapper
async function dbQuery<T>(sql: string, params: unknown[], context: string): Promise<T[]> {
  try {
    const result = await db.query(sql, params);
    return result.rows;
  } catch (err) {
    logger.error(`${context} failed`, { err });
    throw new DatabaseError(`${context} failed`, { cause: err });
  }
}
```

## Step 4: Document the Pattern

In `rules/<lang>/patterns.md`:
```markdown
## [Pattern Name]

[When to use it]

[Code example]

[When NOT to use it / tradeoffs]
```

## Step 5: Backfill Existing Code

After the pattern is extracted and documented:
1. Find all existing instances with grep
2. Replace them with the new pattern
3. Test that behavior is unchanged
4. One commit per module replaced (not one giant commit)

## Output Format

Pattern extraction summary:
- **Pattern name**: [name]
- **Found in**: [N] locations
- **Extracted to**: `src/lib/[module].ts`
- **Documented in**: `rules/[lang]/patterns.md`
- **Tests added**: [test file]
