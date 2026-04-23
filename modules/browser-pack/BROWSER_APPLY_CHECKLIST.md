# Browser Apply Checklist

Use this checklist before enabling any browser capability.

## Review The Capability

Check:

- capability id and class;
- exact target or destination;
- whether the task is read-only or write-like;
- whether uploads, posting, deletion, or settings changes are involved;
- whether personal or confidential data could be exposed.

## Safe To Proceed Automatically

Proceed automatically only when all of the following are true:

- the capability is read-only;
- the destination is known;
- the payload is known and non-sensitive;
- the task does not upload, post, delete, purchase, or change account settings.

## User Approval Required

Ask before:

- write-like browser actions;
- personal or confidential data leaving the machine;
- uploads, purchases, settings changes, or deletion;
- unclear destinations or unclear payloads.

## Verification

After enabling:

- note the capability in the registry or project docs;
- confirm the read/write class still matches the actual behavior;
- rerun audit if scripts or config changed.
