# Verification Plan

## Goal

Verify that Agent Runtime Guard keeps growing in power without losing reviewability or safety.

## Current Verification Layers

- local audit scanner;
- registry presence check;
- apply checklists for each capability pack;
- compatibility strategy docs;
- import checklist and report template.

## Next Verification Targets

- scenario tests for approval boundaries;
- prompt-injection test cases;
- outbound payload review test cases;
- integration smoke tests for OpenClaw, OpenCode, and Claude Code glue layers.

## Minimum Verification For New Pack Additions

1. audit passes;
2. registry check passes;
3. pack docs exist;
4. apply checklist exists;
5. approval boundaries are explicit.
