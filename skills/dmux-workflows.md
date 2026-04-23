# Skill: dmux Workflows

## Trigger

Use when orchestrating multi-agent work using tmux panes — running parallel agents in separate terminal panes, monitoring their outputs, and coordinating hand-offs between panes. Also use for any tmux-based workflow automation.

## Core Concept

**dmux** (distributed multiplexer) patterns use tmux to run multiple agent or CLI sessions in parallel, each in its own pane, with the orchestrator watching outputs and directing work. This is useful when:
- Running multiple long-running agent tasks simultaneously without blocking.
- Coordinating tasks that have natural I/O boundaries (one agent writes files, another reads them).
- Building repeatable multi-pane development environments (server + tests + watcher).

## Session and Pane Layout

```bash
# Create a named session
tmux new-session -d -s work -n main

# Split panes
tmux split-window -h -t work:main        # vertical split (left/right)
tmux split-window -v -t work:main.1      # horizontal split in right pane

# Resulting layout:
# ┌───────────────┬──────────────┐
# │               │   right-top  │
# │   main pane   ├──────────────┤
# │               │  right-bot   │
# └───────────────┴──────────────┘

# Name panes for reference (tmux >= 3.1 with pane titles)
tmux select-pane -t work:main.0 -T "orchestrator"
tmux select-pane -t work:main.1 -T "agent-1"
tmux select-pane -t work:main.2 -T "agent-2"
```

## Sending Commands to Panes

```bash
# Send a command to a specific pane
tmux send-keys -t work:main.1 "claude -p 'Review src/api.ts for security issues'" Enter

# Send to pane by title (if named)
tmux send-keys -t work:main.{agent-1} "npm test" Enter

# Broadcast to all panes in a window
tmux set-window-option -t work:main synchronize-panes on
tmux send-keys -t work:main "echo ready" Enter
tmux set-window-option -t work:main synchronize-panes off
```

## Reading Pane Output

```bash
# Capture current pane content
tmux capture-pane -t work:main.1 -p

# Capture last N lines
tmux capture-pane -t work:main.1 -p | tail -20

# Wait for a specific string to appear in a pane
wait_for_pane_output() {
    local target="$1"
    local pattern="$2"
    local timeout="${3:-60}"
    local elapsed=0
    while ! tmux capture-pane -t "$target" -p | grep -q "$pattern"; do
        sleep 1
        elapsed=$((elapsed + 1))
        if [ $elapsed -ge $timeout ]; then
            echo "Timeout waiting for: $pattern"
            return 1
        fi
    done
}

# Usage
wait_for_pane_output "work:main.1" "Tests passed" 120
```

## Standard Multi-Agent Layout

```bash
#!/usr/bin/env bash
# setup-workspace.sh — standard 3-pane agent workspace

SESSION="agents"

tmux new-session -d -s "$SESSION" -n workspace

# Pane 0: orchestrator / main
# Pane 1: agent-a (e.g., backend work)
tmux split-window -h -t "$SESSION:workspace"
# Pane 2: agent-b (e.g., frontend work)  
tmux split-window -v -t "$SESSION:workspace.1"

# Start agents
tmux send-keys -t "$SESSION:workspace.1" "cd backend && claude" Enter
tmux send-keys -t "$SESSION:workspace.2" "cd frontend && claude" Enter

# Focus orchestrator
tmux select-pane -t "$SESSION:workspace.0"
tmux attach-session -t "$SESSION"
```

## Coordination Pattern

```bash
# Orchestrator script
#!/usr/bin/env bash
set -euo pipefail

# Phase 1: Kick off parallel tasks
tmux send-keys -t agents:workspace.1 "claude -p 'Implement the User model per spec.md'" Enter
tmux send-keys -t agents:workspace.2 "claude -p 'Implement the API routes per spec.md'" Enter

# Wait for both to complete
wait_for_pane_output "agents:workspace.1" "Task complete" 300
wait_for_pane_output "agents:workspace.2" "Task complete" 300

echo "Phase 1 complete — reviewing outputs"

# Phase 2: Review
tmux send-keys -t agents:workspace.0 "claude -p 'Review the changes in backend/ and frontend/ together'" Enter
```

## Common Recipes

### Dev server + tests watcher

```bash
tmux new-session -d -s dev
tmux send-keys -t dev "npm run dev" Enter
tmux split-window -h -t dev
tmux send-keys -t dev.1 "npm run test:watch" Enter
tmux split-window -v -t dev.1
tmux send-keys -t dev.2 "git log --oneline -10" Enter
tmux attach-session -t dev
```

### Kill and clean up a session

```bash
tmux kill-session -t agents
```

## Constraints

- Always use named sessions (`-s name`) — unnamed sessions are hard to track.
- Never use `send-keys` with destructive commands without confirming the target pane first.
- Avoid `synchronize-panes on` in production orchestration — it sends the same command to all panes, which is rarely what you want.
- Capture pane output to a file if you need a persistent log: `tmux pipe-pane -t target "cat >> /tmp/pane.log"`.
