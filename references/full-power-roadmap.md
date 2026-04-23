# Full-Power Secure Roadmap

## Goal

Reach or exceed the practical power of the upstream toolkit while maintaining stronger security, clearer review boundaries, and better long-term control.

Success means:

- matching the useful capability of the upstream repo;
- exceeding it in safety, observability, and maintainability;
- keeping dangerous actions behind explicit approval;
- making upstream updates cheap to review instead of risky to install.

## Current State

Agent Runtime Guard already has:

- standing approval policy;
- prompt-injection rejection rules;
- Phase 1 policy for trusted agents, MCP, and shell;
- Phase 2 policy for plugins, browser automation, and notifications;
- Phase 3 policy for installers, wrappers, daemons, and integration templates;
- upstream sync, vendor policy, and import checklist.

Current rough power level versus upstream: around 65 percent practical power with stronger safety foundations.

## Target State

### Power Target

Reach 100 percent of the useful upstream capability, then go beyond it by adding:

- stronger payload review;
- better module classification;
- safer defaults;
- cleaner observability;
- safer update workflow;
- reusable integration packs.

### Security Target

Keep user approval required for:

- deletion;
- destructive overwrite of sensitive content;
- sending personal, confidential, or secret data externally;
- elevated privileges;
- permanent high-risk global configuration changes;
- unclear external data flow.

Everything else should be as automated as possible under reviewable policy.

## Capability Gap Map

### Already Covered Well

- policy model;
- security posture;
- trust boundaries;
- prompt-injection handling;
- shell approval classes;
- external payload review rules;
- upstream-safe adoption process.

### Partially Covered

- integration templates;
- plugin policy;
- browser policy;
- wrapper policy;
- daemon policy;
- installer policy.

### Not Yet Fully Realized

- real wired integrations for OpenClaw, OpenCode, and Claude Code;
- reviewed MCP adapter pack;
- reviewed plugin pack;
- browser task pack;
- wrapper command pack;
- daemon/service pack where useful;
- upstream import automation and change reports;
- test harness for policy enforcement;
- safe config generators for each target tool.

## Roadmap Phases

## Phase 4: Real Integration Wiring

Goal: convert templates into actual ready-to-apply integration packs.

Deliverables:

- OpenClaw integration pack;
- OpenCode integration pack;
- Claude Code integration pack;
- explicit target-path mapping;
- apply-preview workflow;
- rollback notes.

Definition of done:

- each integration is installable locally with visible file targets;
- risky modules remain disabled by default;
- audit passes after generation.

## Phase 5: Reviewed Capability Packs

Goal: rebuild the most useful runtime power from upstream in controlled modules.

Deliverables:

- reviewed local MCP pack;
- reviewed external MCP pack with payload review layer;
- reviewed plugin pack classified by risk;
- browser automation pack with read/write separation;
- wrapper pack for common helper flows;
- notification pack split into local and external modes.

Definition of done:

- each pack has documented data flow;
- each pack maps to approval policy;
- each pack can be enabled independently.

## Phase 6: Upstream Import Engine

Goal: make upstream updates cheap to inspect and safe to absorb.

Deliverables:

- upstream diff workflow;
- change classification script or checklist-driven helper;
- adoption log;
- vendor/import folder conventions;
- import report template.

Definition of done:

- new upstream changes can be reviewed by category quickly;
- safe changes can be adopted without raw install.

## Phase 7: Guardrail Enforcement Layer

Goal: move from policy text to enforceable checks where useful.

Deliverables:

- payload scrub helpers;
- policy lint checks for configs;
- hook validation rules;
- module manifest schema;
- sensitive-data outbound detector.

Definition of done:

- common unsafe patterns are caught automatically before apply.

## Phase 8: Test And Verification Layer

Goal: verify that safe-power behavior remains correct as the repo grows.

Deliverables:

- audit test set;
- policy scenario tests;
- prompt-injection test cases;
- sample external payload review tests;
- integration smoke tests.

Definition of done:

- changes to modules can be tested before adoption;
- regressions in safety policy are caught early.

## Phase 9: Beyond Upstream

Goal: exceed upstream value, not just match it.

Deliverables:

- better observability and logs;
- cleaner per-tool config generation;
- safer selective auto-wiring;
- richer module manifests;
- optional dashboard or status summary for enabled capabilities.

Definition of done:

- Agent Runtime Guard becomes easier to trust, easier to update, and easier to operate than upstream.

## Execution Priorities

### Highest priority next

1. OpenClaw integration wiring
2. Reviewed MCP pack
3. Wrapper pack
4. Plugin pack
5. Browser pack

### Medium priority

6. Upstream import engine
7. Guardrail enforcement helpers
8. Integration smoke tests

### Later

9. Daemon/service pack where clearly useful
10. Advanced observability and status tooling

## Risk Controls

For every new feature added:

1. classify it;
2. document data flow;
3. decide approval boundary;
4. build local-first if possible;
5. add audit coverage;
6. verify before enable.

## Recommended Build Strategy

Do not chase total parity in one jump.

Use this order:

- wire the current safe base into real tools;
- add the highest-value runtime packs;
- add import automation;
- add enforcement and testing;
- then optimize and go beyond upstream.

## Practical Milestone Targets

- 75 percent power: real OpenClaw and OpenCode wiring plus first MCP and wrapper packs.
- 85 percent power: reviewed plugin and browser packs plus safe import workflow.
- 95 percent power: enforcement helpers and test harness active.
- 100 percent plus: easier updates, better observability, safer defaults, and richer integration than upstream.
