# Codex Harness — NOT YET SUPPORTED

> **NOT YET SUPPORTED** for production use. A best-effort `hooks/adapter.js` exists using the broadest input-shape fallback chain, but the Codex hook API is not publicly documented and the adapter is unverified. No wiring plan, no policy maps, no wizard path. Test your actual Codex hook payload against the adapter before relying on it.

## What This Would Be

Codex is OpenAI's code-generation agent harness. Agent Runtime Guard would support Codex by providing the same hook integration, payload classification, and runtime decision layers it provides for Claude Code, OpenCode, and OpenClaw.

## What Is Planned

When this integration lands, it would deliver:
- A `WIRING_PLAN.md` documenting how Agent Runtime Guard hooks map to Codex's hook event model
- A `CODEX_POLICY_MAP.md` documenting which runtime policies apply and how
- A `CODEX_APPLY_CHECKLIST.md` for verifying the integration is active
- Setup wizard support via `--tool codex`
- Per-tool apply-status rows showing actual wiring state

## Known Unknowns

See `COMPATIBILITY_NOTES.md` for a full list of what is unresolved.

## How to Contribute

If you have verified knowledge of the Codex hook API or agent lifecycle, open a PR that fills in `COMPATIBILITY_NOTES.md` and proposes a `WIRING_PLAN.md`. Do not propose fake wiring — only document what you have actually tested.
