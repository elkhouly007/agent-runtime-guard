# quality-gate-local

## Class

local-only

## Purpose

Run visible local quality checks such as lint, test, or diff sanity review without hidden external routing.

## Allowed Use

- local lint or test reminders;
- local quality gate reporting;
- local review summaries.

## Approval Boundary

Ask before deletion, elevated use, global mutation, or external sends.

## Rejection Cases

Reject use if the plugin silently changes files, installs dependencies, or hides failing output.
