# Skill: accessibility-review

## Purpose

Audit a UI component, page, or feature for accessibility (a11y) issues against WCAG 2.1 AA standards. Identify violations, explain their impact, and provide concrete fixes.

## Trigger

- Before shipping a new UI component or page
- After a UI refactor that touches markup or styling
- When a11y issues are reported by users or automated tools
- During a compliance or design review

## Trigger

`/accessibility-review` or `review accessibility of [component/page]`

## Steps

1. **Identify scope**
   - Which component, page, or feature to review
   - Target standard: WCAG 2.1 AA (default) or AAA

2. **Activate a11y-architect agent**
   - Read the component source (HTML/JSX/TSX/Flutter/SwiftUI)
   - Apply WCAG 2.1 AA criteria

3. **Check these categories**

   | Category | What to look for |
   |----------|-----------------|
   | Perceivable | Alt text on images, captions on video, color contrast ≥ 4.5:1 (text), 3:1 (large text) |
   | Operable | Keyboard navigation, focus indicators, no keyboard traps, skip links |
   | Understandable | Clear labels, error messages, consistent navigation, language attribute |
   | Robust | Valid HTML, ARIA roles used correctly, screen reader compatibility |

4. **Report findings**
   - List each issue with: WCAG criterion, severity (critical/major/minor), affected element, fix recommendation
   - Prioritize by severity: critical issues block release; major issues should be fixed before release; minor issues are tracked

5. **Provide fixes**
   - Code snippets for each finding
   - Verify that fixes do not break visual appearance or functionality

## Output Format

```markdown
## Accessibility Review — [Component/Page Name]

**Standard**: WCAG 2.1 AA
**Date**: YYYY-MM-DD

### Critical Issues (must fix before release)
- [WCAG X.X.X] Element: `<selector>` — Issue: ... — Fix: ...

### Major Issues (should fix before release)
- ...

### Minor Issues (track for future)
- ...

### Passed Checks
- ...
```

## Safe Behavior

- Read-only analysis unless asked to apply fixes.
- When applying fixes, modify only the targeted component — do not refactor surrounding code.
- Run existing tests after applying fixes to confirm no regressions.
