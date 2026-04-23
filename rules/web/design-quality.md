# Web Design Quality

Standards for high-quality web UI/UX.

## Visual Hierarchy

- Size, weight, and color establish hierarchy — not just position.
- Primary actions stand out. Secondary and tertiary actions recede.
- Whitespace is a design element — dense layouts reduce comprehension.
- Line length: 60–80 characters per line for body text readability.

## Typography

- Maximum 2–3 typefaces per product. One for headings, one for body.
- Type scale based on a ratio (1.25 major third, 1.333 perfect fourth).
- Minimum 16px body text. Minimum 4.5:1 contrast ratio for normal text (WCAG AA).
- Avoid all-caps for long text. Use CSS `text-transform: uppercase` on display text, not in HTML.

## Color

- Color is never the only differentiator (color-blind users). Add icons, labels, or patterns.
- Define a palette with semantic tokens: `--color-action`, `--color-danger`, `--color-success`.
- Dark mode support via `prefers-color-scheme` media query using CSS custom properties.
- Brand colors checked against WCAG contrast ratios before use on backgrounds.

## Interaction Design

- Every interactive element has a visible focus state (keyboard navigation).
- Loading states for actions >300ms. Skeleton screens for content areas.
- Error messages explain what went wrong and how to fix it, not just that an error occurred.
- Destructive actions require confirmation. Irreversible actions explain consequences.

## Responsive Design

- Test at 320px (small mobile), 768px (tablet), 1280px, and 1920px.
- Touch targets minimum 44×44px (WCAG 2.5.8 / Apple HIG).
- No horizontal scroll on any viewport width.
- Overflow text uses `ellipsis` or clamp; never breaks layout.

## Performance Perception

- First Contentful Paint < 1.8s. Largest Contentful Paint < 2.5s.
- No layout shift after initial render (CLS < 0.1).
- Instant feedback on user actions — never leave a user wondering if a click registered.
