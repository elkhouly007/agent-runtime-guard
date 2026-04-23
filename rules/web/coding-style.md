---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Web (HTML/CSS/JS) Coding Style

## HTML

### Semantic Structure

```html
<!-- BAD — div soup; no semantic meaning for assistive technology -->
<div class="header">
  <div class="logo">Brand</div>
  <div class="menu">
    <div class="menu-item"><a href="/">Home</a></div>
  </div>
</div>
<div class="content">
  <div class="post">
    <div class="title">Article Title</div>
    <div class="body">...</div>
  </div>
</div>
<div class="sidebar">...</div>
<div class="footer">...</div>

<!-- GOOD — semantic landmarks; screen readers and search engines understand the structure -->
<header>
  <a href="/" aria-label="Brand home"><img src="logo.svg" alt="Brand"></a>
  <nav aria-label="Primary">
    <ul>
      <li><a href="/">Home</a></li>
      <li><a href="/about">About</a></li>
    </ul>
  </nav>
</header>
<main>
  <article>
    <h1>Article Title</h1>
    <p>Content...</p>
  </article>
</main>
<aside aria-label="Related posts">...</aside>
<footer>...</footer>
```

Rules:
- Use `<nav>`, `<main>`, `<article>`, `<section>`, `<aside>`, `<header>`, `<footer>` — one `<main>` per page.
- `<button>` for actions, `<a href>` for navigation — never swap them.
- Heading hierarchy must be logical (`h1` → `h2` → `h3`) — do not skip levels.
- `lang` attribute on `<html>`; `lang` override on sections in a different language.
- Boolean attributes written without value: `<input required>` not `<input required="true">`.

### Forms and Labels

```html
<!-- BAD — input with no label; placeholder is not a label -->
<input type="email" placeholder="Enter email">

<!-- GOOD — explicit label association -->
<label for="email">Email address</label>
<input type="email" id="email" name="email" autocomplete="email" required>

<!-- GOOD — wrapping label (no for/id needed) -->
<label>
  <input type="checkbox" name="agree"> I accept the terms
</label>

<!-- GOOD — error message associated with the field -->
<label for="email">Email</label>
<input type="email" id="email" aria-describedby="email-error" aria-invalid="true">
<span id="email-error" role="alert">Enter a valid email address.</span>
```

- Decorative images use `alt=""`; informative images have meaningful `alt` text.
- Never use `placeholder` as the sole label — it disappears when the user types.

---

## CSS

### Design Tokens and Variables

```css
/* BAD — magic values scattered across the codebase */
.card {
  padding: 16px;
  border-radius: 8px;
  color: #1a1a2e;
  box-shadow: 0 2px 4px rgba(0,0,0,0.12);
}

/* GOOD — tokens defined once; semantic variable names */
:root {
  --color-surface: #ffffff;
  --color-text-primary: #1a1a2e;
  --color-brand: #4361ee;
  --color-brand-hover: #3a56d4;

  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;

  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-full: 9999px;

  --shadow-card: 0 2px 4px rgb(0 0 0 / 0.12);

  --font-size-sm: clamp(0.8rem, 0.17vw + 0.76rem, 0.89rem);
  --font-size-base: clamp(1rem, 0.34vw + 0.91rem, 1.19rem);
  --font-size-lg: clamp(1.2rem, 0.61vw + 1.1rem, 1.58rem);
}

.card {
  padding: var(--space-md);
  border-radius: var(--radius-md);
  color: var(--color-text-primary);
  box-shadow: var(--shadow-card);
}
```

### Modern Layout

```css
/* BAD — float-based layout (legacy, fragile) */
.container { overflow: hidden; }
.sidebar { float: left; width: 30%; }
.content { float: left; width: 70%; }

/* GOOD — CSS Grid for two-dimensional layout */
.page-layout {
  display: grid;
  grid-template-areas:
    "header header"
    "sidebar content"
    "footer footer";
  grid-template-columns: 280px 1fr;
  grid-template-rows: auto 1fr auto;
  min-height: 100dvh;
}

.page-header  { grid-area: header; }
.page-sidebar { grid-area: sidebar; }
.page-content { grid-area: content; }
.page-footer  { grid-area: footer; }

/* GOOD — Flexbox for one-dimensional component alignment */
.card-actions {
  display: flex;
  gap: var(--space-sm);      /* gap instead of margin between children */
  align-items: center;
  justify-content: flex-end;
}
```

### Media Queries (mobile-first)

```css
/* BAD — desktop-first; overrides required for every smaller screen */
.grid { grid-template-columns: repeat(4, 1fr); }
@media (max-width: 768px) { .grid { grid-template-columns: 1fr; } }

/* GOOD — mobile-first; progressively enhance */
.grid {
  display: grid;
  grid-template-columns: 1fr;          /* base: single column */
  gap: var(--space-md);
}

@media (min-width: 48rem) {            /* tablet+ */
  .grid { grid-template-columns: repeat(2, 1fr); }
}

@media (min-width: 75rem) {            /* desktop+ */
  .grid { grid-template-columns: repeat(4, 1fr); }
}
```

Rules:
- Avoid `!important` — it signals specificity debt that should be fixed at the source.
- Use logical properties (`margin-inline`, `padding-block`) for i18n / RTL support.
- Use `aspect-ratio` instead of padding-percentage hacks.
- Never inline styles in HTML — styles belong in CSS files or design-system components.

---

## JavaScript (Vanilla / Browser)

### DOM Safety

```javascript
// BAD — innerHTML with user data → XSS
container.innerHTML = `<p>Welcome, ${user.name}!</p>`;

// BAD — document.write blocks parsing and enables XSS
document.write('<script src="' + userInput + '"><\/script>');

// GOOD — textContent for plain text (no XSS risk)
const p = document.createElement('p');
p.textContent = `Welcome, ${user.name}!`;
container.appendChild(p);

// GOOD — when HTML is required, sanitize first
import DOMPurify from 'dompurify';
container.innerHTML = DOMPurify.sanitize(htmlFromServer);
```

### Event Handling

```javascript
// BAD — attaching listener to each dynamic item (memory leak as items are added)
document.querySelectorAll('.btn').forEach(btn => {
  btn.addEventListener('click', handleClick);
});

// GOOD — event delegation (one listener; works for dynamic items)
document.getElementById('btn-container').addEventListener('click', (e) => {
  const btn = e.target.closest('[data-action]');
  if (!btn) return;
  handleAction(btn.dataset.action);
});

// BAD — anonymous function; can never be removed
element.addEventListener('resize', () => layout());

// GOOD — named reference so it can be cleaned up
const onResize = () => layout();
window.addEventListener('resize', onResize);
// When element is removed:
window.removeEventListener('resize', onResize);
```

### Async and Fetch

```javascript
// BAD — XMLHttpRequest (verbose, callback-based)
const xhr = new XMLHttpRequest();
xhr.open('GET', '/api/users');
xhr.onload = () => { if (xhr.status === 200) parse(xhr.responseText); };
xhr.send();

// BAD — fetch without error handling (network error ≠ HTTP error)
const data = await fetch('/api/users').then(r => r.json());

// GOOD — handle both network and HTTP errors explicitly
async function fetchUsers() {
  const response = await fetch('/api/users', {
    headers: { 'Accept': 'application/json' },
    signal: AbortSignal.timeout(5000),  // 5s timeout
  });
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`);
  }
  return response.json();
}

// BAD — sequential awaits when requests are independent
const user  = await fetchUser(id);
const prefs = await fetchPrefs(id);
const feed  = await fetchFeed(id);

// GOOD — parallel (total time = max of the three, not sum)
const [user, prefs, feed] = await Promise.all([
  fetchUser(id), fetchPrefs(id), fetchFeed(id),
]);
```

Rules:
- Prefer `const` over `let`; avoid `var`.
- Use `requestAnimationFrame` for visual updates, not `setTimeout`.
- Never block the main thread with synchronous I/O or long computation — use workers.

---

## Accessibility (WCAG 2.1 AA)

| Requirement | Target | How to test |
|---|---|---|
| Color contrast (normal text) | ≥ 4.5:1 | axe DevTools, Colour Contrast Analyser |
| Color contrast (large text / UI) | ≥ 3:1 | axe DevTools |
| Keyboard navigability | All interactive elements reachable | Tab through the page manually |
| Focus indicator | Visible on all interactive elements | Tab + inspect visual focus ring |
| ARIA labels | Only where native semantics are insufficient | NVDA/VoiceOver screen reader test |
| Error association | `aria-describedby` links input to error | axe automated scan |
| Focus management | Modal: trap focus in; restore on close | Manual test with keyboard only |

```html
<!-- GOOD — dialog with focus trap and restore -->
<dialog id="confirm-modal" aria-labelledby="modal-title">
  <h2 id="modal-title">Confirm deletion</h2>
  <p>This action cannot be undone.</p>
  <button id="cancel-btn">Cancel</button>
  <button id="confirm-btn" class="btn-danger">Delete</button>
</dialog>
```

```javascript
// Focus management for custom modal
function openModal(modal, triggerEl) {
  modal.showModal();
  modal.querySelector('[autofocus], button')?.focus();
  modal.addEventListener('close', () => triggerEl.focus(), { once: true });
}
```

---

## Performance

```html
<!-- BAD — render-blocking script in <head> -->
<head>
  <script src="app.js"></script>
</head>

<!-- GOOD — defer non-critical; type="module" defers automatically -->
<head>
  <link rel="preload" href="hero.webp" as="image">
  <link rel="preload" href="fonts/inter.woff2" as="font" crossorigin>
  <script src="app.js" defer></script>
  <!-- or: <script type="module" src="app.js"></script> -->
</head>

<!-- BAD — unoptimized image; no size hints; no lazy loading -->
<img src="photo.jpg">

<!-- GOOD — modern format, explicit dimensions, lazy below fold -->
<picture>
  <source srcset="photo.avif" type="image/avif">
  <source srcset="photo.webp" type="image/webp">
  <img src="photo.jpg" alt="Team photo" width="800" height="600" loading="lazy">
</picture>
```

```css
/* Font loading — prevent invisible text (FOIT) */
@font-face {
  font-family: 'Inter';
  src: url('inter.woff2') format('woff2');
  font-display: swap;   /* show fallback immediately; swap when loaded */
}
```

---

## Tooling

```bash
# Format HTML, CSS, JS
npx prettier --write "src/**/*.{html,css,js,ts,tsx}"

# Lint CSS — enforce conventions (stylelint)
npx stylelint "src/**/*.css" --fix

# Lint JS/TS — enforce best practices
npx eslint "src/**/*.{js,ts}" --fix

# Type-check TypeScript
npx tsc --noEmit

# Accessibility — automated axe scan on built pages
npx @axe-core/cli http://localhost:3000

# Lighthouse — performance + a11y + SEO (CI mode)
npx lighthouse-ci autorun --upload.target=temporary-public-storage

# Bundle size analysis (webpack)
npx webpack-bundle-analyzer dist/stats.json

# Bundle size analysis (Vite)
npx vite-bundle-visualizer

# HTML validation
npx html-validate "dist/**/*.html"
```

---

## Anti-Patterns

| Anti-pattern | Why it hurts | Fix |
|---|---|---|
| `innerHTML` with user data | XSS — script injection | `textContent`; or DOMPurify for HTML |
| `div` / `span` instead of semantics | Inaccessible; poor SEO; fragile CSS | Semantic elements: `<nav>`, `<button>`, etc. |
| Placeholder as the only label | Disappears when user types; fails WCAG | Explicit `<label>` + `for`/`id` association |
| `!important` in CSS | Specificity arms race; unmaintainable | Fix specificity at source; use BEM / layers |
| Magic color/spacing values | Inconsistent UI; hard to theme | Custom properties (`--color-brand: #4361ee`) |
| Render-blocking scripts in `<head>` | Delays FCP/LCP; poor Core Web Vitals | `defer` or `type="module"` |
| `<img>` without `width`/`height` | Cumulative Layout Shift (CLS) | Always set `width` + `height` attributes |
| No `font-display` on `@font-face` | Invisible text until font loads (FOIT) | `font-display: swap` |
| Per-element event listeners on lists | Memory leak; breaks for dynamic items | Event delegation on stable parent |
| Sequential `await` for independent fetches | N× latency instead of max-latency | `Promise.all([...])` |
| `max-width` media queries (desktop-first) | Heavy overrides for every smaller screen | `min-width` queries; mobile-first base |
| Missing `alt` on informative images | Screen readers skip meaningful content | Meaningful `alt` text; `alt=""` for decorative |
