# Skill: Multi-Frontend

## Trigger

Command: `/multi-frontend "component/feature"`

Use for frontend components or features that require coordinated design, test-first implementation, accessibility review, and TypeScript type safety review across a standard agent team. This is a pre-configured specialization of `/multi-plan` + `/multi-execute` for frontend work.

Use this instead of a single agent when:
- The component has non-trivial state management or interaction patterns
- Accessibility correctness is a hard requirement (medical, government, or public-facing UI)
- TypeScript type safety is critical (shared component library, design system contribution)
- The component is large enough that a single agent would lose track of the full requirements

Do not use for:
- Small style tweaks, copy changes, or single-prop modifications (delegate directly)
- Backend-only work (use `/multi-backend` instead)
- Exploration or prototyping — use a single `architect` or `code-explorer` spike first

## Agent Team

| Agent | Role |
|-------|------|
| `architect` | Designs component API, state shape, and composition structure |
| `tdd-guide` | Writes failing component tests (vitest + testing-library) |
| `a11y-architect` | Accessibility review — runs in parallel with implementation |
| `typescript-reviewer` | Type safety check — prop types, generics, discriminated unions |
| `code-reviewer` | Final quality review — logic, naming, re-render risk, bundle impact |

## Process

### Phase 1 — Component Design (sequential, architect only)

Assign `architect` to:
- Define the **component API**: prop names, types, required vs. optional, default values
- Define the **state shape**: local state, context, external store (identify what belongs where)
- Define the **composition structure**: which sub-components, what slots/children patterns are needed
- Identify **interaction patterns**: keyboard navigation, focus management, open/close behavior, form submission
- Identify **design token dependencies**: which spacing, color, typography tokens the component uses

Output: a component spec document. This is the input to all subsequent phases.

Ahmed reviews Phase 1 if the component modifies a shared design system or affects other components.

### Phase 2 — Test Setup (sequential, requires Phase 1)

Assign `tdd-guide` to:
- Write failing unit tests using **vitest** + **@testing-library/react** (or the project's test stack)
- Cover: rendering with required props, rendering with optional props, user interactions, keyboard behavior, error states, loading states
- Write failing accessibility assertions using `@testing-library/jest-dom` or `axe` integration
- Confirm: 0 tests passing (all should fail — implementation does not exist yet)

Output: test files with failing tests. No implementation is written in this phase.

### Phase 3 — Implementation + Accessibility Review (parallel, requires Phase 2)

Run two agents simultaneously:

**Agent 1: implementation**
- Assign `typescript-reviewer` or `code-reviewer` to implement the component until Phase 2 tests pass
- The agent works strictly against the Phase 1 spec and Phase 2 tests — no scope expansion
- No inline styles — use design tokens and the project's styling system

**Agent 2: a11y-architect**
- Receives the Phase 1 spec and the implementation diff (or spec alone if implementation is not ready)
- Audits for: correct ARIA roles and attributes, keyboard navigation completeness, focus trap behavior, screen reader announcement order, color contrast (if design tokens provided), touch target sizes

Output: implementation diff + accessibility findings list. Accessibility findings are not optional — they are a gate.

### Phase 4 — Type Safety + Quality Review (parallel, requires Phase 3)

Run two agents simultaneously:

**Agent 1: typescript-reviewer**
- Reviews all TypeScript: prop interface completeness, generic constraints, discriminated union exhaustiveness, event handler types, ref forwarding types, missing `undefined` handling

**Agent 2: code-reviewer**
- Reviews implementation for: unnecessary re-renders (unstable references, missing memoization), bundle size risk (heavy imports, dynamic imports needed), logic correctness, edge cases, naming clarity

Output: two review reports. Any CRITICAL finding stops the pipeline.

### Phase 5 — Ahmed Approval Gate

Surface the merged report to Ahmed:
- Phase 1 component spec
- Phase 2 test count (failing as expected)
- Phase 3 implementation diff + accessibility findings
- Phase 4 TypeScript review + code review findings
- Performance checklist (see below)

Ahmed approves before any files are written.

## Example: "Modal Dialog" Component

**Phase 1 — architect output:**
```
Component API:
  <Modal
    isOpen: boolean                       (required)
    onClose: () => void                   (required)
    title: string                         (required)
    description?: string                  (optional)
    size?: "sm" | "md" | "lg"            (optional, default: "md")
    children: React.ReactNode             (required)
    initialFocusRef?: React.RefObject     (optional — where to focus on open)
    closeOnOverlayClick?: boolean         (optional, default: true)
  />

State shape:
  No internal open/close state — controlled by isOpen prop (caller owns state)
  Internal: previouslyFocusedElement ref (for focus return on close)

Composition:
  Modal → ModalOverlay + ModalContent + ModalHeader + ModalBody + ModalCloseButton
  Portal: render into document.body via React.createPortal

Interaction patterns:
  - Trap focus inside modal when open
  - Escape key closes modal (calls onClose)
  - Overlay click closes modal if closeOnOverlayClick is true
  - Return focus to previously focused element on close
  - Scroll lock on body when modal is open

Design token dependencies:
  spacing.4, spacing.6, color.overlay, color.surface, radius.lg, shadow.xl, zIndex.modal
```

**Phase 2 — tdd-guide output:**
```
modal.test.tsx: 22 tests written, 22 failing
  - renders when isOpen is true
  - does not render when isOpen is false
  - renders title
  - renders description when provided
  - does not render description when omitted
  - calls onClose when Escape key is pressed
  - calls onClose when overlay is clicked (closeOnOverlayClick=true)
  - does not call onClose when overlay is clicked (closeOnOverlayClick=false)
  - traps focus within modal
  - returns focus to trigger element on close
  - renders size="sm" variant
  - renders size="lg" variant
  - axe: no accessibility violations on open
  - axe: no accessibility violations on close
  - ... (8 more)
```

**Phase 3 — a11y-architect findings:**
```
[CRITICAL] Missing role="dialog" on ModalContent — screen readers won't announce it as a dialog
[CRITICAL] Missing aria-modal="true" — screen readers will read background content
[MAJOR]    Missing aria-labelledby linking to title element
[MINOR]    Close button label is "X" — should be aria-label="Close dialog"
```

**Phase 4 — typescript-reviewer findings:**
```
[MAJOR]   onClose typed as () => void but used in async context — consider () => void | Promise<void>
[MINOR]   initialFocusRef should be typed as React.RefObject<HTMLElement>, not <any>
[INFO]    Consider exporting ModalProps interface for consumer use
```

## CSS / Design Token Guidance

- Never use hardcoded color, spacing, or font values — always reference design tokens
- If the project uses Tailwind: use only classes from the configured scale, no arbitrary values without justification
- If the project uses CSS Modules or styled-components: import tokens from the project's token file, do not inline `#hex` or `px` values
- Document which tokens the component depends on in the Phase 1 spec so `a11y-architect` can verify contrast

## Performance Checklist

Before Ahmed approves Phase 5, confirm:

| Check | Expected |
|-------|---------|
| No unstable object/array literals as props | Memoize or lift out |
| Event handlers stable across renders | useCallback if passed to memo'd children |
| No heavy library imported at module level | Dynamic import if >50kb |
| Portal target exists before mount | Guard createPortal with document check |
| Scroll lock cleans up on unmount | useEffect cleanup confirmed |
| No layout thrash in open/close animation | Transitions use CSS, not JS measurement |

## Trigger Multi-Frontend vs. Single Agent

| Situation | Use |
|-----------|-----|
| Style tweak or copy change | Single agent |
| New simple presentational component | Single agent (`typescript-reviewer`) |
| New interactive component with keyboard behavior | `/multi-frontend` |
| Component in shared design system | `/multi-frontend` |
| Component with complex state or context | `/multi-frontend` |
| Full feature (UI + API + DB) | `/multi-workflow` |

## Safe Behavior

- Phase 1 is read-only (spec only, no writes).
- No files are written until Ahmed approves the Phase 5 report.
- Accessibility findings from Phase 3 are a hard gate — CRITICAL findings block all writes.
- Design system changes are flagged before Phase 1 completes — they affect other components.
