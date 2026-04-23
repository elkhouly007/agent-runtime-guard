---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Code Review

Standards for effective code review — both for authors and reviewers.

## Author Responsibilities

**Before submitting for review**:
- The code works. You have tested the change manually and/or with automated tests.
- The tests pass. Do not ask someone else to debug your CI failures.
- The PR is focused. One logical change per PR. Not three bug fixes and a refactor.
- The description is complete: what changed, why it changed, how to verify it.

**Making reviews easy**:
- Small PRs get faster, better reviews. If a change is large, explain why it must be large.
- Self-review before requesting review. A five-minute self-review catches 50% of issues and saves reviewer time.
- Respond to every comment. Not resolving comments implies they are ignored.

## Reviewer Responsibilities

**What to look for**:
- Correctness: does the code do what it claims? Under all inputs, including edge cases?
- Security: are there injection vectors, auth bypasses, secret exposure, or input validation gaps?
- Maintainability: will the next person understand this? Is the complexity justified?
- Tests: does the test suite verify the behavior, including failure modes?
- Documentation: is the behavior change documented where it should be?

**What not to block on**:
- Style that is handled by the formatter. Automated tools own style.
- Personal preference in design choices where the author's choice is reasonable.
- Theoretical future requirements that are not actual requirements.

## Review Mindset

- The goal of review is to improve the code, not to demonstrate the reviewer's expertise.
- "Why did you choose X over Y?" is more useful than "Y is better than X."
- Distinguish between: must-fix (blocking merge), should-fix (strong recommendation), and suggestion (optional improvement). Make the distinction explicit in the comment.
- Approve when you would be comfortable merging this code. Not when it is perfect.

## Escalation

- If review is taking more than 2 rounds without resolution, discuss synchronously. Async comment threads are inefficient for complex disagreements.
- If a reviewer and author disagree on something important, escalate to a third reviewer rather than deadlocking.
- Security findings are always blocking. No exceptions.
