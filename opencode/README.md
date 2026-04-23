# OpenCode Adapter Notes

This folder contains a safe project-local OpenCode config template, prompt pack, and wiring notes.

## Included

- `opencode.safe.jsonc`
- `prompts/planner.md`
- `prompts/code-review.md`
- `prompts/security-review.md`
- `prompts/build-fix.md`
- `WIRING_PLAN.md`
- `OPENCODE_POLICY_MAP.md`
- `OPENCODE_APPLY_CHECKLIST.md`
- `COMPATIBILITY_STRATEGY.md`
- `examples/project-local-config.example.jsonc`
- `examples/task-routing-example.md`
- `examples/role-profile-example.md`
- `commands/plan-safe.md`
- `commands/verify-safe.md`
- `commands/orchestrate-safe.md`
- `commands/checkpoint-safe.md`

## Intent

Use Agent Runtime Guard as an external policy, prompt, and config-template layer for OpenCode without blindly mutating user-level config.

## Default Position

- project-local wiring is preferred first;
- risky modules remain disabled by default;
- user-level or global config changes require explicit review;
- external or trusted-agent use requires payload review when data leaves the machine.
