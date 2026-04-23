# Notification Pack

This pack defines reviewed notification patterns for Agent Runtime Guard.

## Goal

Recover notification usefulness while keeping local and external delivery clearly separated.

## Pack Structure

- `registry.json`: reviewed notification registry
- `local/`: local notification notes
- `external/`: external notification notes
- `NOTIFICATION_APPLY_CHECKLIST.md`: apply checklist before enabling any notification path

## Default Position

- local notifications are preferred first;
- external notifications require reviewed destinations and non-sensitive content unless approved otherwise;
- notification paths must not hide destinations or leak unnecessary sensitive content.
