# Skill: Learn Eval

## Trigger

Use when:
- Ahmed runs `/learn-eval`
- Ahmed wants a pattern captured but wants it evaluated rigorously before it enters the store
- Ahmed says "is this worth saving?", "evaluate this pattern", or "quality-check this before storing it"
- A lesson is potentially valuable but feels narrow, obvious, or vague — use `/learn-eval` instead of `/learn` to decide

Command: `/learn-eval`

## /learn vs /learn-eval

| Situation | Use |
|-----------|-----|
| Pattern is clear, Ahmed is confident it generalizes | `/learn` — fast capture, starts at confidence 0.7 |
| Pattern might be too narrow or obvious | `/learn-eval` — gates decide if it's worth storing |
| Lesson came from a one-off unusual situation | `/learn-eval` — check generalizability first |
| Negative outcome that should never repeat | `/learn` — capture immediately, don't risk losing it |
| Pattern is a candidate for a rule, not just an instinct | `/learn` with the rule-file suggestion |
| You are not sure if the lesson is real or just noise | `/learn-eval` — let the gates filter it |

`/learn-eval` is slower and more rigorous. Use it when quality matters more than speed.

## Process

### 1. Capture the pattern

Ask the same 3 questions as `/learn`. Ask one at a time, wait for each answer:

```
Question 1: "What situation triggered this pattern?
(e.g., 'the test suite failed because migrations were not run')"

Question 2: "What did you do that worked — or what should be done differently?
(e.g., 'run db:migrate before npm test on first checkout')"

Question 3: "Was the outcome positive, neutral, or negative?"
```

If Ahmed gave a description with the command, extract trigger/behavior/outcome from it instead of asking. If the description is too short to yield both trigger and behavior, ask for clarification.

Do not save anything yet. Hold the extracted fields for evaluation.

### 2. Run the 5 quality gates

Evaluate the extracted trigger and behavior against each gate in order. Score 1 point for each gate passed. Score 0 for a fail or uncertain result.

#### Gate 1: Generalizable?

**Question:** Does this pattern apply across multiple sessions or projects, or is it specific to one unique situation?

| Pass | Fail |
|------|------|
| "When a PR has no linked ticket, ask for it" — happens everywhere | "When that one legacy API at $company returns a 503, restart the proxy" |
| "Read the full stack trace before touching code" — universal | "When Ahmed's laptop has low battery, skip the long test suite" |
| "Run linting before committing in any new repo" | "The CSV file Ahmed sent on April 10th needed the header row removed" |

A pattern is too narrow if it names a specific person (other than a general role), a specific file, a one-time event, or a system that no other context would have.

#### Gate 2: Non-obvious?

**Question:** Is this something a reasonably skilled practitioner would already know, or is it a documented best practice?

| Pass | Fail |
|------|------|
| "In this repo, tests require migrations to run first — this is not documented" | "Always read the error message before fixing the bug" |
| "Asking for the outcome before reading logs cuts turnaround by 60%" | "Commit often" |
| "This team's PR review etiquette requires a ticket link — not standard" | "Use version control for code" |

Generic advice that any developer handbook covers is not worth storing as a personal instinct. Instincts capture the non-obvious, context-specific, or empirically-discovered.

#### Gate 3: Actionable?

**Question:** Does the behavior describe a concrete step you can actually take, or is it vague advice?

| Pass | Fail |
|------|------|
| "Run `db:migrate` before `npm test` on first checkout" | "Be more careful with databases" |
| "Ask 'what outcome are you expecting?' before reading logs" | "Be more communicative" |
| "Check for existing migrations in `/db/migrate/` before writing a new one" | "Think before acting" |

If you cannot tell whether the behavior was followed or not, it is not actionable. The behavior must name a specific action, command, question, or step.

#### Gate 4: Verifiable?

**Question:** Can you tell, after the fact, whether you followed this pattern or not?

| Pass | Fail |
|------|------|
| "Run lint before committing" — either you ran it or you didn't | "Be thorough" — no clear signal |
| "Ask for the ticket number before starting review" — auditable from conversation | "Try to understand the context" — too fuzzy |
| "Read the full error output, not just the last line" — checkable | "Approach problems carefully" — not checkable |

Verifiability is distinct from actionability. Actionable means you know what to do. Verifiable means you can confirm you did it. Both are required.

#### Gate 5: Safe?

**Question:** Does the trigger or behavior contain secrets, personal data, destructive commands, or patterns that could cause harm if replicated?

| Pass | Fail |
|------|------|
| "Run db:migrate before tests" | "Use API_KEY=abc123 for the staging env" |
| "Ask for ticket number before review" | "SSH to 192.168.1.10 and restart the service" |
| "Check for migrations before writing new ones" | "rm -rf the cache dir when tests hang" |

If the pattern references a specific credential, IP, hostname, destructive command, or personal identifier, it fails this gate regardless of how useful it seems. Do not save unsafe patterns — they become a liability.

### 3. Show the evaluation score

After running all 5 gates, display the result:

```
Evaluation complete.

Pattern:
  trigger:   "test suite fails after fresh checkout on this repo"
  behavior:  "run db:migrate before npm test"
  outcome:   positive

Quality Gates:
  [PASS] Generalizable    — applies to any repo with unmigrated DB schema
  [PASS] Non-obvious      — not documented, discovered empirically
  [PASS] Actionable       — specific command to run
  [PASS] Verifiable       — you either ran it or you didn't
  [PASS] Safe             — no credentials or destructive content

Score: 5/5
```

For a partial score:

```
Quality Gates:
  [PASS] Generalizable    — applies across projects
  [FAIL] Non-obvious      — "always read error messages" is basic advice
  [PASS] Actionable       — concrete behavior described
  [FAIL] Verifiable       — "be more careful" cannot be confirmed
  [PASS] Safe             — no sensitive content

Score: 3/5
  Failed: Non-obvious, Verifiable
```

### 4. Apply the save decision

| Score | Decision | Saved as | Confidence |
|-------|----------|----------|------------|
| 0–2 | Rejected | Not saved | — |
| 3–4 | Saved as pending | pending.json | 0.30 |
| 5 | Saved as candidate | pending.json | 0.60 |

**Score 0–2: reject**

```
Decision: Not saved.

This pattern did not meet the minimum threshold (3/5 gates).
Failed gates: Non-obvious, Verifiable

What to do:
  - Rephrase the behavior to be more concrete, then re-run /learn-eval
  - Or use /learn if you want to force-save with lower confidence
```

**Score 3–4: save as pending**

Build the instinct object with `status: "pending"` and `confidence: 0.30`, append to `pending.json`. Confirm:

```
Decision: Saved as pending.

  id:         ...a1b2c3d4
  trigger:    "..."
  behavior:   "..."
  confidence: 0.30
  status:     pending
  expires:    2026-07-18

It did not pass all gates, but is worth tracking.
Run /instinct-status to review. Promote manually if it proves useful.
```

**Score 5: save as candidate**

Build the instinct object with `status: "candidate"` and `confidence: 0.60`, append to `pending.json`. Confirm:

```
Decision: Saved as candidate.

  id:         ...f9e87654
  trigger:    "..."
  behavior:   "..."
  confidence: 0.60
  status:     candidate
  expires:    2026-07-18

Passed all 5 gates. This is a strong pattern.
Run /instinct-status to review all candidates.
Run /evolve when you have 3+ confident instincts to cluster into a skill.
```

### 5. Build and write the instinct object

```json
{
  "id": "<uuid-v4>",
  "created_at": "<today ISO date>",
  "expires_at": "<today + 90 days ISO date>",
  "tool_name": "manual",
  "event_type": "manual-learn-eval",
  "trigger": "<extracted trigger>",
  "behavior": "<extracted behavior>",
  "outcome": "<positive | neutral | negative>",
  "confidence": "<0.30 or 0.60 based on score>",
  "uses_count": 0,
  "status": "<pending or candidate based on score>",
  "eval_score": "<N>/5",
  "eval_gates_failed": ["<gate name>", ...]
}
```

The `eval_score` and `eval_gates_failed` fields are stored for traceability — so when reviewing in `/instinct-status`, you can see why this instinct started at a given confidence.

```bash
# Manual fallback: write to pending.json
python3 -c "
import json, uuid
from datetime import datetime, timedelta

path = '/root/.openclaw/instincts/pending.json'
with open(path) as f:
    data = json.load(f)

today = datetime.utcnow()
score = 5  # replace with actual score
confidence = 0.60 if score == 5 else 0.30
status = 'candidate' if score == 5 else 'pending'

new_instinct = {
    'id': str(uuid.uuid4()),
    'created_at': today.isoformat(),
    'expires_at': (today + timedelta(days=90)).isoformat(),
    'tool_name': 'manual',
    'event_type': 'manual-learn-eval',
    'trigger': 'TRIGGER_HERE',
    'behavior': 'BEHAVIOR_HERE',
    'outcome': 'positive',
    'confidence': confidence,
    'uses_count': 0,
    'status': status,
    'eval_score': f'{score}/5',
    'eval_gates_failed': []
}
data.append(new_instinct)
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
print('Saved:', new_instinct['id'][-8:], '— score:', score)
"
```

## Evaluation Rubric

Full pass/fail examples for each gate:

| Gate | Pass example | Fail example | Why it matters |
|------|-------------|--------------|----------------|
| **Generalizable** | "When any PR lacks a ticket, ask for it" | "When that one contractor sends PRs, ask for tickets" | Too-narrow instincts only fire once — not worth the storage |
| **Non-obvious** | "This repo requires migrations before tests — not in README" | "Read error messages before fixing bugs" | Obvious patterns waste a slot better used for real discoveries |
| **Actionable** | "Run `npm ci` before `npm test`" | "Be more methodical about dependencies" | Vague behaviors never get followed — or never get credit for being followed |
| **Verifiable** | "Always ask for ticket number before starting" | "Try to understand context better" | If you can't tell you followed it, it cannot improve with use |
| **Safe** | "Check migration status before writing a new one" | "POSTGRES_URL=postgres://user:pass@host/db" | Unsafe patterns become liabilities, not assets |

## Safe Behavior

- Does not save anything until after evaluation is complete.
- Does not save rejected patterns (score < 3) — no silent fallback to a lower-confidence save.
- Does not write to `confident.json` — all `/learn-eval` outputs go to `pending.json`.
- Does not overwrite existing instincts — always appends.
- If `pending.json` is missing, creates it as an empty array before appending.
- If `pending.json` is malformed JSON, reports the error and stops — does not overwrite.
- Ahmed can override a rejection by using `/learn` directly — `/learn-eval` does not block, it advises.
