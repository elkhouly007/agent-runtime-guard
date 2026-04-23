# Skill: TDD (Test-Driven Development)

## Trigger

Use when:
- Starting any new feature or function
- Fixing a bug — the bug itself is a missing test
- Refactoring (tests must exist first)
- The expected behavior can be stated clearly before writing code

## The TDD Cycle

```
RED  → Write a failing test that describes one behavior
GREEN → Write the minimum code to make it pass
REFACTOR → Clean up, then verify green again
repeat
```

**Never skip RED.** A test that was never failing gives no confidence.

## Process

### 1. State the behavior before writing any test
Write it in plain language first:
- "When X, the function should return Y"
- "When the user is not authenticated, the endpoint returns 401"
- "When the input is empty, the function throws ValidationError"

### 2. Write the failing test
Delegate to `tdd-guide` agent if methodology enforcement is needed.

```typescript
// Example: TypeScript/Jest
it('returns 0 for empty cart', () => {
  const cart = new Cart([]);
  expect(cart.total()).toBe(0);
});
```

```python
# Example: Python/pytest
def test_empty_cart_total_is_zero():
    cart = Cart([])
    assert cart.total() == 0
```

```go
// Example: Go
func TestEmptyCartTotal(t *testing.T) {
    cart := NewCart([]Item{})
    if cart.Total() != 0 {
        t.Errorf("expected 0, got %v", cart.Total())
    }
}
```

Run it — **confirm it fails** with the right error (not a syntax error or import error).

### 3. Write minimum passing code
Only enough to make the test pass. No premature generalization.

### 4. Refactor
- Remove duplication
- Rename for clarity
- Extract functions if needed
- Delegate to `refactor-cleaner` if pattern cleanup is involved
- **Tests must stay green throughout**

### 5. Repeat for the next behavior
Add edge case tests one at a time, not all at once.

## Test Coverage Thresholds

| Type | Minimum |
|------|---------|
| New business logic | 100% of stated behaviors |
| New utility functions | 100% of branches |
| Bug fixes | Regression test required (proves the bug existed) |
| Error paths | All exception/error types explicitly tested |
| Edge cases | null / empty / zero / boundary for numeric inputs |

Coverage commands:
```bash
npm run test:coverage      # Node.js / Jest
pytest --cov=src --cov-report=term-missing
go test ./... -cover -coverprofile=coverage.out
cargo tarpaulin            # Rust
```

## Test Naming Convention

Name the test after the behavior, not the function:

| Bad | Good |
|-----|------|
| `test_calculate()` | `test_total_is_zero_for_empty_cart()` |
| `it('works')` | `it('throws when amount is negative')` |
| `TestCart` | `TestCart_ReturnsZeroForEmptyItems` |

## Red Flags That Break TDD

- Writing tests after the code → you're writing confirmation tests, not behavior specs.
- Writing multiple failing tests before making any pass → too many unknowns at once.
- Mocking everything → tests that can't catch integration bugs.
- Testing implementation details → tests that break on every refactor.
- Ignoring flaky tests → they're telling you something is wrong.

## Safe Behavior

- No new code without a failing test first.
- No refactoring without a passing test suite.
- Tests run after every change — failures must be addressed before continuing.
- Do not delete or disable a failing test to make the suite pass.
