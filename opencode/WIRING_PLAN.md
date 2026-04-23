# OpenCode Wiring Plan

## Goal

Wire Agent Runtime Guard into OpenCode as a project-local safe-power layer without relying on raw upstream config or fragile core patching.

## Scope Of This First Wiring Step

This step prepares:

- target file map;
- OpenCode config usage guidance;
- policy mapping for OpenCode roles and tools;
- project-local examples;
- compatibility guidance for future OpenCode changes.

It does not overwrite existing OpenCode user config or global files.

## Target Paths

Recommended project-local targets:

- `tools/ecc-safe-plus/opencode/opencode.safe.jsonc`
- `tools/ecc-safe-plus/opencode/prompts/`
- `tools/ecc-safe-plus/opencode/WIRING_PLAN.md`
- `tools/ecc-safe-plus/opencode/OPENCODE_POLICY_MAP.md`
- `tools/ecc-safe-plus/opencode/OPENCODE_APPLY_CHECKLIST.md`
- `tools/ecc-safe-plus/opencode/COMPATIBILITY_STRATEGY.md`
- `tools/ecc-safe-plus/opencode/examples/`

Potential future integration targets, only after explicit review:

- per-project OpenCode config references;
- project-local role presets;
- optional module enablement snippets.

## Wiring Model

Use Agent Runtime Guard as an external policy, prompt, and config-template source.

OpenCode should consume:

- `opencode.safe.jsonc` as a reviewed starting point;
- planner, reviewer, security, and build-fix prompts;
- future module snippets only after policy classification.

Prefer project-local references and reviewed config copies over global mutation.

## Approval Mapping

### Auto-allowed

- local project config templates;
- local prompt files;
- local policy references;
- trusted external agents after payload review and non-sensitive confirmation.

### Approval-required

- overwriting existing important OpenCode config files;
- enabling external-write or system-write plugins;
- enabling external data flow with personal or confidential data;
- global user-level OpenCode config mutation.

## Rollback Strategy

If integration causes instability:

1. delete the local `tools/ecc-safe-plus/opencode/` directory;
2. revert any manual changes to your project-local `.opencode.json` (if you were using the safe template).

## Definition Of Done

This first wiring step is complete when:

- OpenCode-specific wiring docs exist;
- project-local usage examples exist;
- config and role policy are mapped clearly;
- no global overwrite or risky mutation has happened.
