# Development Workflow

Standards for how development work should be structured to maximize quality and velocity.

## Task Decomposition

- Break all work into tasks small enough to complete and verify in one session.
- A task is complete only when: the code works, the tests pass, and the documentation is updated.
- Never leave a task "half done" — either complete it or roll it back. Partial changes accumulate into an untestable mess.
- Prioritize by impact and risk. High-risk, high-impact work goes first, when attention is sharpest.

## The Definition of Done

Work is done when:
1. The code change is complete
2. Tests are added or updated to cover the change
3. All existing tests pass
4. Documentation is updated if behavior changed
5. The change has been reviewed (or you have reviewed it yourself after a break)
6. The change is committed and pushed

"It works on my machine" is not done. "It passes CI" is done.

## Code Review

- Every non-trivial change should be reviewed before merging to the main branch.
- The author is responsible for producing a reviewable PR: clear description, passing tests, reasonable size.
- Reviewers should review for correctness and maintainability, not style (style is enforced by the formatter).
- Review comments are not personal. Respond to every comment substantively.
- A review approval means: "I understand this change and believe it is correct." It does not mean "I didn't find any bugs."

## Continuous Integration

- CI must pass before merging. No exceptions. Every exception creates a broken main branch.
- Fix failing CI immediately. A broken CI blocks everyone on the team.
- Keep CI fast. A CI pipeline taking more than 15 minutes discourages running it.
- CI should run on every push. Not just on PR creation.

## Iteration Discipline

- One change at a time. Mixing a refactor with a feature with a bug fix in one change makes all three harder to review and harder to revert.
- Prefer smaller, more frequent changes over large, infrequent ones. Small changes are easier to review, easier to revert, and safer to deploy.
- Measure the result of every significant change. If you changed something to make it faster or more reliable, verify the improvement with a measurement.
