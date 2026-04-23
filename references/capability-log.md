# ARG Capability Log

Tracks the growth of Agent Runtime Guard's capability surface over time.
Each entry records what was added, why, and what it enables.

---

## v1.0.0 — 2026-04-23

### Runtime Layer (original)
- `runtime/decision-engine.js` — kill-switch → learned-allow → auto-allow-once → trajectory-nudge decision chain
- `runtime/policy-store.js` — persistent allow/block policies with session and permanent scope
- `runtime/session-context.js` — per-session trajectory tracking and env override support
- `runtime/action-planner.js` — stack-aware action decomposition
- `runtime/workflow-router.js` — routes decisions based on primary stack and risk profile
- `runtime/project-policy.js` — per-project trust posture (strict/balanced/relaxed)
- `runtime/decision-journal.js` — append-only JSONL audit trail

### Hook Layer (original)
- `claude/hooks/dangerous-command-gate.js` — pre-execution command risk scoring, 21 dangerous patterns
- `claude/hooks/secret-warning.js` — 23 secret pattern detectors (tokens, keys, certs)
- `claude/hooks/hook-utils.js` — shared utilities: path sensitivity classifier, rate limiter, JSONL logger

### Agent Ecosystem (original, ARG amplification philosophy)
- 49 agents across: architecture, code review, security, testing, language specialists, build resolvers, open source, orchestration
- Each agent: Mission statement, ARG-aware Activation conditions, numbered Protocol, Amplification Techniques, measurable Done When

### Rule Set (original)
- 81 rules across 11 language directories + common directory
- Languages: Python, TypeScript, Go, Rust, Java, C++, Kotlin, C#, Dart, Swift, Perl, PHP
- Domains: database patterns, database security, infrastructure patterns, infrastructure security, web (coding-style, design-quality, hooks, patterns, performance, security, testing)

### Skill Set (original)
- 22 skills covering: ARG debug, policy tuning, learning review, capability audit, code analysis, amplification techniques, autonomous improvement, multi-agent debug, semantic refactor, test intelligence, deployment safety, context maximization, orchestration design, workflow acceleration, pattern extraction, plus 6 domain-specific skills

---

## Future Capability Targets

- Inter-agent trust protocol with cryptographic identity verification
- Adaptive risk scoring based on project-specific learned threat model
- Natural language prompt injection detection (ASI01 full coverage)
- Post-tool output sanitization hook (ASI05 full coverage)
- Agent performance metrics and automated improvement cycle
