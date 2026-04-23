# Plugin Pack

This pack defines reviewed plugin patterns for Agent Runtime Guard.

## Goal

Recover plugin power without hidden network destinations, hidden installs, or approval bypass.

## Pack Structure

- `registry.json`: reviewed plugin registry
- `local/`: local-only plugin notes
- `external-read/`: reviewed external-read plugin notes
- `external-write/`: reviewed but approval-gated external-write plugin notes
- `PLUGIN_APPLY_CHECKLIST.md`: apply checklist before enabling any plugin

## Default Position

- local-only plugins are preferred first;
- external-read plugins require payload review;
- external-write plugins require user approval for meaningful writes;
- plugins must not hide downloads, destinations, or permission changes.
