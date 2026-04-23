---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Web Frontend Testing Rules

## Framework Choice

- **Unit/component tests:** Use **Vitest** (preferred for Vite projects) or **Jest** for test running + assertion.
- **Component rendering:** Use **Testing Library** (`@testing-library/react`, `@testing-library/vue`, etc.) — test user behavior, not implementation.
- **End-to-end:** Use **Playwright** — it supports multiple browsers (Chromium, Firefox, WebKit) and is the modern standard.
- **Visual regression:** Use **Playwright** screenshots or **Storybook + Chromatic** if visual consistency is a hard requirement.
- Do not use Enzyme — it is unmaintained and tests implementation details.

## Unit and Component Tests (Testing Library)

```ts
// BAD — testing implementation detail (internal state)
const { instance } = render(<Counter />);
expect(instance.state.count).toBe(0);

// GOOD — test what the user sees
import { render, screen, fireEvent } from '@testing-library/react';

test('counter increments on click', async () => {
    render(<Counter />);
    const button = screen.getByRole('button', { name: /increment/i });
    await userEvent.click(button);
    expect(screen.getByText('Count: 1')).toBeInTheDocument();
});
```

- Query by accessible role, label, or text — never by CSS class or internal component name.
- Prefer `userEvent` over `fireEvent` — it simulates real browser interaction sequences.
- Use `screen.getBy*` (throws if missing) for expected elements, `screen.queryBy*` (returns null) for optional ones.
- Wrap async state updates in `await waitFor(...)` or use `findBy*` queries.

## Vitest Configuration

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        environment: 'jsdom',  // or 'happy-dom' for speed
        globals: true,
        setupFiles: ['./src/test/setup.ts'],
        coverage: {
            provider: 'v8',
            reporter: ['text', 'lcov'],
            thresholds: { lines: 80, functions: 80 },
        },
    },
});
```

- Use `jsdom` environment for DOM-dependent code; use `node` environment for pure logic.
- Set coverage thresholds in CI — fail on regression.

## jsdom Usage

- jsdom does not support layout (no `getBoundingClientRect`, no CSS computed values) — don't test layout-dependent behavior in unit tests; use Playwright for that.
- Mock browser APIs that jsdom doesn't implement: `window.matchMedia`, `IntersectionObserver`, `ResizeObserver`.

```ts
// setup.ts — mock matchMedia
Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation(query => ({
        matches: false,
        media: query,
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
        addEventListener: vi.fn(),
        removeEventListener: vi.fn(),
        dispatchEvent: vi.fn(),
    })),
});
```

## Playwright (E2E)

```ts
// tests/e2e/login.spec.ts
import { test, expect } from '@playwright/test';

test('user can log in', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill('user@example.com');
    await page.getByLabel('Password').fill('secret');
    await page.getByRole('button', { name: 'Log in' }).click();
    await expect(page).toHaveURL('/dashboard');
    await expect(page.getByRole('heading', { name: 'Dashboard' })).toBeVisible();
});
```

- Use locators (`getByRole`, `getByLabel`, `getByText`) — they are auto-waiting and retry-safe.
- Never use `page.$` with CSS selectors in new tests — they don't auto-wait.
- Use `page.waitForURL` or `expect(page).toHaveURL` for navigation assertions.
- Run against `localhost` in CI with the dev server started by `webServer` config.
- Capture screenshots on failure: `use: { screenshot: 'only-on-failure' }` in `playwright.config.ts`.

```ts
// playwright.config.ts
export default defineConfig({
    testDir: './tests/e2e',
    use: {
        baseURL: 'http://localhost:3000',
        screenshot: 'only-on-failure',
        trace: 'retain-on-failure',
    },
    webServer: {
        command: 'npm run dev',
        port: 3000,
        reuseExistingServer: !process.env.CI,
    },
    projects: [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    ],
});
```

## Test Organization

```
src/
  components/
    Button/
      Button.tsx
      Button.test.tsx     ← unit/component tests co-located
tests/
  e2e/
    login.spec.ts         ← E2E tests in separate directory
    checkout.spec.ts
```

- Co-locate unit tests next to source files.
- Keep E2E tests in a top-level `tests/e2e/` directory.
- Name test files `*.test.ts(x)` for unit tests, `*.spec.ts` for E2E.

## What Not to Test

- Don't write E2E tests for every unit-tested scenario — E2E tests are slow; use them for critical user flows only (login, checkout, key CRUD operations).
- Don't snapshot-test large component trees — snapshots break on trivial changes and give false confidence.
- Don't test styling details (color values, pixel sizes) in unit tests — use visual regression or accessibility checks instead.
