# Claude Code Hook Profile Example

## Secret Warning Hook

Use before prompt submit flows when a local warning about likely secrets is useful.

## Build Reminder Hook

Use around local build, test, lint, or check flows when a reminder to inspect output is useful.

## Git Push Reminder Hook

Use around push-related shell flows when a review reminder is useful.

## Escalation Rule

If a hook would ever move beyond local warning behavior into deletion, external write, or global mutation, stop and require approval.
