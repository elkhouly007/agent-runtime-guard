# Skill: Autonomous Loops

## Trigger

Use when:
- A task must repeat until a condition is met (e.g., "keep fixing tests until they pass").
- A pipeline has multiple sequential stages that each produce output consumed by the next.
- A PR review cycle needs to run → fix → re-check without manual intervention.
- Orchestrating a DAG of parallel + sequential agent work.
- Ahmed says "loop until done", "keep going", "watch and fix", or "run this on a schedule".
- Using `/loop-start` or checking `/loop-status`.

## Trigger Loops vs Single-Shot

| Situation | Loop | Single-Shot |
|-----------|------|-------------|
| Outcome is not deterministic upfront | Yes | No |
| Task has a natural exit condition | Yes | No |
| One-pass analysis or generation | No | Yes |
| Side effects are safe to repeat | Yes | Caution |
| External state changes between passes | Yes | No |
| Token budget is very limited | No | Yes |
| Ahmed is watching and will intervene | Single-shot preferred | — |

**Default to single-shot.** Use loops only when the problem genuinely requires iteration.

## Pattern 1: Sequential Pipeline

Each stage reads the previous stage's output. Stages run one at a time.

**Use for:** test-fix cycles, lint-fix cycles, multi-pass document processing.

```typescript
// sequential-pipeline.ts
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

interface PipelineStage {
  name: string;
  prompt: (context: string) => string;
  exitCondition: (output: string) => boolean;
}

async function runPipeline(
  stages: PipelineStage[],
  initialContext: string,
  maxRounds = 5
): Promise<string> {
  let context = initialContext;

  for (const stage of stages) {
    let round = 0;
    let done = false;

    while (!done && round < maxRounds) {
      round++;
      console.log(`[${stage.name}] Round ${round}`);

      const response = await client.messages.create({
        model: "claude-opus-4-5",
        max_tokens: 4096,
        messages: [{ role: "user", content: stage.prompt(context) }],
      });

      const output =
        response.content[0].type === "text" ? response.content[0].text : "";

      done = stage.exitCondition(output);
      context = output; // next stage receives this stage's output
    }

    if (round >= maxRounds) {
      console.warn(`[${stage.name}] Max rounds reached — moving on`);
    }
  }

  return context;
}

// Example: test-fix pipeline
const stages: PipelineStage[] = [
  {
    name: "RunTests",
    prompt: (ctx) => `Run these tests and report failures:\n${ctx}`,
    exitCondition: (out) => out.includes("All tests passed"),
  },
  {
    name: "FixFailures",
    prompt: (ctx) => `Fix the failing tests reported here:\n${ctx}`,
    exitCondition: (out) => out.includes("FIXED"),
  },
];

runPipeline(stages, "npm test 2>&1", 5).then(console.log);
```

Bash equivalent (simpler cases):

```bash
#!/usr/bin/env bash
MAX_ROUNDS=5
ROUND=0

while [ $ROUND -lt $MAX_ROUNDS ]; do
  ROUND=$((ROUND + 1))
  echo "[Round $ROUND] Running tests..."

  OUTPUT=$(npm test 2>&1)

  if echo "$OUTPUT" | grep -q "passing" && ! echo "$OUTPUT" | grep -q "failing"; then
    echo "All tests passing — loop complete."
    exit 0
  fi

  echo "Failures found — invoking fix agent..."
  # Invoke fix agent here, e.g.:
  # claude --prompt "Fix these test failures: $OUTPUT" --model claude-opus-4-5
done

echo "WARNING: Max rounds reached without passing tests."
exit 1
```

## Pattern 2: PR Review Loop

Watch a PR, comment on issues, wait for pushes, re-review until approved or abandoned.

**Use for:** automated PR review that responds to developer fixes.

```typescript
// pr-review-loop.ts
import { execSync } from "child_process";

interface PRState {
  sha: string;
  approved: boolean;
  round: number;
}

async function prReviewLoop(prNumber: number, maxRounds = 8): Promise<void> {
  const state: PRState = { sha: "", approved: false, round: 0 };

  while (!state.approved && state.round < maxRounds) {
    state.round++;

    // Get current HEAD SHA
    const currentSha = execSync(
      `gh pr view ${prNumber} --json headRefOid -q .headRefOid`
    )
      .toString()
      .trim();

    if (currentSha === state.sha) {
      console.log(`[Round ${state.round}] No new commits — waiting 60s...`);
      await sleep(60_000);
      continue;
    }

    state.sha = currentSha;
    console.log(`[Round ${state.round}] New commit ${currentSha} — reviewing`);

    // Run review agent
    const diff = execSync(`gh pr diff ${prNumber}`).toString();
    const review = await runReviewAgent(diff);

    if (review.verdict === "approve") {
      execSync(`gh pr review ${prNumber} --approve -b "${review.summary}"`);
      state.approved = true;
    } else {
      execSync(
        `gh pr review ${prNumber} --request-changes -b "${review.findings}"`
      );
    }
  }

  if (!state.approved) {
    console.warn(`PR ${prNumber} not approved after ${state.round} rounds.`);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function runReviewAgent(
  diff: string
): Promise<{ verdict: string; summary: string; findings: string }> {
  // Invoke code-review skill via agent
  return { verdict: "request-changes", summary: "", findings: "" };
}
```

```bash
# Bash version — simpler, less stateful
PR=$1
MAX_ROUNDS=8
ROUND=0
LAST_SHA=""

while [ $ROUND -lt $MAX_ROUNDS ]; do
  ROUND=$((ROUND + 1))
  CURRENT_SHA=$(gh pr view "$PR" --json headRefOid -q .headRefOid)

  if [ "$CURRENT_SHA" = "$LAST_SHA" ]; then
    echo "[Round $ROUND] No new commits — sleeping 60s"
    sleep 60
    continue
  fi

  LAST_SHA=$CURRENT_SHA
  echo "[Round $ROUND] Reviewing $CURRENT_SHA"

  STATUS=$(gh pr view "$PR" --json reviewDecision -q .reviewDecision)
  [ "$STATUS" = "APPROVED" ] && { echo "PR approved."; exit 0; }

  # Invoke review agent
  gh pr diff "$PR" | claude --prompt "Review this PR diff and output APPROVE or REQUEST_CHANGES with findings."
done

echo "Max rounds reached — escalate to Ahmed."
exit 1
```

## Pattern 3: DAG Orchestration

Parallel branches converge at a join before proceeding. Use when subtasks are independent.

**Use for:** multi-file analysis, parallel agent work, fan-out/fan-in pipelines.

```typescript
// dag-orchestrator.ts
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

interface DAGNode {
  id: string;
  dependencies: string[];
  task: (inputs: Record<string, string>) => Promise<string>;
}

async function runDAG(nodes: DAGNode[]): Promise<Record<string, string>> {
  const results: Record<string, string> = {};
  const completed = new Set<string>();

  while (completed.size < nodes.length) {
    // Find all nodes whose dependencies are satisfied
    const ready = nodes.filter(
      (n) =>
        !completed.has(n.id) && n.dependencies.every((d) => completed.has(d))
    );

    if (ready.length === 0) {
      throw new Error("DAG deadlock — check for circular dependencies");
    }

    // Run ready nodes in parallel
    const batch = await Promise.all(
      ready.map(async (node) => {
        const inputs = Object.fromEntries(
          node.dependencies.map((d) => [d, results[d]])
        );
        const output = await node.task(inputs);
        return { id: node.id, output };
      })
    );

    for (const { id, output } of batch) {
      results[id] = output;
      completed.add(id);
      console.log(`[DAG] Completed: ${id}`);
    }
  }

  return results;
}

// Example: parallel code review + security scan, then combined report
const dag: DAGNode[] = [
  {
    id: "code-review",
    dependencies: [],
    task: async () => {
      /* invoke code-reviewer agent */
      return "code review output";
    },
  },
  {
    id: "security-scan",
    dependencies: [],
    task: async () => {
      /* invoke security-scan agent */
      return "security scan output";
    },
  },
  {
    id: "combined-report",
    dependencies: ["code-review", "security-scan"],
    task: async (inputs) => {
      const prompt = `Combine these findings into one report:\n\nCode Review:\n${inputs["code-review"]}\n\nSecurity:\n${inputs["security-scan"]}`;
      const response = await client.messages.create({
        model: "claude-opus-4-5",
        max_tokens: 2048,
        messages: [{ role: "user", content: prompt }],
      });
      return response.content[0].type === "text"
        ? response.content[0].text
        : "";
    },
  },
];

runDAG(dag).then((results) => console.log(results["combined-report"]));
```

## Loop Guard Patterns

### Guard 1: Re-entrancy Prevention
Prevent a loop from launching a second instance of itself.

```bash
LOCKFILE="/tmp/ecc-loop-$(basename $0).lock"

if [ -f "$LOCKFILE" ]; then
  echo "Loop already running (PID $(cat $LOCKFILE)) — exiting."
  exit 1
fi

echo $$ > "$LOCKFILE"
trap "rm -f $LOCKFILE" EXIT
```

### Guard 2: Observer Loop Prevention
An observer watching for changes must not trigger itself.

```typescript
// Track what the loop itself writes so it doesn't re-trigger
const loopWrittenFiles = new Set<string>();

function onFileChange(path: string): void {
  if (loopWrittenFiles.has(path)) {
    loopWrittenFiles.delete(path); // consume the guard
    return; // skip — this change was ours
  }
  // process external change
}
```

### Guard 3: 5-Layer Guard (production hardened)

```typescript
const guard = {
  maxRounds: 10,               // Layer 1: absolute iteration cap
  maxWallSeconds: 300,         // Layer 2: wall-clock timeout
  idempotencyKey: uuid(),      // Layer 3: unique run ID, stored externally
  lastOutputHash: "",          // Layer 4: detect no-progress (output didn't change)
  externalStopFlag: false,     // Layer 5: check a stop-file each round
};

async function guardedLoop(): Promise<void> {
  const startTime = Date.now();

  for (let round = 0; round < guard.maxRounds; round++) {
    // Layer 2
    if ((Date.now() - startTime) / 1000 > guard.maxWallSeconds) {
      console.warn("Wall-clock timeout — stopping loop.");
      break;
    }

    // Layer 5
    if (fs.existsSync("/tmp/ecc-loop-stop")) {
      console.log("Stop flag detected — halting.");
      fs.unlinkSync("/tmp/ecc-loop-stop");
      break;
    }

    const output = await doWork();

    // Layer 4
    const hash = sha256(output);
    if (hash === guard.lastOutputHash) {
      console.log("No progress detected — loop terminating.");
      break;
    }
    guard.lastOutputHash = hash;

    if (isDone(output)) break;
  }
}
```

## Loop State Management

Store loop state externally so it survives restarts.

```yaml
# /tmp/ecc-loop-state-<run-id>.yaml
run_id: loop-1713524800
started: 2026-04-19T08:00:00Z
round: 3
max_rounds: 10
last_sha: abc123
status: running     # running | paused | done | failed
context_summary: "2 tests still failing after round 3"
```

```bash
# Read state
STATE=$(cat /tmp/ecc-loop-state-$RUN_ID.yaml)
ROUND=$(echo "$STATE" | grep "round:" | awk '{print $2}')

# Update state
sed -i "s/round: $ROUND/round: $((ROUND + 1))/" /tmp/ecc-loop-state-$RUN_ID.yaml
```

## Failure Handling and Recovery

| Failure Type | Response |
|--------------|----------|
| Agent timeout | Retry once, then skip stage and log |
| Exit condition never met | Log last output, stop at max rounds |
| External API error | Exponential backoff, max 3 retries |
| Bad output format | Validate before passing to next stage, request retry |
| Loop state file missing | Restart from round 0, warn Ahmed |
| Deadlock detected | Stop immediately, report stuck node |

```bash
# Retry with exponential backoff
retry() {
  local n=0
  local max=3
  local delay=2
  while [ $n -lt $max ]; do
    "$@" && return 0
    n=$((n + 1))
    echo "Retry $n/$max — waiting ${delay}s"
    sleep $delay
    delay=$((delay * 2))
  done
  echo "All retries exhausted."
  return 1
}

retry npx ecc-agentshield scan --workspace .
```

## How to Stop a Runaway Loop

### Immediate stop (from terminal)
```bash
# Write the stop flag
touch /tmp/ecc-loop-stop

# Or kill by PID from the lock file
kill $(cat /tmp/ecc-loop-*.lock)
```

### From another agent or hook
```bash
# Any agent can drop the stop flag — the loop checks it each round
echo "stop" > /tmp/ecc-loop-stop
```

### Emergency: kill all loop processes
```bash
pkill -f "ecc-loop" || true
rm -f /tmp/ecc-loop-*.lock /tmp/ecc-loop-stop
```

## Commands

### `/loop-start <pattern> [--max-rounds N] [--timeout Xs]`
Start a named loop pattern.

```bash
# Start a test-fix sequential pipeline, max 8 rounds, 5-minute timeout
/loop-start sequential-pipeline --max-rounds 8 --timeout 300s

# Start PR review loop for PR #42
/loop-start pr-review --pr 42 --max-rounds 10
```

### `/loop-status [run-id]`
Check the status of running or recent loops.

```bash
# Check all loops
ls /tmp/ecc-loop-state-*.yaml | xargs -I{} sh -c 'echo "---"; cat {}'

# Check specific run
cat /tmp/ecc-loop-state-$RUN_ID.yaml
```

Output:
```
run_id: loop-1713524800
pattern: sequential-pipeline
round: 3 / 8
status: running
last_action: "Fixed 2 test failures in auth.test.ts"
elapsed: 142s / 300s
```

## Anti-Patterns

- **Infinite loops with no exit condition** — always define what "done" means before starting.
- **Loops that modify their own guard config** — guard values are immutable once the loop starts.
- **Passing full file contents between every round** — summarize context; do not grow the payload each pass.
- **Spawning a new agent inside a loop without checking if one is already running** — use the lockfile guard.
- **Loops that silently swallow errors** — every failed round must be logged with its reason.
- **Using loops as a substitute for a deterministic solution** — if a single-shot approach works, use it.

## Safe Behavior

- All loops require an explicit exit condition or max-round cap — no uncapped loops.
- Loops writing to the filesystem check the stop flag every round.
- A loop may not modify `rules/`, `settings.json`, or any agent/skill file — those changes require Ahmed's approval even if the loop found the need.
- Loop state files are written to `/tmp/` — never committed.
- If a loop runs past 80% of its max rounds without converging, it logs a warning and alerts Ahmed.
- Runaway loop detection: if output hash has not changed in 2 consecutive rounds, the loop stops.
