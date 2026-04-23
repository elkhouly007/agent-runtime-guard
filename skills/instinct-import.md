# Skill: Instinct Import

## Trigger

Use when:
- Ahmed runs `/instinct-import <file>` to bring in instincts from a teammate or community source
- Ahmed says "import these instincts", "load this instinct file", or "add someone else's patterns"
- A shared instinct JSON file has been downloaded and needs to be merged into the local store

Command: `/instinct-import <file>`

## Why Import Instead of Manually Editing

Importing validates, deduplicates, and secures the data before it touches your store. Directly editing `pending.json` risks:
- Duplicate IDs colliding with existing entries
- Importing overconfident instincts that haven't been earned locally
- Malformed JSON corrupting the store
- Accidentally importing secrets from an untrusted file

Use `/instinct-import` every time you receive instincts from an external source.

## Process

### 1. Receive the command

```
/instinct-import ~/Downloads/teammates-instincts.json
/instinct-import /tmp/community-patterns.json
```

Resolve the path. If the file does not exist, stop:

```
Error: File not found: ~/Downloads/teammates-instincts.json
Check the path and try again.
```

### 2. Parse and validate the file

Read the file and parse as JSON. If JSON is malformed, stop:

```
Error: File is not valid JSON. Parse error at line 14: unexpected comma.
Fix the file and retry.
```

The file must be a JSON array. If it is an object (not an array), stop:

```
Error: Expected a JSON array at the top level. Got object.
The correct format is: [ { ...instinct... }, { ...instinct... } ]
```

For each element in the array, validate required fields:

| Field | Type | Required | Validation rule |
|-------|------|----------|-----------------|
| `id` | string | yes | Non-empty string |
| `trigger` | string | yes | Non-empty string |
| `behavior` | string | yes | Non-empty string |
| `outcome` | string | yes | One of: `positive`, `neutral`, `negative` |
| `confidence` | number | yes | Between 0.0 and 1.0 inclusive |

Optional fields (`created_at`, `expires_at`, `tool_name`, `event_type`, `uses_count`, `status`) are preserved if present, ignored if absent.

Entries that fail validation are collected in a rejected list — do not stop the whole import, continue processing the rest.

### 3. Security check: cap confidence on import

Imported instincts have not been earned locally. Reject any entry where `confidence > 0.7`:

```
Rejected (confidence too high): id=abc123 — confidence 0.85 exceeds import cap of 0.70
```

The cap is not negotiable and cannot be overridden by a flag. Trust is earned locally through use, not inherited from export files.

Rationale: A teammate's confident instinct is their earned trust, not yours. Start it as a low-confidence candidate and let local usage promote it.

### 4. Deduplicate against existing store

Load both `~/.openclaw/instincts/pending.json` and `~/.openclaw/instincts/confident.json`.

Build a set of all existing `id` values. For each import candidate, if its original `id` already exists in either file, skip it and note as duplicate.

### 5. Rename IDs to avoid future collisions

For every entry that passes validation and deduplication, rewrite its `id`:

```
imported-<timestamp-ms>-<original-id-last-8-chars>
```

Example: `imported-1713571200000-a1b2c3d4`

Use the same timestamp for all entries in a single import run (the Unix ms timestamp at the moment the command is executed). This groups the batch together and makes it traceable.

### 6. Normalize imported instinct fields

Before appending, set these fields regardless of what the source file had:

```json
{
  "status": "pending",
  "confidence": "<original value, but capped at 0.70>",
  "imported_at": "<today ISO date>",
  "import_source": "<original filename basename>"
}
```

Do not modify `trigger`, `behavior`, or `outcome` — preserve them exactly as-is.

If `expires_at` is missing, set it to today + 60 days (shorter than manual `/learn` entries — imported instincts get less benefit of the doubt).

If `uses_count` is missing, set it to 0.

### 7. Append to pending.json

```bash
# Manual fallback: append validated entries
python3 -c "
import json, sys, os, time
from datetime import datetime, timedelta

pending_path = os.path.expanduser('~/.openclaw/instincts/pending.json')
import_file = sys.argv[1]
timestamp_ms = int(time.time() * 1000)
today = datetime.utcnow()

with open(import_file) as f:
    incoming = json.load(f)

with open(pending_path) as f:
    pending = json.load(f)

with open(os.path.expanduser('~/.openclaw/instincts/confident.json')) as f:
    confident = json.load(f)

existing_ids = {i['id'] for i in pending} | {i['id'] for i in confident}
basename = os.path.basename(import_file)

imported, skipped_dup, skipped_invalid, skipped_confidence = 0, 0, 0, 0

for entry in incoming:
    # Validate required fields
    required = ['id', 'trigger', 'behavior', 'outcome', 'confidence']
    if not all(k in entry and entry[k] for k in required):
        skipped_invalid += 1
        continue
    if entry['outcome'] not in ('positive', 'neutral', 'negative'):
        skipped_invalid += 1
        continue
    try:
        conf = float(entry['confidence'])
    except (ValueError, TypeError):
        skipped_invalid += 1
        continue

    # Security cap
    if conf > 0.7:
        skipped_confidence += 1
        continue

    # Deduplicate
    orig_id = str(entry['id'])
    if orig_id in existing_ids:
        skipped_dup += 1
        continue

    # Build normalized entry
    new_id = f'imported-{timestamp_ms}-{orig_id[-8:]}'
    expires = entry.get('expires_at') or (today + timedelta(days=60)).isoformat()
    new_entry = {
        'id': new_id,
        'created_at': entry.get('created_at', today.isoformat()),
        'imported_at': today.isoformat(),
        'import_source': basename,
        'expires_at': expires,
        'tool_name': entry.get('tool_name', 'imported'),
        'event_type': entry.get('event_type', 'import'),
        'trigger': entry['trigger'],
        'behavior': entry['behavior'],
        'outcome': entry['outcome'],
        'confidence': conf,
        'uses_count': int(entry.get('uses_count', 0)),
        'status': 'pending'
    }
    pending.append(new_entry)
    existing_ids.add(new_id)
    imported += 1

with open(pending_path, 'w') as f:
    json.dump(pending, f, indent=2)

print(f'Imported {imported} instincts ({skipped_dup} skipped as duplicates, {skipped_invalid} rejected as invalid, {skipped_confidence} rejected — confidence too high).')
" "$file_path"
```

### 8. Report results

```
Import complete.

  Imported:  12 instincts → pending.json
  Skipped:    2 duplicates (already in store)
  Rejected:   1 invalid (missing required fields)
  Rejected:   3 confidence too high (> 0.70)

All imported instincts set to status: pending
IDs prefixed: imported-1713571200000-*

Run /instinct-status to review imported candidates.
```

If 0 instincts were imported and all were rejected:

```
Nothing imported. All 8 entries were rejected.
Check the file format and resubmit.
```

## Import File Format

The import file must be a JSON array. Each element must follow this schema:

```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "trigger": "the test suite fails after a fresh checkout",
    "behavior": "run db:migrate before npm test",
    "outcome": "positive",
    "confidence": 0.65,
    "created_at": "2026-04-10T14:22:00",
    "expires_at": "2026-07-09T14:22:00",
    "tool_name": "manual",
    "event_type": "manual-learn",
    "uses_count": 3,
    "status": "candidate"
  },
  {
    "id": "b9c8d7e6-f5a4-3210-fedc-ba9876543210",
    "trigger": "PR has no linked issue",
    "behavior": "ask for the ticket number before starting review",
    "outcome": "positive",
    "confidence": 0.50
  }
]
```

Minimal valid entry (only required fields):

```json
{
  "id": "any-unique-string",
  "trigger": "non-empty description of the situation",
  "behavior": "non-empty description of what to do",
  "outcome": "positive",
  "confidence": 0.40
}
```

## Validation Rules Reference

| Rule | Behavior on failure |
|------|---------------------|
| File must exist | Stop immediately |
| File must be valid JSON | Stop immediately |
| Top-level must be array | Stop immediately |
| `id` required, non-empty string | Reject that entry |
| `trigger` required, non-empty string | Reject that entry |
| `behavior` required, non-empty string | Reject that entry |
| `outcome` must be `positive`, `neutral`, or `negative` | Reject that entry |
| `confidence` must be number 0.0–1.0 | Reject that entry |
| `confidence > 0.70` | Reject that entry (security cap) |
| `id` already in pending.json or confident.json | Skip that entry (duplicate) |

## Security Considerations

**Why confidence is capped at 0.70 on import:**

Confidence in the instinct system reflects local evidence — how many times this pattern has played out in your actual sessions. An imported instinct with confidence 0.95 is someone else's evidence, not yours. Importing it at face value would pollute your store with unearned certainty.

The cap of 0.70 matches the starting confidence of manually captured (`/learn`) instincts — the highest trust level that doesn't require local validation history.

**What the importer does not check:**

The importer does not scan `trigger` or `behavior` content for harmful patterns. That is the responsibility of `/instinct-export` on the sending side (redaction before sharing). If you receive a file from an untrusted source, review it manually before importing.

**Manual pre-import inspection:**

```bash
# Preview the file before importing
python3 -m json.tool ~/Downloads/shared-instincts.json | head -80

# Count entries and check confidence distribution
python3 -c "
import json
with open('shared-instincts.json') as f:
    data = json.load(f)
print(f'Total entries: {len(data)}')
high_conf = [i for i in data if i.get('confidence', 0) > 0.7]
print(f'Will be rejected (confidence > 0.70): {len(high_conf)}')
"
```

## Safe Behavior

- Never writes to `confident.json` — all imports go to `pending.json`.
- Never overwrites existing entries — only appends.
- Never removes entries from the store during import.
- If `pending.json` is missing, creates it as an empty array before appending.
- If `pending.json` is malformed JSON, reports the error and stops — does not overwrite.
- If the import file is malformed, stops before touching the store.
