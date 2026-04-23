# Wrapper Apply Checklist

Use this checklist before enabling any wrapper.

## Review The Wrapper

Check:

- wrapper id and class;
- exact tool or tools it calls;
- exact destination for any external call;
- whether logs and output remain visible;
- whether the wrapper rewrites payloads or prompts.

## Safe To Proceed Automatically

Proceed automatically only when all of the following are true:

- the wrapper is local or reviewed external;
- the destination and payload are known;
- the wrapper does not hide logs or approval boundaries;
- the wrapper does not require deletion, elevated access, or global mutation.

## User Approval Required

Ask before:

- deletion or destructive overwrite through wrapper actions;
- personal or confidential data leaving the machine;
- elevated privilege use;
- unclear external routing or hidden payload mutation.

## Verification

After enabling:

- note the wrapper in the registry or project docs;
- confirm output and destinations remain visible;
- rerun audit if local scripts or config changed.
