# health-check-local

## What it does

Runs periodic local health and status checks on a schedule and writes results to a local log file.

## Class

local

## Data flow

- reads: local project files, local scripts
- writes: local log file (specified path)
- external: none

## Approval boundary

- start: auto — local, easy to stop, no external sends
- stop: auto
- send health results externally: ask Ahmed

## How to use

Specify the check interval and the local scripts or checks to run. Results go to a local log.

## Stop mechanism

Send SIGTERM to the process, or cancel the scheduled task.

## Example use cases

- run audit-local.sh every hour and log results;
- run status-summary.sh periodically and keep a local history;
- watch for unexpected config drift and log any changes.
