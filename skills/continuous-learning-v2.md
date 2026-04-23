# Skill: Continuous Learning v2

## Trigger

Use when:
- A session ends and behavioral patterns worth retaining have emerged.
- Ahmed says "remember that", "add that as a rule", "that was a good pattern".
- Running `/instinct-status`, `/instinct-import`, `/instinct-export`, `/evolve`, or `/prune`.
- The instinct store has pending items awaiting confidence scoring.
- Reviewing whether a cluster of instincts has hardened into a promotable skill.

## Process

### 1. Capture raw instinct from session
At the end of any session where a novel pattern was applied, log it immediately before context is lost.

```bash
# Append to instinct staging file
cat >> ~/.openclaw/workspace-sand/memory/instincts/pending.yaml << 'EOF'
- id: inst-$(date +%s)
  created: $(date -u +%Y-%m-%dT%H:%M:%SZ)
  source_session: <session-id>
  trigger: "<what situation triggered this>"
  behavior: "<what I did>"
  outcome: positive | negative | neutral
  confidence: 0.1
  status: pending
  tags: []
EOF
```

### 2. Score the instinct
Apply the confidence scoring table to each pending instinct before committing it.

### 3. Promote or discard
- `confidence >= 0.7` → move to `instincts/confident/`
- `confidence >= 0.9` → candidate for skill promotion via `/evolve`
- `confidence < 0.3` after 3 sessions → discard via `/prune`

### 4. Cluster into skills
When 3+ confident instincts share a tag and form a coherent workflow, run `/evolve` to draft a new skill file.

### 5. Archive evolved instincts
After a skill is written and accepted, mark source instincts as `status: evolved` — do not delete them. They remain as provenance.

## Instinct Lifecycle

```
pending (new, unscored)
  │
  ├─ confidence < 0.3 after 3 sessions → PRUNED
  │
  ├─ confidence 0.3–0.69 → CANDIDATE (needs more evidence)
  │
  └─ confidence >= 0.7 → CONFIDENT
                            │
                            └─ confidence >= 0.9, clusterable → EVOLVED (promoted to skill)
```

## Instinct YAML Format

Each instinct is a YAML document stored flat under `memory/instincts/`.

```yaml
# memory/instincts/confident/inst-1713524800.yaml
id: inst-1713524800
created: 2026-04-19T08:00:00Z
source_session: sess-abc123
trigger: "User asks to debug a failing test with no stack trace"
behavior: "Run test with --verbose before reading any source file"
outcome: positive
evidence_count: 4        # how many sessions this was applied
confidence: 0.82
status: confident
tags:
  - testing
  - debugging
  - information-gathering
related_instincts:
  - inst-1713481200
  - inst-1713395400
notes: "Always collect observable data before hypothesis — applies beyond tests"
evolved_into: null       # filled when promoted to a skill
```

## Confidence Scoring Table

| Factor | Weight | How to Score |
|--------|--------|--------------|
| Positive outcome in this session | +0.15 | Did the behavior achieve the goal? |
| Ahmed explicitly approved the behavior | +0.20 | Direct confirmation, not silence |
| Applied successfully in 2+ prior sessions | +0.10 per session (max +0.30) | Check `evidence_count` |
| Outcome was negative | -0.20 | Behavior caused a problem |
| Ahmed corrected or reversed the behavior | -0.30 | Explicit rejection |
| Applies to only one narrow edge case | -0.10 | Low generalizability |
| Conflicts with an existing rule | -0.25 | Check rules/ before scoring |
| No evidence of outcome (neutral) | +0.00 | Do not score positively |

Starting confidence for all new instincts: **0.10**
Maximum confidence cap before skill promotion: **1.00**

## Commands

### `/instinct-status`
Show all instincts by lifecycle stage.

```bash
echo "=== PENDING ==="
ls ~/.openclaw/workspace-sand/memory/instincts/pending/ 2>/dev/null | wc -l

echo "=== CONFIDENT ==="
ls ~/.openclaw/workspace-sand/memory/instincts/confident/ 2>/dev/null

echo "=== EVOLVED ==="
grep -r "status: evolved" ~/.openclaw/workspace-sand/memory/instincts/ --include="*.yaml" -l
```

Output format:
```
PENDING:  3 instincts (unscored)
CONFIDENT: inst-1713524800 [conf=0.82, tags=testing,debugging]
           inst-1713481200 [conf=0.75, tags=git,commits]
EVOLVED:  inst-1713300000 → skill: commit-discipline.md
PRUNED:   2 instincts (archived)
```

### `/instinct-import <session-id>`
Pull patterns from a named session into the pending queue. Used after reviewing a session log.

```bash
# Extract candidate behaviors from session log
grep -E "(worked|fixed|resolved|good pattern|remember)" \
  ~/.openclaw/logs/<session-id>.log | \
  while read line; do
    echo "Candidate: $line"
  done
```

### `/instinct-export`
Dump all confident instincts to a portable YAML bundle for backup or transfer.

```bash
find ~/.openclaw/workspace-sand/memory/instincts/confident/ -name "*.yaml" \
  -exec cat {} \; > /tmp/instincts-export-$(date +%Y%m%d).yaml

echo "Exported $(ls ~/.openclaw/workspace-sand/memory/instincts/confident/ | wc -l) instincts"
```

### `/evolve [tag]`
Cluster confident instincts by tag and draft a skill file.

```bash
# Find all instincts with a given tag
grep -r "tags:.*<tag>" ~/.openclaw/workspace-sand/memory/instincts/confident/ \
  --include="*.yaml" -l

# Review clusters and draft skill structure
# Then write to tools/ecc-safe-plus/skills/<derived-name>.md
```

Evolve only when:
- 3+ confident instincts share a tag.
- The behaviors form a coherent, repeatable workflow.
- Ahmed approves the skill draft before it is committed.

### `/prune`
Remove or archive instincts that failed to gain confidence.

```bash
# Find stale pending instincts (older than 14 days, confidence < 0.3)
find ~/.openclaw/workspace-sand/memory/instincts/pending/ -name "*.yaml" \
  -mtime +14 | while read f; do
    conf=$(grep "confidence:" "$f" | awk '{print $2}')
    if (( $(echo "$conf < 0.3" | bc -l) )); then
      echo "PRUNE: $f (conf=$conf)"
      mv "$f" ~/.openclaw/workspace-sand/memory/instincts/pruned/
    fi
  done
```

## Instinct vs Skill Distinction

| Property | Instinct | Skill |
|----------|----------|-------|
| Source | Observed behavior from sessions | Deliberate design or evolved instincts |
| Format | YAML frontmatter, short prose | Full .md with sections, examples, commands |
| Lifecycle | pending → confident → evolved | Stable unless revised |
| Scope | Single behavior or heuristic | Complete workflow with steps |
| Requires approval | On promotion only | Always before write |
| Lives in | `memory/instincts/` | `tools/ecc-safe-plus/skills/` |
| Can be pruned | Yes | Deprecated, not deleted |

## What Makes a Good Instinct

A good instinct is:
- **Specific** — "run tests before reading source on a failing test" not "be thorough".
- **Actionable** — maps to a concrete behavior, not a value.
- **Falsifiable** — you can tell if it worked or failed.
- **Generalizable** — applies in at least 3 different contexts.
- **Not already a rule** — check `rules/` before logging a new instinct.

Anti-patterns:
- "Be careful" → too vague, not an instinct.
- "Ahmed likes clean code" → not actionable.
- Instincts derived from a single session with neutral outcome → premature.
- Logging every single action as an instinct → noise, degrades signal quality.

## Safe Behavior

- Instincts are never applied automatically — they inform behavior, they do not override rules.
- No instinct overrides an explicit rule in `rules/`.
- `/evolve` drafts are shown to Ahmed before any file is written.
- `/prune` moves to `pruned/` directory — never hard-deletes.
- Confidence scores are never inflated; negative evidence is always applied.
- Instincts from a single session with no follow-up evidence stay at `pending` — they do not auto-promote.
