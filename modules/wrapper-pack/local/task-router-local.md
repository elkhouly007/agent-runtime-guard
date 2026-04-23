# task-router-local

## Class

local

## Purpose

Route local tasks to the right Safe-Plus role or prompt without hidden behavior.

## Allowed Use

- local planner routing;
- local reviewer routing;
- local security routing;
- local build-fix routing.

## Approval Boundary

Ask before the wrapper adds deletion, destructive overwrite, elevated use, or non-reviewed external calls.

## Rejection Cases

Reject use if the wrapper hides routing logic, rewrites the task in a risky way, or bypasses approval boundaries.
