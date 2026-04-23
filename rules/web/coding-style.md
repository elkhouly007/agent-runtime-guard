# Web Coding Style

Standards for web frontend development.

## HTML

- Semantic elements: `<nav>`, `<main>`, `<article>`, `<section>`, `<aside>`, `<header>`, `<footer>` over generic `<div>`.
- Every `<img>` has a meaningful `alt` attribute (empty `alt=""` for decorative images).
- Forms use `<label for="id">` paired with `<input id="id">`.
- Headings follow document outline hierarchy (`h1` → `h2` → `h3`). One `h1` per page.

## CSS

- Mobile-first responsive design: base styles for small viewports, `min-width` media queries for larger.
- CSS custom properties (variables) for design tokens: colors, spacing, typography.
- BEM naming convention for component CSS: `block__element--modifier`.
- Avoid `!important` except to override third-party styles.
- Logical properties (`margin-inline`, `padding-block`) for internationalization.

## JavaScript

- `const` by default, `let` when reassignment is needed. Never `var`.
- Arrow functions for callbacks. Named functions for top-level declarations.
- Destructuring for object and array access.
- Optional chaining (`?.`) and nullish coalescing (`??`) over manual null checks.
- Async/await over raw Promises for readability.

## Component Design

- One component per file.
- Props interface explicitly typed (TypeScript).
- Keep components small: split when a component exceeds ~150 lines or handles >2 responsibilities.
- Separate display (presentational) components from data-fetching (container) components.
- Shared UI primitives in a design system layer, not duplicated across features.

## File Organization

```
src/
  components/       # reusable UI primitives
  features/         # feature-scoped components + logic
  hooks/            # shared custom hooks
  lib/              # framework-agnostic utilities
  styles/           # global styles, design tokens
```
