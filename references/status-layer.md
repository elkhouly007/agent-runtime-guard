# Status Layer

## Goal

Provide a clear, up-to-date view of enabled packs, wiring readiness, verification health, and progress toward full-power completion.

## Current Status Signals

- audit status;
- registry status;
- smoke-test status;
- scenario file status;
- integration smoke status;
- payload protection status.

## Capability Pack Status

| Pack | Registry | Candidates | Class Coverage |
|---|---|---|---|
| MCP | present | filesystem-local, git-local, session-observer-local, github-reviewed, browser-reviewed | local + external |
| Wrappers | present | task-router-local, git-review-local, checkpoint-local, model-route-local, orchestrate-local, trusted-agent-reviewed | local + external |
| Plugins | present | changed-files-local, local-review-helper, quality-gate-local, git-summary-local, docs-fetch-reviewed, issue-sync-reviewed | local + external-read + external-write |
| Browser | present | read-only candidates, approval-gated write candidates | read + write-gated |
| Notifications | present | local-only candidates, external-reviewed candidates | local + external-reviewed |

## Tool Wiring Readiness

| Tool | Wiring Plan | Policy Map | Apply Checklist | Compatibility Strategy | Examples |
|---|---|---|---|---|---|
| OpenClaw | present | present | present | present | present |
| OpenCode | present | present | present | present | present |
| Claude Code | present | present | present | present | present |

## Verification Health

| Check | Status |
|---|---|
| audit-local | ok |
| check-registries | ok |
| smoke-test | ok |
| check-scenarios | ok |
| check-integration-smoke | ok |
| test-payload-protection | ok |

## Payload Protection Layer

| Component | Status |
|---|---|
| classify-payload.sh | present |
| redact-payload.sh | present |
| review-payload.sh | present |
| payload-classification.md | present |
| payload-redaction.md | present |

## Upstream Workflow

| Component | Status |
|---|---|
| upstream-sync.md | present |
| vendor-policy.md | present |
| import-checklist.md | present |
| import-report-template.md | present |
| import-report.sh | present |

## Scenario Coverage

| File | Scenarios |
|---|---|
| approval-boundary-scenarios.md | 20 scenarios |
| prompt-injection-scenarios.md | 14 scenarios |
| integration-smoke-cases.md | covers all 3 tools + packs + payload + upstream |

## Remaining Gaps

- More high-value upstream runtime features could still be imported or rebuilt.
- Payload detection could be deepened beyond current heuristic classification.
- Optional daemon/service pack not yet built.
- Status summary could be extended to show per-pack enabled state at runtime.

## Recommended Future Output

- per-pack enabled/disabled runtime state;
- import log showing last upstream review date;
- per-tool apply status (applied vs template-only);
- richer observability for live sessions.
