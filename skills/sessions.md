# Skill: Sessions

## Trigger

Use when you want to list past Claude Code sessions, find a previous conversation, search session history, or resume context from an earlier session.

## Session File Structure

Claude Code stores sessions under `~/.claude/projects/`. Each project directory maps to a working directory path (slashes replaced with dashes).

```
~/.claude/projects/
└── -home-user-myproject/
    └── <session-id>.jsonl      # one JSONL file per session
```

Each `.jsonl` file contains one JSON object per line. The first user-role entry is the conversation opener.

| Field | Description |
|-------|-------------|
| `uuid` | Session ID used for `--resume` |
| `timestamp` | ISO-8601 creation time |
| `message.role` | `user` or `assistant` |
| `message.content` | Message text or structured content |

## Process

### 1. List recent sessions

```bash
# All sessions across all projects, sorted newest first
ls -lt ~/.claude/projects/*/*.jsonl 2>/dev/null | head -40

# Sessions for the current project only
PROJECT_KEY=$(pwd | sed 's|/|-|g')
ls -lt ~/.claude/projects/${PROJECT_KEY}/*.jsonl 2>/dev/null
```

### 2. Show session summaries

For each session file, extract the date and the first user message:

```bash
for f in ~/.claude/projects/*/*.jsonl; do
  SESSION_ID=$(basename "$f" .jsonl)
  DATE=$(stat -c %y "$f" | cut -d' ' -f1)
  FIRST_MSG=$(grep '"role":"user"' "$f" 2>/dev/null | head -1 | \
    python3 -c "import sys,json; d=json.loads(sys.stdin.read()); \
    c=d.get('message',{}).get('content',''); \
    print((c if isinstance(c,str) else c[0].get('text',''))[:80])" 2>/dev/null)
  echo "$DATE  $SESSION_ID  $FIRST_MSG"
done | sort -r
```

### 3. Filter options

| Flag | Behavior |
|------|----------|
| `--today` | Sessions where file mtime is today |
| `--last-7` | Sessions from the past 7 days |
| `--project <name>` | Sessions under `~/.claude/projects/*<name>*/` |

```bash
# --today
find ~/.claude/projects -name "*.jsonl" -newer "$(date -d 'yesterday' +%Y-%m-%d)" 2>/dev/null

# --last-7
find ~/.claude/projects -name "*.jsonl" -mtime -7 2>/dev/null | sort -t/ -k6 -r

# --project myapp
ls -lt ~/.claude/projects/*myapp*/*.jsonl 2>/dev/null
```

### 4. Search sessions

```bash
# Search all sessions for a keyword
grep -r "keyword" ~/.claude/projects/*/  --include="*.jsonl" -l

# Search with context
grep -r "keyword" ~/.claude/projects/*/*.jsonl | \
  python3 -c "import sys,json
for line in sys.stdin:
  try:
    parts = line.split(':', 2)
    d = json.loads(parts[2])
    c = d.get('message',{}).get('content','')
    text = c if isinstance(c,str) else ''.join(b.get('text','') for b in c if isinstance(b,dict))
    if 'keyword' in text:
      print(parts[0], text[:120])
  except: pass"
```

### 5. Resume a session

To resume a session in Claude Code CLI:

```bash
claude --resume <session-id>
```

The session ID is the `.jsonl` filename without the extension. Example:

```bash
SESSION_ID="a1b2c3d4-e5f6-7890-abcd-ef1234567890"
claude --resume $SESSION_ID
```

### 6. Export a session summary

```bash
# Export all messages from a session to plain text
SESSION_FILE=~/.claude/projects/-home-user-myproject/<session-id>.jsonl
python3 - <<'EOF'
import json, sys
for line in open(sys.argv[1]):
    try:
        d = json.loads(line)
        role = d.get('message', {}).get('role', '')
        content = d.get('message', {}).get('content', '')
        text = content if isinstance(content, str) else \
               ' '.join(b.get('text','') for b in content if isinstance(b,dict))
        if text.strip():
            print(f"[{role.upper()}] {text[:500]}\n")
    except: pass
EOF $SESSION_FILE
```

### 7. Use session context in a new conversation

If you cannot resume directly, paste the summary output into your new session and say:
> "This is context from a previous session. Continue from here."

Alternatively, export to a file and reference it:
```bash
python3 export_session.py $SESSION_FILE > /tmp/session-context.txt
claude "$(cat /tmp/session-context.txt)\n\nContinue the work above."
```

## Safe Behavior

- Read-only — no session files are modified.
- No session data is sent to external services.
- Session IDs are local identifiers; do not share them in public contexts.
