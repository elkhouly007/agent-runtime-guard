# OpenClaw Wiring Plan

## Goal

Wire Agent Runtime Guard into OpenClaw in a way that is apply-ready, reviewable, and aligned with the standing approval policy.

## Scope Of This First Wiring Step

This step prepares:

- target file map;
- prompt pack layout;
- policy mapping for OpenClaw usage;
- manual apply guidance without forcing unsafe overwrites;
- compatibility guidance for frequent OpenClaw updates;
- project-local examples that avoid core patching.

It does not overwrite existing OpenClaw workspace files or global OpenClaw config.

## Target Paths

Recommended project-local target paths:

- `tools/ecc-safe-plus/openclaw/prompts/`
- `tools/ecc-safe-plus/openclaw/WIRING_PLAN.md`
- `tools/ecc-safe-plus/openclaw/OPENCLAW_POLICY_MAP.md`
- `tools/ecc-safe-plus/openclaw/OPENCLAW_APPLY_CHECKLIST.md`
- `tools/ecc-safe-plus/openclaw/examples/`

Potential future integration targets, only after explicit review:

- workspace prompt references in project instructions;
- per-project OpenClaw helper docs;
- optional task-specific prompt routing notes.

## Wiring Model

Use Agent Runtime Guard as an external policy and prompt source.

OpenClaw should consume:

- planner prompt;
- reviewer prompt;
- security prompt;
- future capability manifests and per-tool apply notes.

Prefer project-local references and adapter glue over direct core patching.
Do not change global OpenClaw defaults automatically in this step.

## Approval Mapping

### Auto-allowed

- reading local files;
- writing new local documentation;
- adding local prompt files;
- adding project-local policy notes;
- using trusted external agents only after payload review.

### Approval-required

- deleting or overwriting existing important workspace files;
- editing global OpenClaw config;
- enabling external modules with unclear data flow;
- routing personal or confidential data externally.

## Rollback Strategy

If integration causes instability:

1. remove the workspace prompt references from project instructions;
2. delete the local `tools/ecc-safe-plus/openclaw/` directory;
3. revert any manual changes made to `.openclaw/settings.json` if applicable.

## Definition Of Done

This first wiring step is complete when:

- OpenClaw-specific wiring docs exist;
- prompt roles are mapped to policy;
- apply instructions are explicit;
- no risky overwrite or global mutation has happened.
