---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Hooks System

## Purpose

Hooks are a lightweight control layer around tool execution. In Agent Runtime Guard they should add visibility, friction, and optional enforcement without becoming a hidden source of side effects.

## Hook Types

- **PreToolUse**: Before tool execution, for validation and warnings
- **PostToolUse**: After tool execution, for reminders, lightweight checks, and follow-up cues
- **Stop / SessionEnd**: When a session ends, for final review or metadata capture
- **SessionStart**: When a session starts, for restoring safe local context

## Safe Hook Contract

Hooks should:

- read only the JSON payload provided on stdin;
- inspect local text only unless an external module is explicitly documented;
- write warnings to stderr;
- echo the original JSON unchanged unless a documented safe transform is intended;
- avoid network calls by default;
- avoid hidden writes or hidden installs;
- fail predictably and visibly.

## Approval and Enforcement

Use enforcement carefully:

- Enable block mode only for clearly high-risk behaviors
- Default to warnings for ambiguous situations
- Never rely on a hook as the only safety boundary
- Never use silent permission auto-approval
- Prefer explicit reviewed configuration over bypass flags

## Good Hook Design

- Keep logic narrow and deterministic
- Prefer pattern files or config over hardcoded regex sprawl
- Log metadata, not payload content
- Rate-limit noisy hooks when they trigger often
- Make verification easy with fixture tests and integrity checks

## Multi-Step Work Tracking

Use explicit task tracking when the harness supports it:

- Track progress on multi-step work
- Verify understanding before broad edits
- Keep steps granular enough to steer
- Surface missing or out-of-order work early

A good task list reveals:

- out-of-order steps
- missing items
- extra unnecessary items
- wrong granularity
- misinterpreted requirements

## Agent Runtime Guard Guidance

- Prefer project-local hook wiring over global hidden mutation
- Verify hook paths after installation
- Keep hooks readable enough to audit manually
- Treat hook output as advisory evidence unless block mode is explicitly enabled and documented

## Anti-Patterns

- Hooks that silently mutate user content
- Hooks that fetch dependencies at runtime
- Hooks that send telemetry without explicit documentation
- Hooks that auto-approve dangerous actions
- Hooks that depend on fragile global machine state
