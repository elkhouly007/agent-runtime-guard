# checkpoint-local

## Class

local

## Purpose

Create a visible local checkpoint note or status snapshot without hidden side effects.

## Allowed Use

- local progress snapshot;
- local checkpoint metadata;
- local reversible tracking notes.

## Approval Boundary

Ask before deletion, destructive overwrite, elevated access, or external sends.

## Rejection Cases

Reject use if the wrapper hides writes, mutates unrelated files, or claims rollback safety it does not have.
