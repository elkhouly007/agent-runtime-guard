# OpenClaw Adapter Notes

This folder contains portable prompts and wiring notes for OpenClaw-style harnesses.

## Included

- `prompts/planner.md`
- `prompts/reviewer.md`
- `prompts/security.md`
- `WIRING_PLAN.md`
- `OPENCLAW_POLICY_MAP.md`
- `OPENCLAW_APPLY_CHECKLIST.md`
- `COMPATIBILITY_STRATEGY.md`
- `examples/task-routing-example.md`
- `examples/project-local-instructions.example.md`
- `examples/openclaw-task-profile.example.md`

## Intent

Use Agent Runtime Guard as a policy and prompt source for OpenClaw without blindly mutating global config.

## Default Position

- project-local wiring is preferred first;
- risky modules remain disabled by default;
- global config changes require explicit review;
- external or trusted-agent use requires payload review when data leaves the machine;
- OpenClaw integration should remain loose-coupled so updates only require glue-layer maintenance.
