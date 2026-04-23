# Skill: Loop Start

## Trigger

Use when:
- A task requires repeated execution of the same workflow until a condition is met.
- Running a PR review loop (fetch → review → comment → wait → repeat).
- Running an automated test-fix loop (test → fix → test until green).
- Any process where the number of iterations is not known in advance.

Do NOT use when:
- The task has a fixed, known number of steps — use a plain plan instead.
- A single agent call is sufficient.
- You need DAG orchestration — use `/multi-workflow` instead.

## Loop Types

| Type | Pattern | Example |
|------|---------|---------|
| **Until-success** | Run until exit condition met | Test loop: run until all pass |
| **Until-empty** | Run until queue is drained | PR loop: review until no open PRs |
| **Fixed-budget** | Run at most N iterations | Research loop: max 5 search rounds |
| **Time-boxed** | Run until time limit | Monitoring loop: check every 60s for 10min |

## Process

### 1. Define the loop before starting

Answer these before writing any loop:

```
Loop name:      [short identifier, e.g. "test-fix-loop"]
Goal:           [what does success look like?]
Exit condition: [what stops the loop?]
Max iterations: [hard cap — always set one]
On failure:     [what to do if max iterations reached without success]
Steps per iter: [what happens in each iteration]
```

### 2. Write the loop spec

```markdown
## Loop: test-fix-loop
- Goal: all tests passing in src/
- Exit condition: `npm test` exits 0
- Max iterations: 10
- On failure: stop, report last test output, escalate to Ahmed
- Per iteration:
  1. Run `npm test`
  2. If exit 0 → done
  3. Read failing test names
  4. Delegate fix to `tdd-guide` agent (one test at a time)
  5. Verify fix did not break other tests
```

### 3. Set up loop state file

Track state across iterations to prevent runaway loops:

```bash
# Create loop state
cat > /tmp/ecc-loop-test-fix.json << 'EOF'
{
  "loop_id": "test-fix-loop",
  "started_at": "2026-04-19T17:00:00Z",
  "iteration": 0,
  "max_iterations": 10,
  "status": "running",
  "last_hash": null
}
EOF
```

### 4. Guard pattern — mandatory

Every loop must include these 5 guards:

```bash
# Guard 1: Iteration cap
if [ "$iteration" -ge "$max_iterations" ]; then
  echo "Loop cap reached. Stopping." && exit 1
fi

# Guard 2: Wall-clock timeout
start_time=$(cat /tmp/ecc-loop-state.json | python3 -c "import sys,json; print(json.load(sys.stdin)['started_at'])")
# Check elapsed time > 30 minutes → stop

# Guard 3: No-progress detection
current_hash=$(npm test 2>&1 | md5sum | cut -d' ' -f1)
if [ "$current_hash" = "$last_hash" ]; then
  echo "No progress detected. Stopping to avoid infinite loop." && exit 1
fi

# Guard 4: External stop flag
if [ -f /tmp/ecc-loop-stop ]; then
  echo "Stop flag set. Exiting loop." && rm /tmp/ecc-loop-stop && exit 0
fi

# Guard 5: Idempotency key
# Each iteration must produce a different output — if same output twice, stop
```

### 5. Delegate iteration work to agents

Each iteration's work should be delegated to the right agent, not done inline:

```
Iteration task          → Agent
─────────────────────────────────
Fix failing test        → tdd-guide
Fix build error         → build-error-resolver
Review PR               → code-reviewer
Fix lint error          → code-reviewer
```

### 6. Report after loop ends

```
Loop: test-fix-loop
Status: SUCCESS (exit condition met at iteration 4)
Iterations used: 4 / 10
Duration: 3m 42s
Changes made: 3 files modified
```

## Common Patterns

### Test-Fix Loop

```bash
for i in $(seq 1 10); do
  npm test 2>&1 | tee /tmp/test-output.txt
  [ $? -eq 0 ] && echo "All tests pass. Done." && break
  echo "Iteration $i failed. Delegating fix..."
  # → delegate to tdd-guide agent with /tmp/test-output.txt context
done
```

### PR Review Loop

```bash
while true; do
  open_prs=$(gh pr list --json number --jq 'length')
  [ "$open_prs" -eq 0 ] && echo "No open PRs. Done." && break
  gh pr list --json number,title --jq '.[]' | head -1
  # → delegate review to code-reviewer agent
done
```

### Build-Fix Loop

```bash
for i in $(seq 1 5); do
  npm run build 2>&1 | tee /tmp/build-output.txt
  [ $? -eq 0 ] && echo "Build clean." && break
  # → delegate to build-error-resolver agent
done
```

## Safe Behavior

- Always set `max_iterations` before starting — no unbounded loops.
- Always check the no-progress guard (same output twice → stop).
- Use the stop flag file `/tmp/ecc-loop-stop` to interrupt a running loop safely.
- Loop state files go in `/tmp/` — session-scoped, not persisted.
- Agents run inside the loop should be read-only until Ahmed approves the final result.
- Destructive actions (deletes, force pushes) require Ahmed's explicit approval even inside a loop.
