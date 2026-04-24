---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Web Testing

Standards for testing web applications.

## Testing Pyramid

- Unit tests: pure functions, hooks, utilities — fast, many, isolated.
- Component tests: render a component, interact, assert output — Vitest + Testing Library.
- Integration tests: multiple components + data layer working together.
- E2E tests: critical user flows in a real browser — Playwright.

## Component Testing with Testing Library

Test behavior, not implementation:

```tsx
import { render, screen, userEvent } from '@testing-library/react';

test('submits form with valid data', async () => {
  const user = userEvent.setup();
  const onSubmit = vi.fn();

  render(<LoginForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText('Email'), 'alice@example.com');
  await user.type(screen.getByLabelText('Password'), 'secret');
  await user.click(screen.getByRole('button', { name: 'Log in' }));

  expect(onSubmit).toHaveBeenCalledWith({
    email: 'alice@example.com',
    password: 'secret',
  });
});
```

## Querying Best Practices

Priority order (Testing Library):
1. `getByRole` — tests accessibility too
2. `getByLabelText` — form elements
3. `getByPlaceholderText` — fallback
4. `getByText` — static content
5. `getByTestId` — last resort

Never query by class name or implementation details.

## Async Testing

```tsx
await waitFor(() => expect(screen.getByText('Saved')).toBeInTheDocument());
await screen.findByText('Saved');  // shorthand
```

## E2E with Playwright

```ts
test('user can complete checkout', async ({ page }) => {
  await page.goto('/cart');
  await page.getByRole('button', { name: 'Checkout' }).click();
  await page.getByLabel('Card number').fill('4242 4242 4242 4242');
  await page.getByRole('button', { name: 'Pay now' }).click();
  await expect(page.getByText('Order confirmed')).toBeVisible();
});
```

## Visual Regression

- Storybook for component documentation and visual snapshots.
- Chromatic or Percy for automated visual regression in CI.
- Snapshot tests for stable, intentionally static output only.

## Accessibility Testing

- `axe-core` via `@axe-core/playwright` or `jest-axe` for automated a11y checks.
- Keyboard navigation test: complete a user flow using only Tab/Enter/Escape.
- Screen reader spot checks for critical flows.
