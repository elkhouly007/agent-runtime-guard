# Plugin Apply Checklist

Use this checklist before enabling any plugin.

## Review The Plugin

Check:

- plugin id and class;
- exact runtime behavior;
- whether it installs or downloads anything;
- exact destinations for any external calls;
- whether personal or confidential data could be exposed.

## Safe To Proceed Automatically

Proceed automatically only when all of the following are true:

- the plugin is local-only or reviewed external-read;
- the payload is known and non-sensitive;
- the plugin does not delete data, elevate privileges, or mutate global config;
- the plugin does not hide downloads or permission changes.

## User Approval Required

Ask before:

- meaningful external writes;
- deletion or destructive overwrite through plugin actions;
- personal or confidential data leaving the machine;
- elevated privileges or global mutation.

## Verification

After enabling:

- note the plugin in the registry or project docs;
- confirm class and behavior still match policy;
- rerun audit if scripts or config changed.
