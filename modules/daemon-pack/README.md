# Daemon/Service Pack

Optional, carefully scoped services and background helpers.

## Design Rules

- All daemons must have a visible, easy stop mechanism.
- All daemons must write clear, readable local logs.
- No elevated privileges by default.
- No hidden persistence — must be explicitly started.
- No silent external connections.
- Personal or confidential data must never leave the machine without Ahmed's approval.

## When to Use

Use a daemon only when a persistent background helper provides clear value that a one-shot script cannot:

- watching a local folder for changes and triggering a safe local action;
- maintaining a lightweight local session state for multi-step workflows;
- running periodic local health or status checks.

## When NOT to Use

Do not use a daemon for:

- wrapping unsafe runtime behavior behind a persistent process;
- creating long-lived connections to external services without review;
- persisting elevated privileges or global config changes.

## Module Classes

| Class | Description |
|---|---|
| local | runs entirely on the local machine, no external connections |
| supervised | runs locally, connects to a reviewed trusted external endpoint |

## Approval Boundaries

| Action | Policy |
|---|---|
| Start a local daemon with clear logs and easy stop | auto — local non-destructive |
| Stop or restart a running local daemon | auto |
| Start a daemon that connects externally | ask Ahmed |
| Install daemon as a system service | ask Ahmed |
| Enable daemon with elevated privileges | ask Ahmed |
