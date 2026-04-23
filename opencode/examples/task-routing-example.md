# OpenCode Task Routing Example

## Example Role Routing

- planning task -> `opencode/prompts/planner.md`
- code review task -> `opencode/prompts/code-review.md`
- security review task -> `opencode/prompts/security-review.md`
- build-fix task -> `opencode/prompts/build-fix.md`

## Example Rule

Use trusted external prompts or agents only after reviewing the outbound payload and confirming it does not contain personal or confidential data unless the user approved that send.

## Example Escalation

If a task would delete files, overwrite sensitive config, enable risky plugin classes, or send sensitive data externally, stop and ask the user.
