# Claude Code Adapter Notes

This folder contains a safe AGENTS layer, local hook pack, and wiring notes for Claude Code.

## Included

- `AGENTS.md`
- `hooks/README.md`
- `hooks/secret-warning.js`
- `hooks/build-reminder.js`
- `hooks/git-push-reminder.js`
- `WIRING_PLAN.md`
- `CLAUDE_POLICY_MAP.md`
- `CLAUDE_APPLY_CHECKLIST.md`
- `COMPATIBILITY_STRATEGY.md`
- `examples/project-local-agents.example.md`
- `examples/hook-profile-example.md`

## Intent

Use Agent Runtime Guard as an external policy and hook layer for Claude Code without blindly mutating user-level config.

## Default Position

- project-local wiring is preferred first;
- risky modules remain disabled by default;
- user-level or global config changes require explicit review;
- external or trusted-agent use requires payload review when data leaves the machine.
