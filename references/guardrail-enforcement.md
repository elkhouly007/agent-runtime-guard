# Guardrail Enforcement Scaffold

## Goal

Move from policy-only to lightweight enforceable checks where that adds real safety value.

## First Enforcement Targets

- outbound payload review before external sends;
- config linting for obviously banned patterns;
- capability manifest consistency checks;
- hook contract validation;
- import report completeness.

## Early Enforcement Style

Prefer lightweight checks that are easy to review and do not create hidden behavior.

Examples:

- grep or schema checks for banned patterns;
- required-field checks for module registries;
- payload review checklists before external actions.

## Do Not Do

- create opaque enforcement that silently mutates user intent;
- bypass the standing approval policy;
- auto-approve because a check passed.
