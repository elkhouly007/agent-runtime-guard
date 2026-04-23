---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Coding Style — Common Rules

These rules apply across all languages and projects unless a language-specific rule overrides them.

## Naming

Names are self-documenting. A reader should understand intent without reading the implementation.

```typescript
// BAD
const l = users.filter(u => u.a);
function getData(id: string) { ... }
let notActive: boolean;

// GOOD
const activeUsers = users.filter(u => u.isActive);
function fetchUserById(id: string) { ... }
let isActive: boolean;
```

```python
# BAD
def get(x): ...
data = [i for i in lst if i.f]

# GOOD
def fetch_order_by_id(order_id: str): ...
fulfilled_orders = [o for o in orders if o.is_fulfilled]
```

Rules:
- Variables: name what they contain (`userList`, not `list`, not `l`).
- Functions: name what they do (`fetchUserById`, not `getData`).
- Booleans: affirmative predicates only (`isActive`, `hasPermission` — never `notActive`).
- Constants: `SCREAMING_SNAKE_CASE` for module-level constants.
- Abbreviations: only universally understood domain terms (`url`, `id`, `api`, `ctx`).

## Functions

```typescript
// BAD — does three things, 7 params, side effect hidden in a getter
function processUserData(id, name, email, role, created, active, sendEmail) {
  const user = getUser(id);  // mutates cache as side effect
  // ... 60 more lines
}

// GOOD — single responsibility, parameter object, pure query separate from command
interface CreateUserInput { name: string; email: string; role: Role; }
async function createUser(input: CreateUserInput): Promise<User> { ... }
async function sendWelcomeEmail(user: User): Promise<void> { ... }
```

Rules:
- One function does one thing.
- Maximum 30-50 lines (extract if longer).
- Maximum 3-4 parameters; beyond that use a parameter object/struct.
- Functions named like queries (`getUser`) must not modify state.
- Prefer pure functions — easier to test, easier to reason about.

## Files and Modules

```
// BAD — one file: UserService.ts handles auth, profile, billing, notifications (600 lines)
// GOOD — split into: auth.service.ts, profile.service.ts, billing.service.ts
```

- One primary concern per file.
- Files over 200-300 lines are a candidate for decomposition.
- Circular dependencies are a design smell — resolve by extracting shared types or inverting the dependency.
- Imports at the top of the file, ordered: stdlib → third-party → internal.

## Comments

```typescript
// BAD — describes the what (obvious from the code)
// Loop through items
for (const item of items) { ... }

// BAD — commented-out dead code
// await legacySync(user);

// GOOD — explains the why
// Retry up to 3 times; the payment provider returns 502 on cold starts
for (let attempt = 0; attempt < MAX_PAYMENT_RETRIES; attempt++) { ... }
```

- Comments explain *why*, not *what*.
- Outdated comments that contradict the code must be deleted, not updated later.
- Complex algorithms get a reference link or a short derivation note.
- No commented-out code in commits.

## Magic Values

```typescript
// BAD
if (retries > 3) { ... }
if (status === "A") { ... }

// GOOD
const MAX_RETRIES = 3;
const STATUS_ACTIVE = "A" as const;
if (retries > MAX_RETRIES) { ... }
if (status === STATUS_ACTIVE) { ... }
```

```python
# GOOD (Python)
MAX_RETRIES = 3
STATUS_ACTIVE = "A"
```

## Error Handling

```typescript
// BAD — swallowed silently
try {
  await saveOrder(order);
} catch (_) {}

// BAD — error without context
console.log("Error:", err.message);

// GOOD — handled or propagated; logged with context
try {
  await saveOrder(order);
} catch (err) {
  logger.error("Failed to save order", { orderId: order.id, err });
  throw new AppError("ORDER_SAVE_FAILED", { cause: err });
}
```

- Every error is either handled with a recovery path or propagated with context added.
- Error messages describe what went wrong and where — never just "Something went wrong".
- Never use empty `catch` blocks.

## Consistency

- Follow existing conventions in the codebase you are working in.
- A consistently mediocre style is better than an inconsistent mix of good styles.
- Never disable a linter rule without a comment explaining why.

## Tooling

```bash
# TypeScript / JavaScript
npx prettier --write "src/**/*.{ts,tsx,js}"   # format
npx eslint "src/**/*.{ts,tsx}" --fix           # lint + auto-fix
npx tsc --noEmit                               # type check only

# Python
black .                                        # format
ruff check . --fix                             # lint + auto-fix
ruff format .                                  # ruff-native formatting (faster than black)
mypy src/                                      # type check

# Run all checks before committing
npx lint-staged       # if configured in package.json
pre-commit run --all  # if using pre-commit hooks
```

## Anti-Patterns Table

| Anti-pattern | BAD example | Fix |
|---|---|---|
| Cryptic names | `d`, `tmp`, `data2` | Descriptive: `dueDate`, `retryBuffer`, `invoiceData` |
| Negated booleans | `isNotValid`, `notActive` | `isInvalid`, `isActive` |
| Flag parameter | `createUser(true, false, true)` | Parameter object with named fields |
| Long function | 200-line `processEverything()` | Extract cohesive sub-functions |
| Swallowed error | `catch (_) {}` | Log + rethrow or explicit recovery |
| Magic literals | `status === "A"` | Named constant `STATUS_ACTIVE` |
| Commented-out code | `// await legacySync(user);` | Delete it; git history preserves it |
| Misleading name | `getUser()` that also updates last-seen | Rename or split into two functions |
