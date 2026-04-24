---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Web Performance

Standards for fast web applications.

## Core Web Vitals Targets

- LCP (Largest Contentful Paint): < 2.5s
- INP (Interaction to Next Paint): < 200ms
- CLS (Cumulative Layout Shift): < 0.1

## Asset Optimization

- Images: WebP/AVIF format, `width`+`height` attributes to prevent CLS, lazy-load below fold.
- `<img loading="lazy">` for images below the fold.
- Fonts: `font-display: swap`, preload critical fonts, subset to used characters.
- SVGs inlined for critical icons, external for large or reused ones.
- Bundle splitting: vendor chunk separated from application code.

## JavaScript Performance

- Avoid blocking the main thread: long tasks > 50ms hurt INP.
- Virtualize long lists (react-virtual, tanstack-virtual) over rendering thousands of DOM nodes.
- `useMemo` and `useCallback` only when profiling shows a real problem — they add cognitive overhead.
- Debounce search inputs and resize handlers.
- Web Workers for CPU-intensive computation.

## Loading Strategy

- Preload critical resources: `<link rel="preload" as="font">`.
- Prefetch likely next pages: `<link rel="prefetch">`.
- Lazy-load routes and heavy components with `React.lazy`.
- Critical CSS inlined; non-critical CSS loaded asynchronously.

## Caching

- Static assets: long `Cache-Control: max-age` with content-hashed filenames.
- API responses: `Cache-Control: no-store` for sensitive data; `stale-while-revalidate` for tolerant endpoints.
- Service worker caching for offline-capable apps and repeat visits.

## Measurement

- Lighthouse CI in PR pipeline. Gate on regression.
- Real User Monitoring (RUM) with Core Web Vitals reporting (web-vitals library).
- Performance budget: define and alert on bundle size regressions.
- `performance.mark()` / `performance.measure()` for custom timing of critical user flows.
