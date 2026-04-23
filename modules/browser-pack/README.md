# Browser Pack

This pack defines reviewed browser capability patterns for Agent Runtime Guard.

## Goal

Recover browser power with clear target visibility, clear read/write separation, and explicit approval on risky actions.

## Pack Structure

- `registry.json`: reviewed browser capability registry
- `read-only/`: reviewed read-oriented browser notes
- `write-gated/`: browser write candidates that require approval
- `BROWSER_APPLY_CHECKLIST.md`: apply checklist before enabling any browser capability

## Default Position

- read-oriented browsing is preferred first;
- write-like actions require approval;
- browser capability must not hide targets, uploads, or account-changing behavior.
