# Upstream Sync Strategy

## Goal

Track useful upstream changes without letting upstream runtime behavior land directly in the trusted base.

## Core Rule

Treat the upstream repository as a feature feed, not as the installed runtime base.

## Safe Update Flow

1. Fetch or mirror upstream into an isolated review area.
2. Diff the new upstream state against the last reviewed state.
3. Classify changes by area:
   - docs/prompts;
   - hooks;
   - plugins;
   - MCP;
   - installers;
   - wrappers/daemons;
   - config defaults.
4. Review each change against Phase 1, 2, and 3 policy.
5. Choose one outcome per change:
   - adopt directly;
   - adapt into safe-plus form;
   - defer for later;
   - reject.
6. Vendor or rewrite the accepted change into this repo.
7. Re-run audit and note the adoption decision.

## Never Do This

- Do not run raw upstream installers in the trusted base.
- Do not auto-sync executable files into the trusted base.
- Do not allow upstream updates to enable networked or destructive behavior by default.

## Good Candidates For Fast Adoption

- documentation;
- prompts;
- clearly local read-only helpers;
- bug fixes in low-risk local logic.

## Slow-Review Candidates

- hooks;
- plugins;
- MCP adapters;
- installers;
- wrappers;
- daemons;
- config that changes default permissions or external behavior.
