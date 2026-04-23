# Vendor Policy

## Goal

Bring upstream ideas into the trusted base in a controlled way.

## Vendor Rules

- Vendor reviewed code or docs into this repository rather than pointing runtime directly at upstream.
- Keep source provenance in commit history or audit notes.
- Rewrite defaults when needed to match standing approval policy.
- Remove or disable hidden downloads, external writes, destructive flows, or approval bypass.

## Preferred Vendor Targets

- prompts;
- documentation;
- local helper scripts;
- local config templates;
- small reviewed logic blocks.

## Review Checklist

Before vendoring a change, confirm:

- what it does;
- what it sends outside the machine, if anything;
- whether it mutates local files, global config, or external systems;
- whether it introduces hidden dependencies or auto-download behavior;
- whether it weakens review or approval boundaries.
