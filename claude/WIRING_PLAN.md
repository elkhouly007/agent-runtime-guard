# Claude Code Wiring Plan

## Goal

Wire Agent Runtime Guard into Claude Code as a project-local safe-power layer that preserves visibility, approval boundaries, and update resilience.

## Scope Of This First Wiring Step

This step prepares:

- target file map;
- AGENTS and hook usage guidance;
- policy mapping for Claude Code behavior;
- project-local examples;
- compatibility guidance for future Claude Code changes.

It does not overwrite existing Claude Code user config or global files.

## Target Paths

Recommended project-local targets:

- `tools/horus/claude/AGENTS.md`
- `tools/horus/claude/hooks/`
- `tools/horus/claude/WIRING_PLAN.md`
- `tools/horus/claude/CLAUDE_POLICY_MAP.md`
- `tools/horus/claude/CLAUDE_APPLY_CHECKLIST.md`
- `tools/horus/claude/COMPATIBILITY_STRATEGY.md`
- `tools/horus/claude/examples/`

Potential future integration targets, only after explicit review:

- per-project AGENTS references;
- reviewed hook wiring snippets;
- optional local Claude Code config templates.

## Wiring Model

Use Agent Runtime Guard as an external policy and hook source.

Claude Code should consume:

- `claude/AGENTS.md` as the standing instruction layer;
- reviewed local hooks from `claude/hooks/`;
- future local config snippets only after policy review.

Prefer project-local references and reviewed copied snippets over global mutation.

## Approval Mapping

### Auto-allowed

- local AGENTS references;
- local hook files;
- local project docs;
- trusted external prompts or agents after payload review and non-sensitive confirmation.

### Approval-required

- overwriting important existing Claude Code config or hook files;
- enabling hooks that write externally or mutate global state;
- enabling external data flow with personal or confidential data;
- global user-level Claude Code config mutation.

## Rollback Strategy

If integration causes instability:

1. remove the `tools/horus/claude/` references from your project's `.claudecode/` or AGENTS files;
2. delete the local `tools/horus/claude/` directory;
3. revert any manual changes to your project-local Claude Code settings.

## Definition Of Done

This first wiring step is complete when:

- Claude Code-specific wiring docs exist;
- project-local usage examples exist;
- AGENTS and hook policy are mapped clearly;
- no global overwrite or risky mutation has happened.
