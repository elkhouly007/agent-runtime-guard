# Skill: Loop Status

## Trigger

Use when:
- A loop started with `/loop-start` is running and you want to inspect its state.
- A loop appears stuck or is taking longer than expected.
- You want to check how many iterations have been used.
- You need to stop a running loop cleanly.

## Process

### 1. Check active loop state files

```bash
# List all active loop state files
ls /tmp/ecc-loop-*.json 2>/dev/null || echo "No active loops."

# Read a specific loop state
cat /tmp/ecc-loop-test-fix.json | python3 -m json.tool
```

Example output:
```json
{
  "loop_id": "test-fix-loop",
  "started_at": "2026-04-19T17:00:00Z",
  "iteration": 4,
  "max_iterations": 10,
  "status": "running",
  "last_hash": "a3f9c1d2..."
}
```

### 2. Interpret status

| Field | What it tells you |
|-------|------------------|
| `iteration` | Current iteration number |
| `max_iterations` | Hard cap — loop stops here regardless |
| `status` | `running` / `success` / `failed` / `stopped` |
| `last_hash` | Fingerprint of last output — if same twice, loop is stuck |
| `started_at` | Calculate elapsed time from this |

### 3. Calculate progress

```bash
# Elapsed time (minutes)
started=$(cat /tmp/ecc-loop-test-fix.json | python3 -c "
import sys, json, datetime
d = json.load(sys.stdin)
start = datetime.datetime.fromisoformat(d['started_at'].replace('Z','+00:00'))
elapsed = datetime.datetime.now(datetime.timezone.utc) - start
print(f'Elapsed: {int(elapsed.total_seconds()//60)}m {int(elapsed.total_seconds()%60)}s')
print(f'Iteration: {d[\"iteration\"]} / {d[\"max_iterations\"]}')
print(f'Status: {d[\"status\"]}')
")
echo "$started"
```

### 4. Detect a stuck loop

Signs the loop is stuck:
- `iteration` is not increasing
- `last_hash` is the same across multiple status checks
- Elapsed time is far longer than expected per iteration

```bash
# Check if hash changed since last check (run twice, compare)
hash1=$(cat /tmp/ecc-loop-test-fix.json | python3 -c "import sys,json; print(json.load(sys.stdin).get('last_hash',''))")
sleep 30
hash2=$(cat /tmp/ecc-loop-test-fix.json | python3 -c "import sys,json; print(json.load(sys.stdin).get('last_hash',''))")
[ "$hash1" = "$hash2" ] && echo "⚠ Loop may be stuck — hash unchanged"
```

### 5. Stop a loop cleanly

```bash
# Set the stop flag — the loop will exit at the next iteration's Guard 4 check
touch /tmp/ecc-loop-stop
echo "Stop flag set. Loop will exit at next guard check."

# Verify it stopped
sleep 5
cat /tmp/ecc-loop-test-fix.json | python3 -c "import sys,json; print(json.load(sys.stdin)['status'])"
```

### 6. Force-stop (if clean stop does not work)

Only if the loop process is not responding to the stop flag:

```bash
# Find the loop process (if running as a background shell)
ps aux | grep "ecc-loop"

# Kill it
kill <PID>

# Clean up state files
rm /tmp/ecc-loop-*.json /tmp/ecc-loop-stop 2>/dev/null
echo "Loop force-stopped and state cleared."
```

### 7. View loop history

```bash
# Completed loop state files (status != running)
for f in /tmp/ecc-loop-*.json; do
  python3 -c "
import sys, json
d = json.load(open('$f'))
print(f\"{d['loop_id']}: {d['status']} at iteration {d['iteration']}/{d['max_iterations']}\")
"
done
```

## Output Format

When reporting loop status, use this format:

```
Loop: test-fix-loop
Status:     RUNNING
Progress:   4 / 10 iterations (40%)
Elapsed:    3m 12s
Last hash:  a3f9c1d2 (changed since last check ✓)
Stop flag:  not set
```

## Safe Behavior

- Loop status checks are read-only — they never modify state.
- Setting the stop flag (`/tmp/ecc-loop-stop`) is always safe — it triggers a clean exit.
- Force-stopping with `kill` is a last resort — prefer the stop flag.
- After any unclean stop, verify no partial changes were applied: `git status`.
- If a loop left behind partial file changes, review with `git diff` before continuing.
- Delete `/tmp/ecc-loop-*.json` after reviewing completed loops to keep the state directory clean.
