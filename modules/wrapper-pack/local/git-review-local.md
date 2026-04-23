# git-review-local

## Class

local

## Purpose

Wrap local git review and reminder flow with visible output and no hidden routing.

## Allowed Use

- local status and diff inspection;
- visible review reminders before push;
- scoped local helper flow around review tasks.

## Approval Boundary

Ask before destructive history changes, deletion, external push with sensitive data, or elevated use.

## Rejection Cases

Reject use if the wrapper suppresses output, hides destinations, or bypasses review for external operations.
