# Skill: Refactor

## Trigger

Use when improving code structure, reducing duplication, or modernizing legacy code **without changing behavior**.

Do NOT use this skill for:
- Adding new behavior (use `plan-feature`)
- Fixing a bug while restructuring (separate the fix from the refactor)
- Rewriting something from scratch (that's a new feature, not a refactor)

## Pre-Refactor Gate

Before touching any code:
1. **Tests must exist and pass.** Run them now.
2. If tests are missing → write them first using `tdd` skill. No tests = no refactor.
3. Understand the code you're changing. Read callers, read the full function, not just the block.
4. Confirm the code is not scheduled for deletion (check open issues/PRs).

```bash
# Verify green before starting
npm test
pytest
go test ./...
cargo test
```

## Process

### 1. Delegate to refactor-cleaner agent
Provide:
- The file(s) to refactor
- What the problem is (duplication, complexity, readability)
- Any constraints (must stay backwards-compatible, performance-sensitive, etc.)

### 2. Apply one refactoring at a time
Do not batch multiple refactorings in one commit. Each step should be independently verifiable.

### 3. Run tests after each change
If tests break after a refactoring step, undo the step and diagnose before continuing.

### 4. Commit at each stable point
```bash
git add -p                    # stage only the refactoring change
git commit -m "refactor: ..."
```

## Refactoring Patterns

### Extract Function
**When:** A block of code needs a comment to explain it, or is used in multiple places.
```python
# Before
total = 0
for item in items:
    if item.active:
        total += item.price * (1 - item.discount)

# After
def active_item_price(item):
    return item.price * (1 - item.discount)

total = sum(active_item_price(i) for i in items if i.active)
```

### Extract Variable
**When:** An expression is complex or appears multiple times.
```typescript
// Before
if (user.plan === 'pro' && user.trialEnd > Date.now() && !user.suspended) {

// After
const isActiveProUser = user.plan === 'pro' && user.trialEnd > Date.now() && !user.suspended;
if (isActiveProUser) {
```

### Flatten Nesting (Guard Clauses)
**When:** Deep nesting makes the happy path hard to follow.
```go
// Before
func Process(req Request) error {
    if req != nil {
        if req.Valid() {
            if req.User != nil {
                // actual logic
            }
        }
    }
    return nil
}

// After
func Process(req Request) error {
    if req == nil { return nil }
    if !req.Valid() { return ErrInvalid }
    if req.User == nil { return ErrNoUser }
    // actual logic
}
```

### Consolidate Duplication
**When:** The same logic appears 3 or more times (Rule of Three).
- Fewer than 3 copies → tolerate the duplication; abstraction may be premature.
- 3+ copies → extract to a shared function or utility.

### Rename for Clarity
**When:** A name describes implementation, not intent.
| Bad | Good |
|-----|------|
| `doStuff()` | `calculateTax()` |
| `flag` | `isEmailVerified` |
| `data` | `userProfile` |
| `tmp` | `pendingOrders` |

### Simplify Boolean Logic
```python
# Before
if condition == True:
    return True
else:
    return False

# After
return condition
```

## Rules

- Never mix refactoring with feature changes — separate commits, separate PRs.
- Never refactor code you do not understand — read first.
- Never refactor code scheduled for deletion.
- Keep each step small: if tests break, you should know exactly which line caused it.
- Do not over-abstract: 3+ instances justifies extraction, fewer usually doesn't.

## Safe Behavior

- Tests must pass before AND after every step. A failing test = stop and diagnose.
- No behavior changes — if behavior changes, it is not a refactoring.
- No deletions without confirming the code is unused (`grep -rn` the function name first).
- Commits are separate from feature work.
- Do not rename public API surfaces without checking all callers.
