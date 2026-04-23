---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# TypeScript Testing

TypeScript-specific testing standards.

## Framework

- Vitest for unit and integration tests. Fast, native TypeScript support, compatible with Jest API.
- Playwright for end-to-end browser tests.
- MSW (Mock Service Worker) for mocking HTTP requests at the network level.
- `@testing-library` for component tests. Prioritize testing user-observable behavior.

## Type-Safe Tests

- Do not use `any` in test code. Type-safe test code catches type errors in the code under test.
- Use typed mock helpers: `vi.fn<Parameters<typeof myFn>, ReturnType<typeof myFn>>()`.
- Test TypeScript-specific behavior: discrimination of union types, narrowing, exhaustiveness.

## Async Testing

- Always `await` async test operations. Missing `await` is a common source of false-passing async tests.
- `waitFor()` from testing-library for asserting on async state changes.
- Never use `setTimeout` with a fixed delay in tests — use proper awaiting or `fakeTimers`.
- Test error cases: rejected Promises, thrown errors in async code.

## Mocking Strategy

- Mock at module boundaries, not at function level.
- `vi.mock()` for module-level mocking. Import the mock and add `vi.mocked()` wrapper for type safety.
- Prefer dependency injection over module-level mocking for complex components.
- Reset mocks between tests: `vi.clearAllMocks()` in `afterEach`.

## Test Organization

- Co-locate tests with source: `auth.ts` next to `auth.test.ts`.
- Separate unit tests from integration tests. Run unit tests on save; integration tests on commit.
- Snapshot tests: use sparingly, for stable outputs (serialization, complex object shapes). Review snapshot diffs carefully.
