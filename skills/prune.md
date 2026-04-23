# Skill: Prune

## Trigger

Use when:
- Ahmed runs `/prune`
- The instinct store is getting large and noisy
- `/instinct-status` shows EXPIRING instincts that have not been promoted
- Routine maintenance at the end of a project phase

Command: `/prune`

## Pre-Conditions

Before starting:
- [ ] `~/.openclaw/instincts/pending.json` exists and is readable
- [ ] Ahmed is present to confirm before any changes are made

## Process

### 1. Read the pending store

```bash
cat ~/.openclaw/instincts/pending.json
```

Filter to instincts that are not already `status: "pruned"` or `status: "evolved"`. These are the active records to evaluate.

### 2. Identify prunable instincts

Evaluate each active instinct against three pruning criteria:

| Category | Condition | Reason |
|----------|-----------|--------|
| **Expired** | `expires_at` < today's date | Past their useful life — pattern is stale |
| **Negative + low confidence** | `outcome == "negative"` AND `confidence < 0.1` | Confirmed bad pattern with no signal value |
| **Empty + old** | `trigger` is null/empty AND `behavior` is null/empty AND created more than 14 days ago | Placeholder never developed — dead weight |

An instinct that matches any one of these is prunable. An instinct that matches multiple categories is still counted once but noted as matching multiple reasons.

### 3. Show the prune list to Ahmed before doing anything

Group by category and list each instinct with its id (last 8 chars) and age:

```
=== Prune Preview ===
Date: 2026-04-19

Expired (3):
  [a1b2c3d4]  age: 45 days  confidence: 0.30  behavior: "run npm ci before tests"
  [f9e87654]  age: 38 days  confidence: 0.15  behavior: (empty)
  [00cc1122]  age: 62 days  confidence: 0.44  behavior: "check for missing migrations"

Negative + low confidence (1):
  [3344aabb]  age: 12 days  confidence: 0.04  behavior: "skip linting on hotfix branches"

Empty + older than 14 days (2):
  [5566ccdd]  age: 21 days  trigger: (empty)  behavior: (empty)
  [7788eeff]  age: 19 days  trigger: (empty)  behavior: (empty)

Total: 6 instincts flagged for pruning.
```

If no instincts qualify, report:

```
Nothing to prune. Store is clean.
Active instincts: N
```

And stop.

### 4. Ask for confirmation

```
Prune 6 instincts? (yes / no / selective)
```

- **yes**: prune all flagged instincts
- **no**: cancel, make no changes
- **selective**: Ahmed picks which ids to prune by listing them (e.g., "prune a1b2c3d4 and 3344aabb")

Do not prune anything until confirmation is received.

### 5. Execute the prune (soft delete only)

For each confirmed instinct, set `status: "pruned"` in `pending.json`. Do not remove the object from the array. Do not delete the file.

**Safety rule: always soft-delete. Never remove records from the JSON file.**

The `status: "pruned"` flag is the deletion marker. The record stays in the file as an audit trail.

After updating the file, verify the write was successful:

```bash
# Confirm pruned count
cat ~/.openclaw/instincts/pending.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
pruned = [i for i in data if i['status'] == 'pruned']
active = [i for i in data if i['status'] not in ('pruned', 'evolved')]
print(f'Pruned: {len(pruned)}')
print(f'Active: {len(active)}')
"
```

### 6. Report completion

```
Pruned 6 instincts (status set to "pruned").

Store after prune:
  Active pending:   12
  Confident:         7
  Pruned (total):   18
  Evolved (total):   3
```

## Manual Inspection Commands

```bash
# See all non-pruned instincts with their expiry
cat ~/.openclaw/instincts/pending.json | python3 -c "
import json, sys
from datetime import datetime
data = json.load(sys.stdin)
today = datetime.utcnow().isoformat()
active = [i for i in data if i['status'] not in ('pruned','evolved')]
for i in active:
    expired = 'EXPIRED' if i.get('expires_at','9999') < today else ''
    print(f'{i[\"id\"][-8:]}  exp:{i.get(\"expires_at\",\"?\")[:10]}  conf:{i.get(\"confidence\",0):.2f}  {expired}')
"

# Manually set one instinct to pruned by id
python3 -c "
import json
path = '/root/.openclaw/instincts/pending.json'
target_id = 'REPLACE_WITH_FULL_ID'
with open(path) as f:
    data = json.load(f)
for i in data:
    if i['id'] == target_id:
        i['status'] = 'pruned'
        print(f'Pruned: {i[\"id\"][-8:]}')
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
"

# Count all instincts by status
cat ~/.openclaw/instincts/pending.json | python3 -c "
import json, sys
from collections import Counter
data = json.load(sys.stdin)
print(Counter(i['status'] for i in data))
"
```

## Safety Notes

- **Never hard-delete.** Do not remove JSON objects from the array, do not truncate the file, do not overwrite with a filtered copy that omits pruned records. Set `status: "pruned"` only.
- **Always preview before pruning.** The prune list must be shown to Ahmed and confirmed before any changes are made.
- **Selective mode is always available.** Ahmed can reject specific flagged instincts even if they technically qualify for pruning.
- **Confident instincts are never pruned here.** This command only touches `pending.json`. Confident instincts are permanent unless explicitly demoted.
- **If the JSON is malformed**, report the parse error and stop — do not attempt to write partial changes.
