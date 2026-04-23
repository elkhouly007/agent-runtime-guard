---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# TypeScript Testing Rules

## Framework and Setup

- Use Vitest (preferred for modern projects) or Jest for unit/integration tests.
- Use Playwright for E2E tests.
- Configure coverage: `--coverage` flag, target 80%+ line coverage.
- Run tests in CI on every PR.

```typescript
// vitest.config.ts
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    globals: true,
    environment: "node",
    coverage: {
      provider: "v8",
      reporter: ["text", "html"],
      thresholds: { lines: 80, branches: 75, functions: 80 },
    },
  },
});
```

## Unit Tests

```typescript
// Name: what + expected behavior + condition
it("calculateTotal should return 0 when cart is empty", () => {
  expect(calculateTotal([])).toBe(0);
});

it("calculateTotal should apply discount when code is valid", () => {
  const items = [{ price: 100, qty: 2 }];
  expect(calculateTotal(items, "SAVE10")).toBe(180);
});
```

- One assertion per test where possible.
- Mock at module boundaries — use `vi.mock()` / `jest.mock()` for external deps.
- Avoid testing implementation details — test the public interface.

```typescript
// BAD — testing internals
expect(service["_cache"].size).toBe(1);

// GOOD — test behavior
const result = await service.getUser("123");
expect(result.id).toBe("123");
```

## Integration Tests (API)

- Use `supertest` for HTTP endpoint tests.
- Use a test database — do not mock the database in integration tests.
- Clean up test data after each test with `afterEach` / transactions.
- Test status codes, response shape, and side effects.

```typescript
import request from "supertest";
import { app } from "../app";
import { db } from "../db";

afterEach(async () => {
  await db.query("DELETE FROM users WHERE email LIKE '%@test.com'");
});

it("POST /users returns 201 and created user", async () => {
  const res = await request(app)
    .post("/users")
    .send({ email: "ahmed@test.com", name: "Ahmed" });

  expect(res.status).toBe(201);
  expect(res.body).toMatchObject({ email: "ahmed@test.com" });
  expect(res.body.id).toBeDefined();
});
```

## React Component Tests

- Use `@testing-library/react` — query by accessible roles, not implementation.
- Prefer `userEvent` over `fireEvent` for user interactions.
- Test what the user sees and does, not component internals.

```typescript
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

it("submits form with user input", async () => {
  const onSubmit = vi.fn();
  render(<LoginForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByRole("textbox", { name: /email/i }), "a@b.com");
  await userEvent.click(screen.getByRole("button", { name: /login/i }));

  expect(onSubmit).toHaveBeenCalledWith({ email: "a@b.com" });
});

// BAD — queries by class, brittle
screen.getByClassName("submit-btn");

// GOOD — queries by role
screen.getByRole("button", { name: /submit/i });
```

## TypeScript-Specific

- Type your test factories and fixtures — avoid `as any` in tests.
- Use `satisfies` to type-check test fixtures without widening.
- Mock return types should match the actual interface.

```typescript
// Typed factory function
function makeUser(overrides: Partial<User> = {}): User {
  return {
    id: "1",
    name: "Test User",
    email: "test@example.com",
    ...overrides,
  } satisfies User;
}

// Typed mock
const mockRepo: jest.Mocked<UserRepository> = {
  findById: vi.fn(),
  save: vi.fn(),
};
```

## Fake Timers

```typescript
// BAD — flaky, slow
it("debounces search", async () => {
  // ...
  await new Promise((r) => setTimeout(r, 500));
});

// GOOD — deterministic
it("debounces search", async () => {
  vi.useFakeTimers();
  userEvent.type(input, "query");
  vi.advanceTimersByTime(300);
  expect(mockSearch).toHaveBeenCalledTimes(1);
  vi.useRealTimers();
});
```

## CI Configuration

```bash
# Run all tests with coverage
npx vitest run --coverage

# Run only unit tests
npx vitest run src/

# Run E2E
npx playwright test

# Watch mode (local dev)
npx vitest
```

## Common Mistakes to Avoid

- Mocking the module you are testing.
- `expect(true).toBe(true)` — always-passing assertions.
- Not cleaning up timers, event listeners, or subscriptions.
- Using `setTimeout` in tests — use `vi.useFakeTimers()` instead.
- Testing private methods directly — test through the public API.
- Shared mutable state between tests — always reset mocks in `beforeEach`.
