# Claude Code Apply Checklist

Use this checklist before wiring Agent Runtime Guard behavior deeper into Claude Code.

## Local Safe Changes

These may proceed automatically when they only affect project-local files:

- add local AGENTS references;
- add local hook files;
- add local policy references;
- add local usage examples.

## Review Before Apply

Check:

- target path;
- whether an existing AGENTS or hook file would be overwritten;
- whether user-level or global Claude Code config would be touched;
- whether any hook introduces external data flow or persistent mutation;
- whether any personal or confidential data is involved.

## User Approval Required

Ask before:

- deleting anything;
- overwriting an important existing config or hook file;
- editing global or user-level Claude Code configuration;
- enabling hooks with external writes or persistent global mutation;
- enabling outbound behavior with personal or confidential data.

## Verification

After applying changes:

- run the local audit;
- confirm target files exist;
- note which hooks or modules stayed disabled by default.
