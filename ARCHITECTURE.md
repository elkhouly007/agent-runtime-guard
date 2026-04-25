# Architecture — Agent Runtime Guard

## 1. Runtime Module Map

```
runtime/
├── decision-engine.js      Entry point. Walks the Section 3 precedence matrix and returns a decision.
├── risk-score.js           12 pattern classes, bounded 0–10, deterministic. No I/O.
├── decision-key.js         fineKey (5-part) + legacyKey (4-part back-compat). Classifies commands.
├── policy-store.js         Learned-allow, auto-allow-once, approval counts. Atomic tmp+rename writes.
├── session-context.js      Per-session risk tracking. Session-id partitioning. Atomic writes.
├── decision-journal.js     JSONL append-only log with 5 MB rotation, 3-generation retention.
├── project-policy.js       Reads ecc.config.json; falls back to defaults; validates via config-validator.
├── context-discovery.js    Git branch + project markers discovery. Git calls time-bounded at 1500 ms.
├── promotion-guidance.js   6-stage promotion lifecycle. Deterministic.
├── workflow-router.js      Recommends CI, PR, or review workflow based on action + risk.
├── action-planner.js       Builds a step-by-step action plan for the decided action.
├── pretool-gate.js         Single enforcement spine called by all three harness adapters.
├── secret-scan.js          Cross-harness secret pattern scanner (was Claude-only before v1.7).
├── contract.js             Contract lifecycle: load, verify, accept, generate, scopeMatch.
├── glob-match.js           Zero-dep glob matcher (**/*/?/[abc]/! negation/${projectRoot}).
├── arg-extractor.js        Argv splitter. Quoted args, escapes, heredocs → <<HEREDOC (fail-closed).
├── canonical-json.js       Deterministic JSON stringify (keys sorted) for contract hashing.
├── config-validator.js     Typed-field walker. Validates ecc.config.json and ecc.contract.json.
├── state-paths.js          Single source of truth for all storage paths. ECC_STATE_DIR override.
└── telemetry.js            Structured telemetry events to telemetry.jsonl. Never blocks.
```

Adapters (thin, ~30–70 lines each):
```
claude/hooks/dangerous-command-gate.js   → runPreToolGate({ harness:"claude", ... })
openclaw/hooks/adapter.js                → runPreToolGate({ harness:"openclaw", ... })
opencode/hooks/adapter.js                → runPreToolGate({ harness:"opencode", ... })
```

## 2. Decision Flow — Section 4.6 Precedence Matrix

Every `decide()` call walks this fixed ladder. Each rung can only make things more restrictive, except step 11 (contract-allow), which is the single demotion rung and cannot override a floor set above it.

```
Step  Rung                                  Can demote?  Can promote?  Floor-bound?
──────────────────────────────────────────────────────────────────────────────────
1     kill-switch (ECC_KILL_SWITCH=1)        no           to block      yes (F1)
2     contract-hash-mismatch (strict mode)   no           to block      yes (F2)
3     critical-risk (score === 10)           no           to block      yes (F3)
4     secret-class-C payload                 no           to block      yes (F4)
5     strict-mode + gated class + no cover   no           to block      yes (F5)
6     scope-violation                        no           to escalate   yes (F6)
7     novel-command-class                    no           to escalate   yes (F7)
8     protected-branch-write                 no           to review     yes (F8)
9     session-risk >= 3                      no           to escalate   yes (F9)
10    risk scoring                           no           establishes baseline action
11    contract scope-allow                   YES          no            demotes baseline only
                                                                        (source=contract-allow)
12    learned-allow                          YES (narrow) no            destructive-delete only;
                                                                        cannot demote floors
13    auto-allow-once                        YES (narrow) no            same constraints; consumed
                                                                        only when actually needed
14    trajectory nudge                       no           +1 step       exempts contract-allow +
                                                                        learned-allow sources
15    emit + journal                         —            —             —
```

**Demotion rules:**
- Floors (steps 1–9) always win. No rung below can change a floor-set action.
- `contract-allow` demotes baseline only. Never demotes a floor.
- `learned-allow` and `auto-allow-once` cannot demote anything a contract-allow would not have.
- Trajectory nudge is a promoter only. Exempt for `contract-allow` and `learned-allow` sources.
- `auto-allow-once` is consumed only when it actually changes the outcome.

## 3. Contract Specification

See [CONTRACT.md](CONTRACT.md) for full field reference.

Key flow:
1. `ecc-cli.sh contract init` — writes `ecc.contract.json.draft`
2. Human reviews and edits the draft
3. `ecc-cli.sh contract accept` — hashes, writes final `ecc.contract.json`, records in `~/.openclaw/agent-runtime-guard/accepted-contracts.json`
4. Every `decide()` recomputes the hash and verifies against the accepted record

Self-accept guard: `contract accept` refuses when harness session environment variables are detected (`CLAUDE_CODE_SESSION_ID`, etc.).

## 4. Storage Layout

All paths go through `runtime/state-paths.js`. Override with `ECC_STATE_DIR`.

```
~/.openclaw/agent-runtime-guard/
├── decision-journal.jsonl          Append-only decision log
├── decision-journal.1.jsonl        Rotation generation 1 (most recent overflow)
├── decision-journal.2.jsonl.gz     Rotation generation 2
├── decision-journal.3.jsonl.gz     Rotation generation 3
├── session-context.json            Per-session risk + trajectory state
├── current-session-id              16-hex session ID written at SessionStart
├── policy.json                     Learned-allow, approvals, auto-allow-once grants
├── accepted-contracts.json         { <projectRootAbs>: { contractHash, acceptedAt, revision } }
└── telemetry.jsonl                 Structured telemetry events (never blocks decisions)

<projectRoot>/
├── ecc.contract.json               Accepted contract for this project
├── ecc.contract.json.draft         Draft (output of `contract init` / `contract amend`)
└── ecc.config.json                 Per-project config (validated against schemas/ecc.config.schema.json)

artifacts/bench/
└── baseline.json                   p50/p95/p99 per platform; used for 1.5× regression check
```

## 5. Environment Variable Catalog

| Variable | Default | Effect |
|---|---|---|
| `ECC_KILL_SWITCH` | `0` | `1` = PreToolUse hooks exit 2 (block all tool calls unconditionally); informational hooks (PostToolUse/SessionStart/Stop) pass stdin through unchanged |
| `ECC_ENFORCE` | `0` | `1` = hooks exit 2 on block (enforcement mode for adapters) |
| `ECC_CONTRACT_ENABLED` | `1` | `0` = skip contract loading entirely (opt-out) |
| `ECC_CONTRACT_REQUIRED` | `0` | `1` = gated capability classes blocked without valid accepted contract |
| `ECC_READONLY_CONTRACT` | `0` | `1` = decisions proceed but zero writes to policy/session/journal (CI/review mode) |
| `ECC_STATE_DIR` | `~/.openclaw/agent-runtime-guard` | Override storage directory |
| `ECC_TRAJECTORY_THRESHOLD` | `3` | Escalation count triggering trajectory nudge |
| `ECC_TRAJECTORY_WINDOW_MIN` | `30` | Lookback window in minutes for trajectory nudge |
| `ECC_JOURNAL_MAX_MB` | `5` | Rotate decision journal when it exceeds this size |
| `ECC_BENCH_P99_MS` | platform-auto | Override bench p99 ceiling (ms) |
| `ECC_DECISION_JOURNAL` | `1` | `0` = disable journal writes |

## 6. Harness Adapter Contract

Each adapter must:
1. Read all stdin before exiting (prevents broken-pipe in the harness).
2. Echo raw stdin to stdout **unchanged**.
3. Write human-readable notices to stderr only.
4. Exit 0 to allow the action; exit 2 to block (when `ECC_ENFORCE=1` and decision is block/escalate/require-review).
5. Never modify the JSON passed to the model.

`runtime/pretool-gate.js` implements steps 3–5 for all harnesses. Adapters provide only the harness-specific stdin parsing.

## 7. Zero-Dependency Policy

`runtime/*.js` imports only:
- Node builtins: `node:fs`, `node:path`, `node:crypto`, `node:os`, `node:zlib`
- Local `./` requires within `runtime/`

CI enforces this via `scripts/check-zero-deps.sh`. Any PR adding a third-party `require()` in `runtime/` fails CI immediately.
