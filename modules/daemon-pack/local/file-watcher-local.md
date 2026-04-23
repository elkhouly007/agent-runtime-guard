# file-watcher-local

## What it does

Watches a specified local folder for file changes and triggers a reviewed safe local action when a change is detected.

## Class

local

## Data flow

- reads: local folder (specified by user)
- writes: local log file, optional local action output
- external: none

## Approval boundary

- start: auto — local, no external connections, easy to stop
- stop: auto
- change watched folder to a sensitive path: auto — local scope maintained
- trigger an external send on change: ask Ahmed

## How to use

Specify the folder to watch and the local action to trigger. Both must be explicit before starting.

## Stop mechanism

Send SIGTERM to the process, or use the stop script if provided.

## Example use cases

- watch a build output folder and run a local audit when files change;
- watch a config folder and log any unexpected changes;
- watch a test results folder and update a local status file.
