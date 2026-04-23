# Skill: Instinct Export

## Trigger

Use when:
- Ahmed runs `/instinct-export` or `/instinct-export --all` or `/instinct-export --candidates`
- Ahmed wants to share instincts with a teammate or back them up
- Ahmed says "export my instincts", "share these patterns", or "save my instinct store to a file"

Command: `/instinct-export [--all | --confident | --candidates]`

## Why Export via Skill Instead of Copying the File

The raw store files may contain sensitive content — file paths with home directories, IP addresses, API key fragments accidentally captured in a trigger or behavior string. The export skill redacts those before writing the shareable file, so you do not accidentally leak personal or environment-specific data.

Never share `pending.json` or `confident.json` directly. Always export through this skill.

## Flags

| Flag | What it exports |
|------|-----------------|
| _(none)_ | Confident instincts only (default) |
| `--confident` | Same as default — confident instincts only |
| `--all` | All non-pruned, non-evolved instincts from both stores |
| `--candidates` | Only entries with `status=candidate` from pending.json |

## Process

### 1. Determine scope from flag

```
/instinct-export                → load confident.json only
/instinct-export --confident    → load confident.json only
/instinct-export --all          → load pending.json + confident.json, exclude pruned and evolved
/instinct-export --candidates   → load pending.json, filter to status == "candidate"
```

### 2. Load the relevant store files

```bash
cat ~/.openclaw/instincts/confident.json
cat ~/.openclaw/instincts/pending.json
```

If a required file is missing or empty, note it and continue. If both files are missing, stop:

```
Error: No instinct store found at ~/.openclaw/instincts/
Run /learn to capture some instincts first.
```

### 3. Apply status filters

For `--all`: exclude any entry where `status` is `"pruned"` or `"evolved"`. These are dead entries not worth sharing.

For `--candidates`: keep only entries where `status == "candidate"` from pending.json.

For confident/default: use the entire confident.json array.

### 4. Redact sensitive content

For every entry in the export set, inspect the `trigger` and `behavior` fields against these redaction rules:

| Pattern | What it looks like | Action |
|---------|--------------------|--------|
| API key or token | `sk-...`, `ghp_...`, `xox...`, `AKIA...`, any string matching `[A-Za-z0-9]{32,}` following `key=`, `token=`, `secret=`, `password=` | Skip entry, print warning |
| Home directory path | `/home/<username>/`, `/Users/<username>/`, `~/` followed by a directory segment | Skip entry, print warning |
| IP address | `\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b` | Skip entry, print warning |
| Hostname with internal TLD | `.local`, `.internal`, `.corp`, `.lan` in a hostname | Skip entry, print warning |
| Email address | Standard email pattern | Skip entry, print warning |

Redaction is all-or-nothing per entry — if either `trigger` or `behavior` matches any rule, skip the entire entry. Do not attempt partial redaction (truncating or masking) because context makes the pattern identifiable anyway.

Print a warning line for each skipped entry:

```
[REDACTED] id: ...a1b2c3d4 — trigger contains a home directory path. Skipped.
[REDACTED] id: ...f9e87654 — behavior contains an API key pattern. Skipped.
```

### 5. Show preview before writing

Do not write the file yet. Show:

```
Export preview:

  Scope:    confident instincts
  Entries:  14 total, 2 redacted (not exported), 12 ready to export
  Output:   ~/instincts-export-2026-04-19.json

Sample (first 3 triggers):
  1. "user pastes a wall of logs with no question asked"
  2. "PR has no linked issue when review is requested"
  3. "test suite fails after a fresh checkout on this reposi..."

Proceed? (yes / no)
```

Truncate the trigger preview at 80 characters and append `...` if truncated. Show at most 3 entries in the preview regardless of total count.

If 0 entries remain after redaction, do not proceed to confirmation:

```
Nothing to export. All entries were redacted or the selected scope is empty.
```

### 6. Wait for confirmation

Wait for Ahmed to reply. If the answer is not "yes" (any variation: "y", "yeah", "go ahead", "do it"), cancel:

```
Export cancelled. Nothing was written.
```

### 7. Generate the export file

Output path: `~/instincts-export-YYYY-MM-DD.json` using today's date.

If the file already exists (same date, ran twice), append a counter: `~/instincts-export-2026-04-19-2.json`.

Strip internal-only fields before writing — these are system fields that don't transfer meaningfully to another machine:

Fields to remove before export: `imported_at`, `import_source`

Fields to keep: `id`, `trigger`, `behavior`, `outcome`, `confidence`, `created_at`, `expires_at`, `tool_name`, `event_type`, `uses_count`, `status`

```bash
python3 -c "
import json, os
from datetime import datetime

pending_path = os.path.expanduser('~/.openclaw/instincts/pending.json')
confident_path = os.path.expanduser('~/.openclaw/instincts/confident.json')
today = datetime.utcnow().strftime('%Y-%m-%d')
out_path = os.path.expanduser(f'~/instincts-export-{today}.json')

# Handle duplicate output file names
counter = 2
base = out_path
while os.path.exists(out_path):
    out_path = base.replace('.json', f'-{counter}.json')
    counter += 1

import re
SENSITIVE_PATTERNS = [
    r'(key|token|secret|password)=\S{8,}',
    r'[A-Za-z0-9]{32,}',
    r'sk-[A-Za-z0-9]+',
    r'ghp_[A-Za-z0-9]+',
    r'AKIA[A-Z0-9]{16}',
    r'/home/[^/]+/',
    r'/Users/[^/]+/',
    r'~/',
    r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b',
    r'\S+\.(local|internal|corp|lan)\b',
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
]

def is_sensitive(text):
    for p in SENSITIVE_PATTERNS:
        if re.search(p, str(text)):
            return True
    return False

STRIP_FIELDS = {'imported_at', 'import_source'}

def clean(entry):
    return {k: v for k, v in entry.items() if k not in STRIP_FIELDS}

# Load and filter (adjust for your chosen scope/flag)
with open(confident_path) as f:
    entries = json.load(f)

ready, redacted = [], 0
for e in entries:
    if is_sensitive(e.get('trigger', '')) or is_sensitive(e.get('behavior', '')):
        redacted += 1
        print(f'[REDACTED] id: ...{str(e[\"id\"])[-8:]} — sensitive content detected. Skipped.')
        continue
    ready.append(clean(e))

with open(out_path, 'w') as f:
    json.dump(ready, f, indent=2)

print(f'Exported {len(ready)} instincts to {out_path} ({redacted} redacted).')
"
```

### 8. Confirm to Ahmed

```
Export complete.

  File:     ~/instincts-export-2026-04-19.json
  Entries:  12 instincts exported
  Redacted: 2 entries skipped (sensitive content)

To share with a teammate:
  scp ~/instincts-export-2026-04-19.json teammate@host:~/
  # or attach to a shared channel, gist, or repo

On the receiving machine:
  /instinct-import ~/instincts-export-2026-04-19.json
```

## Export File Format

The output file is a JSON array. Example:

```json
[
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "trigger": "user pastes a wall of logs with no question",
    "behavior": "ask 'what outcome are you expecting?' before reading logs",
    "outcome": "positive",
    "confidence": 0.81,
    "created_at": "2026-04-01T10:00:00",
    "expires_at": "2026-06-30T10:00:00",
    "tool_name": "manual",
    "event_type": "manual-learn",
    "uses_count": 5,
    "status": "confident"
  }
]
```

Fields `imported_at` and `import_source` are stripped — they are metadata about where an instinct came from on your machine, not meaningful to the recipient.

## Redaction Rules Reference

| Pattern type | Example | Why filtered |
|-------------|---------|--------------|
| API key fragment | `key=sk-proj-abcdef123456` | Credential exposure |
| Long random string after `token=` | `token=xoxb-1234567890abcdef` | Credential exposure |
| Home directory path | `/home/ahmed/projects/` | Reveals username and machine structure |
| `~/` path | `~/my-private-repo/` | Same — resolves to home dir |
| IP address | `192.168.1.45` | Reveals internal network topology |
| Internal hostname | `api.corp`, `devbox.local` | Reveals internal infrastructure |
| Email address | `ahmed@example.com` | PII |

If in doubt, it is filtered. A false positive (filtering a safe entry) is always preferable to a false negative (leaking sensitive data).

## How to Share with Teammates

**Via file transfer:**
```bash
scp ~/instincts-export-2026-04-19.json teammate@hostname:~/
```

**Via GitHub Gist (private):**
```bash
gh gist create ~/instincts-export-2026-04-19.json --private --desc "instinct export 2026-04-19"
```

**Via shared directory:**
```bash
cp ~/instincts-export-2026-04-19.json /shared/team-instincts/
```

## How to Import on Another Machine

On the receiving machine, after transferring the file:

```
/instinct-import ~/instincts-export-2026-04-19.json
```

The importer will:
- Rename all IDs to avoid collisions
- Cap confidence at 0.70
- Set all entries to `status: pending`
- Append to the local pending.json

See `/instinct-import` for full details.

## Manual Bash Commands for Inspection

```bash
# Count confident instincts (default export scope)
python3 -c "
import json
with open(os.path.expanduser('~/.openclaw/instincts/confident.json')) as f:
    data = json.load(f)
print(f'{len(data)} confident instincts available to export')
"

# Preview all triggers (to spot sensitive content before exporting)
python3 -c "
import json, os
with open(os.path.expanduser('~/.openclaw/instincts/confident.json')) as f:
    data = json.load(f)
for i in data:
    print(repr(i.get('trigger', '')))
"

# Dry-run redaction check
python3 -c "
import json, os, re
PATTERNS = [r'/home/[^/]+/', r'/Users/[^/]+/', r'~/', r'\b\d{1,3}(\.\d{1,3}){3}\b']
with open(os.path.expanduser('~/.openclaw/instincts/confident.json')) as f:
    data = json.load(f)
for e in data:
    for p in PATTERNS:
        if re.search(p, e.get('trigger','') + e.get('behavior','')):
            print(f'Would redact: {e[\"id\"][-8:]}')
            break
"
```

## Safe Behavior

- Read-only on the instinct store — does not modify `pending.json` or `confident.json`.
- Does not write the export file without explicit confirmation.
- Does not export pruned or evolved instincts in `--all` mode.
- If either store file is malformed JSON, reports the error and stops.
- Redaction is conservative — when uncertain, the entry is skipped, not partially exported.
