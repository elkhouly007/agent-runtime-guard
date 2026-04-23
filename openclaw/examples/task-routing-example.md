# OpenClaw Task Routing Example

## Example Intent

A project wants to use Agent Runtime Guard prompt roles without changing global OpenClaw behavior.

## Example Mapping

- planning task -> `openclaw/prompts/planner.md`
- code review task -> `openclaw/prompts/reviewer.md`
- security review task -> `openclaw/prompts/security.md`

## Example Rule

Before any external call or trusted-agent delegation, review the payload and confirm it does not contain personal or confidential data unless the user approved that send.

## Example High-Risk Escalation

If a task would delete files, overwrite a sensitive existing file, or send personal data outside the machine, stop and ask the user.
