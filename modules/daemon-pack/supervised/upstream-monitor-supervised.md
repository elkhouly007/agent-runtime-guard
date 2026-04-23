# upstream-monitor-supervised

## What it does

Polls the upstream repository for new commits or releases on a schedule and writes a local diff/change summary.

## Class

supervised

## Data flow

- reads: upstream repository via reviewed external endpoint (e.g. GitHub API)
- writes: local change summary file
- external: read-only connection to upstream repo — requires Ahmed's approval

## Approval boundary

- start: ask Ahmed — external connection involved
- stop: auto once started
- change polling target: ask Ahmed
- send diff summary externally: ask Ahmed

## How to use

Specify the upstream repo, polling interval, and local output path before starting. Ahmed must approve the external connection.

## Stop mechanism

Send SIGTERM to the process, or cancel the scheduled task.

## Example use cases

- poll affaan-m/everything-claude-code for new commits every 24 hours;
- write a local summary of what changed for review before any adoption decision;
- alert locally when a new release is detected.
