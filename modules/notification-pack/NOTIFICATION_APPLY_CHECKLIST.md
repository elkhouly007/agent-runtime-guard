# Notification Apply Checklist

Use this checklist before enabling any notification path.

## Review The Notification Path

Check:

- notification id and class;
- whether delivery is local or external;
- exact destination if external;
- content class and sensitivity;
- whether the notification implies a meaningful external write.

## Safe To Proceed Automatically

Proceed automatically only when all of the following are true:

- the notification is local, or external to a known trusted destination;
- the content is known and non-sensitive;
- the notification does not expose personal or confidential data;
- the notification does not bypass approval boundaries.

## User Approval Required

Ask before:

- personal or confidential data leaves the machine;
- the destination is new or unclear;
- the notification creates a meaningful external write with unclear impact.

## Verification

After enabling:

- note the notification path in the registry or project docs;
- confirm destination and sensitivity class still match policy;
- rerun audit if scripts or config changed.
