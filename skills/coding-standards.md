# Skill: Coding Standards

## Trigger

Use when establishing or enforcing universal coding standards across a project, onboarding a new team, setting up a code quality baseline, or reviewing code for general correctness and style.

## Universal Principles

These apply regardless of language, framework, or team size:

### Naming

- Names should be self-explanatory — the name should tell you what it does, not how.
- Functions and methods: verb phrases (`calculateTotal`, `sendEmail`, `isValid`).
- Variables and fields: noun phrases (`userId`, `orderCount`, `isLoading`).
- Booleans: prefix with `is`, `has`, `can`, `should` (`isActive`, `hasPermission`).
- Constants: `UPPER_SNAKE_CASE` for true constants; use normal naming for "constant-like" config values.
- Avoid abbreviations unless they are universally understood in the domain (`url`, `id`, `api`, `dto` are fine; `usr`, `mgr`, `proc` are not).

### Functions

- **Single responsibility:** a function does one thing. If you can't describe it in one sentence without "and", split it.
- **Small and focused:** ideally under 20 lines. If it scrolls, it's probably doing too much.
- **No side effects in pure functions:** functions that compute a value should not modify state.
- **Limit parameters:** 3 parameters max. Use an options object for more.
- **Return early to reduce nesting:**

```typescript
// BAD — deep nesting
function processOrder(order) {
    if (order) {
        if (order.status === 'pending') {
            if (order.items.length > 0) {
                // ... actual logic buried here
            }
        }
    }
}

// GOOD — early returns flatten the code
function processOrder(order) {
    if (!order) return;
    if (order.status !== 'pending') return;
    if (order.items.length === 0) return;
    // ... actual logic at top level
}
```

### Variables

- Declare variables as close to their use as possible.
- Prefer immutable (`const`, `val`, `final`) over mutable — mutate only when necessary.
- Avoid magic numbers — extract to named constants:

```typescript
// BAD
if (score > 70) { ... }
setTimeout(fn, 86400000);

// GOOD
const PASSING_SCORE = 70;
const ONE_DAY_MS = 24 * 60 * 60 * 1000;
if (score > PASSING_SCORE) { ... }
setTimeout(fn, ONE_DAY_MS);
```

### Comments

- Code explains **what**. Comments explain **why** — the non-obvious reasoning, the constraint, the workaround.
- Don't comment what is obvious from the code:

```typescript
// BAD — restates the code
user.age += 1; // increment age by 1

// GOOD — explains non-obvious reasoning
// Stripe requires amounts in cents; multiply by 100 to convert from dollars
const amount = price * 100;
```

- Use `TODO:`, `FIXME:`, `HACK:` prefixes for in-code notes so they're searchable.
- Delete commented-out code — use git history instead.

### Error Handling

- Handle errors at the right level — not every function needs a try/catch.
- Catch errors where you can do something useful about them (log, fallback, retry, convert to user-facing message).
- Never swallow errors silently — at minimum log them.
- Use typed/structured errors with error codes, not bare `new Error("something went wrong")`.

```typescript
// BAD — swallowed error
try {
    await sendEmail(user);
} catch (e) {
    // silent failure
}

// GOOD — log and surface
try {
    await sendEmail(user);
} catch (e) {
    logger.error('Failed to send welcome email', { userId: user.id, error: e });
    throw new EmailDeliveryError(`Failed to send email to ${user.id}`, { cause: e });
}
```

### Code Organization

- Group related code together — functions that work together should live near each other.
- Public API at the top of a module, private helpers at the bottom.
- Consistent file structure within a project — new team members should be able to predict where things are.
- Avoid files over 300 lines — if a file is growing large, look for a natural split.

### Testing

- Every non-trivial function should have at least one test.
- Test behavior, not implementation.
- Test names describe the scenario: `"returns null when user not found"`, not `"test getUserById"`.
- Keep tests independent — no shared mutable state between tests.

### Version Control

- Commit messages: imperative tense, present voice — "Add user authentication" not "Added" or "Adding".
- One logical change per commit — not "fix 5 bugs and refactor 3 modules".
- Don't commit broken code to the main branch.
- Review your own diff before pushing — `git diff HEAD` catches obvious mistakes.

## Output Format

When reviewing code against these standards:
- Report findings by category (naming, functions, error handling, etc.).
- For each finding: file/line, issue, concrete fix suggestion.
- Distinguish between style preferences (LOW) and clarity issues (MEDIUM) and correctness bugs (HIGH).
