# model-route-local

## Class

local

## Purpose

Recommend a model tier for a task using local heuristics without external routing.

## Allowed Use

- local task complexity triage;
- budget-aware model suggestions;
- fallback suggestion generation.

## Approval Boundary

Ask before turning routing guidance into an external send that contains personal or confidential data.

## Rejection Cases

Reject use if the wrapper hides the actual destination, auto-sends prompts, or claims approval that did not happen.
