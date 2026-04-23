# Skill: E2E Testing

## Trigger

Use when writing, running, or debugging Playwright end-to-end tests for web applications. Covers test authoring, selector strategy, CI setup, and debugging failing tests.

## Core Principles

- E2E tests verify critical user flows, not every interaction — keep the suite small and fast.
- Target: 10-30 E2E tests covering the golden paths (login, key CRUD, checkout, etc.).
- Flaky tests are worse than no tests — fix or delete them; don't let them accumulate.

## Test Authoring

### Selector Strategy

```typescript
// Prefer by role + name (most resilient to UI changes)
page.getByRole('button', { name: 'Submit' })
page.getByRole('textbox', { name: 'Email' })
page.getByRole('link', { name: 'Dashboard' })

// By label text (good for forms)
page.getByLabel('Password')

// By visible text
page.getByText('Welcome back')

// By test ID (when semantic selectors don't work)
page.getByTestId('order-summary')  // <div data-testid="order-summary">

// AVOID — brittle selectors
page.locator('.btn-primary')        // CSS class
page.locator('#submit-btn')         // ID (fine but fragile if ID changes)
page.locator('div > form > button') // structural selectors
```

### Auto-Waiting

Playwright auto-waits for elements to be ready before interacting — do not add manual `waitForTimeout` sleeps:

```typescript
// BAD — manual sleep
await page.click('#submit');
await page.waitForTimeout(2000); // brittle, slow
await expect(page.locator('.result')).toBeVisible();

// GOOD — use Playwright's auto-wait
await page.getByRole('button', { name: 'Submit' }).click();
await expect(page.getByTestId('result')).toBeVisible(); // auto-waits
```

### Assertions

```typescript
// Navigation
await expect(page).toHaveURL('/dashboard');
await expect(page).toHaveTitle('Dashboard | MyApp');

// Visibility
await expect(page.getByText('Success')).toBeVisible();
await expect(page.getByTestId('error-banner')).not.toBeVisible();

// Text content
await expect(page.getByRole('heading')).toHaveText('Welcome, Alice');

// Input value
await expect(page.getByLabel('Email')).toHaveValue('alice@example.com');

// Element count
await expect(page.getByRole('listitem')).toHaveCount(3);
```

### Page Object Model (for large suites)

```typescript
// pages/LoginPage.ts
export class LoginPage {
    constructor(private page: Page) {}

    async goto() {
        await this.page.goto('/login');
    }

    async login(email: string, password: string) {
        await this.page.getByLabel('Email').fill(email);
        await this.page.getByLabel('Password').fill(password);
        await this.page.getByRole('button', { name: 'Log in' }).click();
    }
}

// tests/e2e/login.spec.ts
test('user can log in', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('alice@example.com', 'password');
    await expect(page).toHaveURL('/dashboard');
});
```

Use POM when tests start duplicating selector logic. Don't extract prematurely for small suites.

## Playwright Config

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
    testDir: './tests/e2e',
    fullyParallel: true,
    retries: process.env.CI ? 2 : 0,   // retry on CI, not locally
    reporter: [['html'], ['list']],
    use: {
        baseURL: 'http://localhost:3000',
        screenshot: 'only-on-failure',
        video: 'retain-on-failure',
        trace: 'retain-on-failure',
    },
    projects: [
        { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
        { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
        { name: 'mobile-chrome', use: { ...devices['Pixel 5'] } },
    ],
    webServer: {
        command: 'npm run dev',
        port: 3000,
        reuseExistingServer: !process.env.CI,
    },
});
```

## Debugging Failing Tests

```bash
# Run specific test with headed browser
npx playwright test login --headed

# Run with Playwright inspector (pauses at each step)
npx playwright test login --debug

# Show HTML report from last run
npx playwright show-report

# Run in trace viewer mode
npx playwright test --trace on
npx playwright show-trace trace.zip
```

## CI Setup

```yaml
# .github/workflows/e2e.yml
- name: Install Playwright browsers
  run: npx playwright install --with-deps chromium firefox

- name: Run E2E tests
  run: npx playwright test

- name: Upload test report
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: playwright-report
    path: playwright-report/
```

## Authentication Shortcuts

For tests that require login, use `storageState` to skip login UI on every test:

```typescript
// tests/e2e/setup/auth.setup.ts
import { test as setup } from '@playwright/test';

setup('authenticate', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Email').fill(process.env.TEST_USER_EMAIL!);
    await page.getByLabel('Password').fill(process.env.TEST_USER_PASSWORD!);
    await page.getByRole('button', { name: 'Log in' }).click();
    await page.context().storageState({ path: 'playwright/.auth/user.json' });
});
```

```typescript
// Use saved auth state in tests
use: {
    storageState: 'playwright/.auth/user.json',
}
```

## Constraints

- Never use `page.waitForTimeout` — it creates flakiness. Use `waitForURL`, `waitForResponse`, or assertion-based waiting.
- Never use `force: true` on clicks without understanding why the element is not interactable normally.
- E2E tests must not depend on data left by a previous test — each test sets up its own state.
