# antegravity Harness — NOT YET SUPPORTED

> **NOT YET SUPPORTED.** This directory is an integration contract sketch only. No wiring, no policy maps, no wizard path, and no verified behavior exist here. Do not treat this as a supported harness.

## What This Would Be

antegravity is a code-agent harness. Agent Runtime Guard would support antegravity by providing the same hook integration, payload classification, and runtime decision layers it provides for Claude Code, OpenCode, and OpenClaw.

## What Is Planned

When this integration lands, it would deliver:
- A `WIRING_PLAN.md` documenting how Agent Runtime Guard hooks map to antegravity's hook event model
- An `ANTEGRAVITY_POLICY_MAP.md` documenting which runtime policies apply and how
- An `ANTEGRAVITY_APPLY_CHECKLIST.md` for verifying the integration is active
- Setup wizard support via `--tool antegravity`
- Per-tool apply-status rows showing actual wiring state

## Known Unknowns

See `COMPATIBILITY_NOTES.md` for a full list of what is unresolved.

## How to Contribute

If you have verified knowledge of the antegravity hook API or agent lifecycle, open a PR that fills in `COMPATIBILITY_NOTES.md` and proposes a `WIRING_PLAN.md`. Do not propose fake wiring — only document what you have actually tested.
