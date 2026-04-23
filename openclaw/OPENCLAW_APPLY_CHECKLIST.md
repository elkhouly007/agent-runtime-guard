# OpenClaw Apply Checklist

Use this checklist before wiring Agent Runtime Guard behavior deeper into OpenClaw.

## Local Safe Changes

These may proceed automatically when they only affect project-local files:

- add new prompt files;
- add local policy references;
- add local examples;
- add apply notes and wiring docs.

## Review Before Apply

Check:

- target path;
- whether an existing file would be overwritten;
- whether any global OpenClaw config would be touched;
- whether any external data flow is introduced;
- whether any user data or personal data is involved.

## User Approval Required

Ask before:

- deleting anything;
- overwriting existing important files;
- editing global OpenClaw configuration;
- enabling outbound behavior with personal or confidential data;
- enabling unclear external integrations.

## Verification

After applying changes:

- run the local audit;
- confirm target files exist;
- note what stayed disabled by default.
