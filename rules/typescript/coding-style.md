# TypeScript Coding Style

TypeScript-specific coding standards extending the common rules.

## Formatting

- Use Prettier with default settings. No manual overrides.
- ESLint for linting. Extend `@typescript-eslint/recommended` at minimum.
- Import order: external modules first, then internal. Use eslint-plugin-import to enforce.

## Type System Usage

- Enable strict mode in tsconfig.json. `"strict": true` enables the full set of strict type checks.
- Avoid `any`. When you need an escape hatch, use `unknown` and narrow it.
- Avoid non-null assertions (`!`) without a comment explaining why null is impossible.
- Use `as const` for literal types and readonly arrays.
- Prefer `interface` for object shapes intended for extension; `type` for unions, intersections, and mapped types.

## Naming

- Types and interfaces: `PascalCase`.
- Functions and variables: `camelCase`.
- Constants: `UPPER_SNAKE_CASE` for module-level constants that are truly constant.
- Generics: single uppercase letter (`T`, `K`, `V`) for simple type parameters; descriptive names (`TEntity`, `TResponse`) for complex ones.
- Avoid `I` prefix for interfaces (`UserRepository`, not `IUserRepository`).

## Async Patterns

- Always `await` Promises. Never let a Promise float unawait-ed without explicit fire-and-forget documentation.
- Use `Promise.all()` for independent concurrent operations.
- Prefer `async/await` over `.then()` chains for readability.
- Handle errors explicitly: `try/catch` around `await`, or `.catch()` on Promises.

## Module Structure

- One export per file for major abstractions (classes, complex types, primary functions).
- Barrel files (`index.ts`) for grouping related exports. Keep them thin.
- Avoid circular imports. They indicate a dependency design problem.
- Prefer named exports over default exports. Named exports enable better IDE tooling.
