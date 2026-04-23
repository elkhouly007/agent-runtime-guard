# Wrapper Pack

This pack defines reviewed wrapper patterns for Agent Runtime Guard.

## Goal

Recover wrapper convenience and orchestration power without hidden payload mutation, hidden destinations, or approval bypass.

## Pack Structure

- `registry.json`: reviewed wrapper registry
- `local/`: local-first wrapper notes
- `external/`: external wrapper notes
- `WRAPPER_APPLY_CHECKLIST.md`: apply checklist before enabling any wrapper

## Default Position

- transparent local wrappers are preferred first;
- external wrappers are allowed only after payload review and clear destination understanding;
- wrappers must not hide logs, destinations, or approval boundaries.
