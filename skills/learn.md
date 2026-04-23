# Skill: Learn

## Trigger

Use when:
- Ahmed runs `/learn [description]` or `/learn` mid-session
- Something just worked well and Ahmed wants to capture it before the session ends
- A mistake was made and the lesson should not be lost
- Ahmed says "remember this", "add this as a pattern", "log this", or "capture that"

Command: `/learn` or `/learn [description]`

## Why Use /learn Instead of Waiting

Session-end automatic capture is passive — it catches patterns from behavior, not from explicit intent. Use `/learn` when:

- The pattern is clear right now and Ahmed wants it recorded with precision
- The situation was unusual and might not recur for automatic capture to catch
- Ahmed wants to articulate the lesson in their own words, not inferred from logs
- A negative outcome needs to be captured (automatic capture skews toward positive)
- The insight came from a conversation, not a tool action (automatic capture misses these)

Do not wait for session end if the lesson is fresh and clear right now.

## Process

### 1. Receive the command

Two forms:

**With description:**
```
/learn always check for migration files before running tests on this repo
```

**Without description:**
```
/learn
```

### 2. If no description given: ask 3 questions

Ask one at a time, not all at once. Wait for each answer before asking the next.

```
Question 1: "What situation triggered this pattern?
(e.g., 'the test suite failed because migrations were not run')"

Question 2: "What did you do that worked — or what should be done differently?
(e.g., 'run db:migrate before npm test on first checkout')"

Question 3: "Was the outcome positive, neutral, or negative?"
```

If Ahmed gives partial answers, fill in what you can and note what is missing.

### 3. If description is given: extract the fields from it

Parse the description to populate instinct fields:

- **trigger**: the situation or condition (what happened / what made this necessary)
- **behavior**: the action or rule to follow (what to do)
- **outcome**: infer from language — "always"/"works"/"fixed it" → positive; "mistake"/"don't"/"avoid" → negative; otherwise → neutral

If the description is too short to extract both trigger and behavior separately, ask:

```
Got it. One clarification: is this about a recurring situation (a trigger) or a specific action to take (a behavior)?
You can also give both: "When X, do Y."
```

### 4. Check if this should be a rule instead

If the description contains absolute language, flag it before saving as an instinct:

| Language pattern | Suggestion |
|-----------------|------------|
| "always [do X]" | This sounds like a permanent rule. Consider adding to `rules/` instead of an instinct. |
| "never [do X]" | Same — rules are enforced on every session; instincts are learned and can expire. |
| "every time [X happens]" | This is rule-level behavior. Instincts work better for context-sensitive patterns. |

Present the suggestion but do not block — if Ahmed wants to save as an instinct, proceed.

```
This sounds like a rule ("always check migrations"). Rules are enforced on every run.
Would you like to add this as a rule file instead? (yes / no, save as instinct)
```

### 5. Build the instinct object

```json
{
  "id": "<uuid-v4>",
  "created_at": "<today ISO date>",
  "expires_at": "<today + 90 days ISO date>",
  "tool_name": "<current tool or 'manual'>",
  "event_type": "manual-learn",
  "trigger": "<extracted trigger>",
  "behavior": "<extracted behavior>",
  "outcome": "<positive | neutral | negative>",
  "confidence": 0.7,
  "uses_count": 0,
  "status": "candidate"
}
```

Notes on field values:
- `confidence` starts at 0.7 for manually captured instincts (higher than auto-captured, because Ahmed explicitly reviewed it)
- `status` is `"candidate"` immediately — skip the `"pending"` stage since this was manually reviewed
- `tool_name` is `"manual"` unless Ahmed specifies a tool context
- `expires_at` is 90 days from today — longer than auto-captured instincts to reflect intentional input

### 6. Write to pending.json via instinct-utils.js

```bash
# If instinct-utils.js is available
node ~/.openclaw/instincts/instinct-utils.js add '<json string>'

# Manual fallback: append directly
python3 -c "
import json, uuid
from datetime import datetime, timedelta

path = '/root/.openclaw/instincts/pending.json'
with open(path) as f:
    data = json.load(f)

today = datetime.utcnow()
new_instinct = {
    'id': str(uuid.uuid4()),
    'created_at': today.isoformat(),
    'expires_at': (today + timedelta(days=90)).isoformat(),
    'tool_name': 'manual',
    'event_type': 'manual-learn',
    'trigger': 'TRIGGER_HERE',
    'behavior': 'BEHAVIOR_HERE',
    'outcome': 'positive',
    'confidence': 0.7,
    'uses_count': 0,
    'status': 'candidate'
}
data.append(new_instinct)
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
print('Saved:', new_instinct['id'][-8:])
"
```

### 7. Confirm to Ahmed

```
Instinct saved as candidate [id: ...a1b2c3d4].

  trigger:   "test suite fails after fresh checkout on this repo"
  behavior:  "run db:migrate before npm test"
  outcome:   positive
  confidence: 0.70
  expires:   2026-07-18

Run /instinct-status to review all candidates.
Run /evolve when you have 3+ confident instincts to cluster into a skill.
```

## Examples of Good vs Bad /learn Inputs

### Good inputs

| Input | Why it works |
|-------|-------------|
| `/learn when the PR has no ticket linked, ask for it before reviewing` | Clear trigger + clear behavior |
| `/learn running db:migrate fixed the test failures on fresh checkout` | Specific situation, concrete fix |
| `/learn avoid using default exports in this repo — named exports only` | Strong rule-level signal (suggest rule file) |
| `/learn reading the full stack trace before touching code saved 20 minutes today` | Positive outcome, specific lesson |

### Bad inputs

| Input | Problem | What to do instead |
|-------|---------|-------------------|
| `/learn be more careful` | No actionable behavior — too vague | Ask the 3 questions |
| `/learn stuff about git` | No trigger, no behavior | Ask "what specific situation?" |
| `/learn good session` | Not a pattern at all | Nothing to capture — skip |
| `/learn always use TypeScript` | Absolute rule — should be a rule file | Suggest `rules/` instead |

### When /learn is better than session-end capture

- You just solved something hard and want the exact wording preserved
- The pattern involves a conversation, not a tool action
- The outcome was negative and you want it captured explicitly
- You want confidence 0.7 from the start (vs 0.3 for auto-captured)
- You are ending the session soon and want to be sure it is saved

## Safe Behavior

- Does not write to `confident.json` — all `/learn` outputs go to `pending.json` as candidates.
- Does not automatically promote to a rule file — only suggests it if absolute language is detected.
- Does not overwrite existing instincts — always appends.
- If `pending.json` is missing, creates it as an empty array before appending.
- If `pending.json` is malformed JSON, reports the error and stops — does not overwrite.
