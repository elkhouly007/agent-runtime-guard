# MCP Apply Checklist

Use this checklist before enabling any MCP module.

## Review The Module

Check:

- module id and class;
- whether it is local or external;
- exact command or connection path;
- exact data that may leave the machine;
- whether personal or confidential data could be exposed.

## Safe To Proceed Automatically

Proceed automatically only when all of the following are true:

- the MCP module is local or reviewed external;
- the payload is known and non-sensitive;
- the module does not require deletion, elevated access, or global mutation;
- the module does not rely on hidden downloads.

## User Approval Required

Ask before:

- deletion or destructive overwrite through MCP actions;
- personal or confidential data leaving the machine;
- elevated privilege use;
- unclear external routing or unclear payload.

## Verification

After enabling:

- note the module in the registry or project docs;
- confirm the module stayed within policy;
- rerun audit if local scripts or config changed.
