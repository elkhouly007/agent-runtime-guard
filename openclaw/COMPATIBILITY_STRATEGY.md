# OpenClaw Compatibility Strategy

## Goal

Keep Agent Runtime Guard loosely coupled to OpenClaw so frequent OpenClaw updates do not force constant rework.

## Core Rule

Do not patch OpenClaw core files when a project-local adapter or template can achieve the same result.

## Avoid

- direct modification of OpenClaw source files;
- deep assumptions about internal OpenClaw implementation details;
- hard dependency on unstable internal paths;
- automatic overwrite of OpenClaw global config.

## Prefer

- project-local prompts and policy references;
- adapter notes and apply templates;
- explicit per-project wiring;
- reviewable config snippets rather than silent mutation.

## Update-Resilient Pattern

1. Keep Agent Runtime Guard files under `tools/horus/`.
2. Reference them from project-local instructions or task flows.
3. Treat any OpenClaw-facing config as replaceable glue, not core logic.
4. Re-check only the glue layer when OpenClaw updates.

## Compatibility Checks After OpenClaw Updates

Review:

- prompt or instruction loading conventions;
- config schema changes;
- tool permission model changes;
- session or routing behavior changes.

If OpenClaw changes in one of these areas, adapt the glue layer only. Do not collapse Safe-Plus back into core patching.
