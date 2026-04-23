# Skill: Iterative Retrieval

## Trigger

Use when:
- A subagent must understand a codebase section before acting on it.
- The relevant files are not known upfront — they must be discovered.
- A single read pass would produce an incomplete or incorrect answer.
- Context from one retrieval round changes what to read next.
- Investigating a bug whose root cause spans multiple files.
- Planning a refactor that requires understanding call chains and dependency trees.
- Token budget is constrained and over-fetching must be avoided.

## The Context Problem

Subagents that act on codebases face a fundamental tension:

- **Too little context** — the agent makes incorrect assumptions, produces wrong patches, misses the root cause.
- **Too much context** — token budget is exhausted before the agent can act, or the relevant signal is buried in noise.

Single-shot retrieval ("read everything upfront") fails on large codebases. Iterative retrieval solves this by progressively narrowing from structure to substance.

## The 3-Phase Pattern

### Phase 1: Broad Scan (structure, not content)
Discover the shape of the problem. Read as little content as possible.

```bash
# Understand project structure
find /repo/src -type f -name "*.ts" | head -60

# Find entry points and key modules
ls /repo/src/
cat /repo/package.json | jq '.main, .scripts'

# Search for symbols, not files
grep -r "class AuthService" /repo/src --include="*.ts" -l
grep -r "export.*authenticate" /repo/src --include="*.ts" -l

# Find where the bug symptom appears
grep -r "Cannot read properties of undefined" /repo/src --include="*.ts" -l
grep -n "user\.profile" /repo/src/auth/auth.service.ts
```

After Phase 1 you should know:
- Which 3–5 files are candidates.
- The approximate line range of interest.
- What to look for in Phase 2.

### Phase 2: Targeted Read (content, not everything)
Read only the files and line ranges identified in Phase 1.

```bash
# Read only the relevant section, not the full file
sed -n '80,140p' /repo/src/auth/auth.service.ts

# Read a specific function
awk '/authenticate\(/{found=1} found{print; if(/^\}/) exit}' \
  /repo/src/auth/auth.service.ts

# Read caller sites
grep -n "authenticate(" /repo/src --include="*.ts" -r -A 3

# Read the test for this function
cat /repo/src/auth/auth.service.spec.ts | grep -A 20 "it('should authenticate"
```

After Phase 2 you should know:
- The exact lines causing the problem.
- The immediate dependencies (imports, types, callers).
- Whether another retrieval round is needed.

### Phase 3: Synthesis
Combine what was retrieved into a coherent understanding before acting.

Synthesis checklist:
- [ ] Root cause is identified, not just the symptom.
- [ ] All relevant callers and callees are understood.
- [ ] The fix does not break any identified caller.
- [ ] Test coverage for the change path is understood.
- [ ] Any cross-cutting concern (auth, logging, error handling) is accounted for.

Do not act until synthesis is complete. Acting on Phase 1 or Phase 2 results alone leads to patches that fix one call site and break another.

## Trigger Iterative vs Single-Shot

| Signal | Use Iterative | Use Single-Shot |
|--------|--------------|-----------------|
| Files relevant to the task are unknown | Yes | No |
| Task spans > 3 files | Yes | No |
| Bug root cause is unclear | Yes | No |
| Task is "read this file and summarize it" | No | Yes |
| Files are specified explicitly by Ahmed | No | Yes |
| Token budget is below 10k remaining | Simplified (2 phases) | Prefer |
| Codebase is < 20 files total | No | Yes |
| Previous round changed what to look for | Yes (loop) | No |

## Token Budget Awareness

Track token consumption across retrieval rounds to avoid exhausting the budget before acting.

```typescript
interface RetrievalBudget {
  totalBudget: number;        // e.g. 180_000 for claude-opus-4-5
  retrievalCap: number;       // max tokens to spend on retrieval (e.g. 60% = 108_000)
  spent: number;              // tokens consumed so far
  reserved: number;           // tokens reserved for output (e.g. 8_192)
}

function canRetrieve(budget: RetrievalBudget, estimatedTokens: number): boolean {
  return (budget.spent + estimatedTokens) < (budget.retrievalCap);
}

function estimateFileTokens(filePath: string): number {
  const { size } = fs.statSync(filePath);
  return Math.ceil(size / 4); // rough: 1 token ≈ 4 bytes
}
```

```bash
# Estimate file size before reading
wc -c /repo/src/auth/auth.service.ts
# 12,847 bytes → ~3,212 tokens → safe to read if budget allows

# For large files, read only the relevant section
wc -l /repo/src/auth/auth.service.ts   # 420 lines
# Read only lines 80-140 → 60 lines → ~300 tokens → efficient
```

Budget thresholds:
| Remaining Budget | Strategy |
|-----------------|----------|
| > 80k tokens | Normal iterative retrieval, up to 3 rounds |
| 40k–80k tokens | Limit to 2 rounds, prefer grep over full reads |
| 10k–40k tokens | Single targeted read only, no broad scan |
| < 10k tokens | No retrieval — synthesize from what is already known |

## Retrieval Strategies by Task Type

### Code Exploration (understanding an unfamiliar module)

```bash
# Round 1: directory and exports
ls /repo/src/payments/
cat /repo/src/payments/index.ts

# Round 2: read the main class/module
cat /repo/src/payments/payment.service.ts

# Round 3 (if needed): read called utilities
grep -n "import" /repo/src/payments/payment.service.ts | head -20
# → follow imports that are local (not node_modules)
```

Stop when: you can describe the module's public API, its key dependencies, and its error handling.

### Bug Investigation (narrowing to root cause)

```bash
# Round 1: locate the symptom
grep -rn "TypeError\|undefined is not" /repo/logs/error.log | tail -20
grep -rn "processPayment" /repo/src --include="*.ts" -l

# Round 2: read the failing function and its direct callers
sed -n '$(grep -n "processPayment" /repo/src/payments/payment.service.ts | head -1 | cut -d: -f1)p' \
  /repo/src/payments/payment.service.ts
# or more simply:
grep -n "processPayment" /repo/src/payments/payment.service.ts -A 30 | head -35

# Round 3 (if root cause not found): trace the data flow upstream
grep -n "processPayment(" /repo/src --include="*.ts" -r -B 3
```

Stop when: you can name the exact line causing the bug and why.

### Refactor Planning (impact analysis before changing an API)

```bash
# Round 1: find all usages of the symbol being changed
grep -rn "UserRepository" /repo/src --include="*.ts" -l

# Round 2: read each usage file's import and call pattern
for f in $(grep -rn "UserRepository" /repo/src --include="*.ts" -l); do
  echo "=== $f ==="
  grep -n "UserRepository" "$f" -A 2 -B 1
done

# Round 3: read the current interface/type definition
grep -n "interface UserRepository\|class UserRepository" \
  /repo/src/users/user.repository.ts -A 30 | head -35
```

Stop when: you have a complete list of all call sites and their usage patterns.

## Passing Context Between Retrieval Rounds

Do not carry raw file content across rounds. Carry **summaries** of what was learned.

```typescript
interface RetrievalRound {
  round: number;
  goal: string;               // what this round was trying to find
  filesRead: string[];        // which files/lines were read
  learned: string;            // concise summary of findings
  nextGoal: string | null;    // what to look for next, or null if done
}

// Example round progression
const rounds: RetrievalRound[] = [
  {
    round: 1,
    goal: "Find files involved in payment processing",
    filesRead: ["src/payments/index.ts", "src/payments/payment.service.ts"],
    learned: "PaymentService.processPayment() at line 87 calls stripe.charge(). Stripe client initialized in constructor from env.STRIPE_SECRET_KEY.",
    nextGoal: "Check if env.STRIPE_SECRET_KEY is validated on startup",
  },
  {
    round: 2,
    goal: "Check if env.STRIPE_SECRET_KEY is validated on startup",
    filesRead: ["src/config/config.service.ts:12-45"],
    learned: "Config is loaded lazily — STRIPE_SECRET_KEY is read at first use, not on startup. No validation. If missing, stripe.charge() throws with opaque error.",
    nextGoal: null, // root cause found
  },
];
```

```bash
# Bash: accumulate a summary file across rounds
SUMMARY=/tmp/retrieval-summary-$$.txt

# Round 1
echo "=== Round 1 ===" >> $SUMMARY
echo "Files: src/payments/payment.service.ts" >> $SUMMARY
echo "Learned: processPayment calls stripe.charge at line 87" >> $SUMMARY
echo "Next: validate env.STRIPE_SECRET_KEY loading" >> $SUMMARY

# Pass summary to next round's prompt
cat $SUMMARY
```

## Stopping Criteria

Stop retrieval when any of the following is true:

| Condition | Action |
|-----------|--------|
| Root cause is identified with specific file + line | Proceed to fix |
| All call sites for a refactor are enumerated | Proceed to plan |
| The module's public API is understood | Proceed to task |
| 3 rounds completed with no new information | Synthesize from what is known, flag uncertainty |
| Token budget below threshold | Stop, synthesize from available context |
| Two consecutive rounds return the same set of files | Deadlock — stop and report |

Never start a 4th retrieval round without a clear, different question than round 3.

## Anti-Patterns

- **Reading entire files when only one function is relevant** — use line ranges or grep with `-A` context.
- **Starting to write code after only Phase 1** — broad scan is not enough to act safely.
- **Re-reading the same file in every round** — if you needed it in round 1, summarize it; don't re-read.
- **Carrying raw file content in the summary** — summaries must be concise; carry conclusions, not raw text.
- **Unlimited retrieval rounds** — cap at 3 rounds unless there is a specific reason logged for a 4th.
- **Guessing at file paths** — always verify a path exists before reading it.
- **Ignoring token budget** — retrieval that exhausts the budget before acting produces no value.

## Safe Behavior

- Retrieval is read-only — no modifications during the retrieval phases.
- File paths discovered during retrieval are verified before read (check existence, check they are in-scope).
- Retrieval does not follow symlinks outside the workspace root.
- Secrets encountered during retrieval (API keys, passwords) are not logged in summaries.
- If retrieval reveals a security finding unrelated to the task, it is reported immediately before continuing.
- Synthesis conclusions are stated with explicit uncertainty when the retrieved evidence is incomplete.
