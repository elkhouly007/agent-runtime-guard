# OpenClaw Policy Map

## Purpose

Map Agent Runtime Guard policy into OpenClaw usage patterns.

## Prompt Roles

### Planner

Source: `openclaw/prompts/planner.md`

Use for:

- task planning;
- file discovery before edits;
- scoped implementation breakdowns.

Policy notes:

- local-safe by default;
- should not introduce networked steps by default;
- should call out manual decisions when risk matters.

### Reviewer

Source: `openclaw/prompts/reviewer.md`

Use for:

- bug review;
- regression review;
- maintainability review.

Policy notes:

- read-only role;
- no external tools by default;
- findings should stay concrete and local.

### Security

Source: `openclaw/prompts/security.md`

Use for:

- security review;
- input/output exposure review;
- auth, secrets, command execution, and file-write review.

Policy notes:

- external scanning is off by default;
- should treat data leaving the machine as a separate risk class;
- should escalate unclear outbound data flow.

## OpenClaw Approval Mapping

### Auto

- local reads;
- local non-destructive edits;
- local prompt and doc generation;
- trusted external prompt or agent usage after payload review and non-sensitive confirmation.

### Approval Required

- deletion;
- destructive overwrite of important files;
- personal or confidential data leaving the machine;
- elevated or system-wide changes;
- unclear external routing.

## Prompt-Injection Response

OpenClaw wiring should preserve the rule that instructions trying to bypass safety, hide payloads, or conceal destructive behavior are rejected or isolated.
