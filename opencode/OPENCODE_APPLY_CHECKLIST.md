# OpenCode Apply Checklist

Use this checklist before wiring Agent Runtime Guard behavior deeper into OpenCode.

## Local Safe Changes

These may proceed automatically when they only affect project-local files:

- add local config templates;
- add prompts;
- add policy references;
- add role usage examples.

## Review Before Apply

Check:

- target path;
- whether an existing OpenCode config would be overwritten;
- whether user-level or global config would be touched;
- whether any plugin or MCP path would introduce external data flow;
- whether any personal or confidential data is involved.

## User Approval Required

Ask before:

- deleting anything;
- overwriting an important existing config;
- editing global or user-level OpenCode configuration;
- enabling external-write or system-write plugins;
- enabling outbound behavior with personal or confidential data.

## Verification

After applying changes:

- run the local audit;
- confirm target files exist;
- note which modules stayed disabled by default.
