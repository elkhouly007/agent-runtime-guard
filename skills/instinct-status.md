# Skill: Instinct Status

## Trigger

Use when:
- Ahmed asks "what instincts do we have?" or "show me the instinct store"
- Before running `/evolve` to see what's ready to cluster
- After a long session to check what was captured automatically
- When deciding what to promote, prune, or review

Command: `/instinct-status`

## Process

### 1. Read the instinct store files

```bash
cat ~/.openclaw/instincts/pending.json
cat ~/.openclaw/instincts/confident.json
```

Parse both JSON arrays. If either file is missing or empty array, note it and continue with what exists.

### 2. Compute today's date and classify pending instincts

For each object in `pending.json` with `status != "pruned"` and `status != "evolved"`:

| Condition | Badge |
|-----------|-------|
| `confidence >= 0.5` | CANDIDATE |
| `expires_at` within 7 days from today | EXPIRING |
| Everything else | PENDING |

An instinct can be both CANDIDATE and EXPIRING — show both badges.

### 3. Display pending instincts grouped by badge

Print in order: CANDIDATE first, then EXPIRING (non-candidate), then PENDING.

For each instinct show:

```
[CANDIDATE] id: ...a1b2c3d4
  trigger:    "user asks to review a PR with no linked issue"
  behavior:   "always ask for the ticket number before starting"
  confidence: 0.72
  expires:    in 18 days
  uses:       3
```

If `trigger` or `behavior` fields are empty/null, show them as `(not filled in)`.

### 4. Display confident instincts summary

```
Confident instincts: 7 total

Most recent 3:
  [c9f3e211] "When debugging a test failure, read the full stack trace before touching code" — promoted 2026-04-10
  [b44a0012] "Always run lint before committing on this repo" — promoted 2026-04-08
  [a8812bca] "Prefer named exports over default exports in this codebase" — promoted 2026-04-01
```

If `confident.json` has 0 entries, say: "No confident instincts yet. Promote candidates from pending to build the store."

### 5. Show actionable next steps

Based on what was found:

- For each CANDIDATE instinct: "To promote [id]: fill in trigger + behavior in pending.json, then call promote([id])"
- If any EXPIRING instincts exist: "Run /prune to clean up N expiring instinct(s)"
- If 3+ confident instincts exist: "Run /evolve to cluster instincts into reusable skills"
- If 0 candidates and 0 confident: "No actionable instincts. Run /learn to capture a pattern manually."

## Example Output

```
=== Instinct Store Status ===
Date: 2026-04-19

--- CANDIDATES (ready to review) ---

[CANDIDATE] id: a1b2c3d4
  trigger:    "user pastes a wall of logs with no question"
  behavior:   "ask 'what outcome are you expecting?' before reading logs"
  confidence: 0.81
  expires:    in 22 days
  uses:       5

[CANDIDATE | EXPIRING] id: f9e87654
  trigger:    (not filled in)
  behavior:   "run npm ci before npm test on first run"
  confidence: 0.55
  expires:    in 4 days
  uses:       2

--- EXPIRING (act soon) ---

[EXPIRING] id: 00cc1122
  trigger:    (not filled in)
  behavior:   (not filled in)
  confidence: 0.12
  expires:    in 6 days
  uses:       0

--- PENDING ---

[PENDING] id: 3344aabb
  trigger:    (not filled in)
  behavior:   (not filled in)
  confidence: 0.20
  expires:    in 28 days
  uses:       1

--- Confident Instincts: 4 total ---

Most recent 3:
  [c9f3e211] "Read full stack trace before touching code" — promoted 2026-04-10
  [b44a0012] "Run lint before committing" — promoted 2026-04-08
  [a8812bca] "Named exports over default exports here" — promoted 2026-04-01

--- Next Steps ---
  - To promote a1b2c3d4: review trigger/behavior in pending.json, then promote(a1b2c3d4)
  - To promote f9e87654: review trigger/behavior in pending.json — EXPIRING in 4 days
  - Run /prune to clean up 2 expiring/low-value instinct(s)
  - Run /evolve to cluster 4 confident instincts into skills
```

## Manual Inspection Commands

```bash
# Pretty-print pending store
cat ~/.openclaw/instincts/pending.json | python3 -m json.tool

# Count by status
cat ~/.openclaw/instincts/pending.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
from collections import Counter
print(Counter(i['status'] for i in data))
"

# Show only candidates (confidence >= 0.5, not pruned/evolved)
cat ~/.openclaw/instincts/pending.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
candidates = [i for i in data if i.get('confidence', 0) >= 0.5 and i['status'] not in ('pruned', 'evolved')]
print(json.dumps(candidates, indent=2))
"

# Show confident instinct count
cat ~/.openclaw/instincts/confident.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f'{len(data)} confident instincts')
"
```

## Safe Behavior

- Read-only operation — does not modify either file.
- Does not promote or prune anything automatically.
- Does not call `/evolve` or `/prune` without Ahmed explicitly running those commands.
- If either JSON file is malformed, report the parse error and stop.
