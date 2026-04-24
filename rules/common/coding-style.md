---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Coding Style

Universal coding standards. These apply across all languages and projects unless a language-specific rule overrides them.

## Naming

- Names are documentation. A well-named variable needs no comment.
- Functions: verb phrases describing what they do. `validateEmailAddress`, not `check` or `emailFunc`.
- Variables: noun phrases describing what they hold. `activeUserCount`, not `count` or `n`.
- Booleans: prefix with `is`, `has`, `can`, `should`. `isExpired`, not `expired`.
- Avoid abbreviations unless the abbreviated form is universally understood in the domain.
- Never use single-letter names outside of loop indices and mathematical conventions.

## Functions

- One function, one responsibility. If you need "and" to describe a function, split it.
- Functions should not exceed 40 lines. Longer functions hide multiple responsibilities.
- Prefer returning early on error conditions rather than deep nesting.
- Pure functions (no side effects) over stateful functions wherever possible.
- Functions that can fail should signal failure explicitly — through the return type or an exception, never by returning a sentinel value.

## Structure

- Modules should have clear single responsibilities. A module that does everything is a module that cannot be tested in isolation.
- Depend on interfaces (abstractions), not implementations. Concrete dependencies make code brittle.
- Limit nesting depth to 3 levels. Deeper nesting indicates a function that needs to be split.
- Constants over magic numbers. A bare `7` in the middle of logic is a maintenance hazard. `MAX_RETRY_ATTEMPTS = 7` is self-documenting.

## Comments

- Write no comments by default. Well-named code needs no explanation.
- Write a comment when the WHY is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific known bug.
- Never write comments that repeat what the code already says.
- Update comments when the code changes. Stale comments are worse than no comments.

## Formatting

- Consistency over personal preference. Use the project formatter (prettier, black, rustfmt, gofmt) and do not override it.
- Code formatting is not worth a code review discussion. Automate it.
- One concept per line. Avoid compressing multiple operations onto a single line to be clever.
