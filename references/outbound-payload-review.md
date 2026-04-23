# Outbound Payload Review

## Goal

Review payloads before external sends so useful external power remains available without leaking sensitive data.

## Review Steps

1. Identify the destination.
2. Read the exact payload.
3. Remove or replace personal, confidential, or secret data when it is not needed.
4. Confirm whether the action is read-like or write-like.
5. Check whether the action falls into a user-approval category.

## Block Immediately If

- the destination is unclear;
- the payload contains personal, confidential, or secret data without approval;
- the action hides deletion, overwrite, or high-risk mutation;
- the tool implies approval that did not happen.

## Safe To Proceed When

- the destination is known;
- the payload is reviewed;
- the payload is non-sensitive or explicitly approved;
- the action stays within the standing approval policy.
