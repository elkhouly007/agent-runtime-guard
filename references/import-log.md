# Upstream Import Log

Records which upstream features (from `affaan-m/everything-claude-code`) were adopted, adapted, or rejected, and when. Use this to avoid duplicate import work and to understand divergence from upstream.

Upstream reference: `affaan-m/everything-claude-code` v1.10.0

---

## Format

Each entry:
```
### [component-name] — ADOPTED | ADAPTED | REJECTED
- **Date:** YYYY-MM-DD
- **Upstream path:** path/in/upstream/repo
- **Our path:** path/in/ecc-safe-plus/ (or N/A if rejected)
- **Decision:** Why adopted as-is, or what was changed, or why rejected.
```

---

## Agents

### code-reviewer — ADOPTED
- **Date:** 2026-04-16
- **Upstream path:** agents/code-reviewer.md
- **Our path:** agents/code-reviewer.md
- **Decision:** Adopted as-is. Upstream version was complete and aligned with our security requirements.

### security-reviewer — ADOPTED
- **Date:** 2026-04-16
- **Upstream path:** agents/security-reviewer.md
- **Our path:** agents/security-reviewer.md

### architect — ADOPTED
- **Date:** 2026-04-16
- **Upstream path:** agents/architect.md
- **Our path:** agents/architect.md

### comment-analyzer — ADDED (ours, not in upstream)
- **Date:** 2026-04-16
- **Upstream path:** N/A
- **Our path:** agents/comment-analyzer.md
- **Decision:** Custom addition for analyzing code comment quality and documentation patterns.

### conversation-analyzer — ADDED (ours, not in upstream)
- **Date:** 2026-04-16
- **Our path:** agents/conversation-analyzer.md
- **Decision:** Custom addition for analyzing multi-turn conversation structure and quality.

### healthcare-reviewer — ADDED (ours, not in upstream)
- **Date:** 2026-04-16
- **Our path:** agents/healthcare-reviewer.md
- **Decision:** Domain-specific addition for healthcare/HIPAA-compliant code review.

### gan-planner / gan-generator / gan-evaluator — ADDED (ours, not in upstream)
- **Date:** 2026-04-16
- **Our path:** agents/gan-*.md
- **Decision:** ML-specific agents for GAN development workflows.

---

## Rules

### common/coding-style — ADAPTED
- **Date:** 2026-04-16
- **Decision:** Adopted upstream base, added ECC-specific patterns.

### common/agents — ADDED (ours, not in upstream)
- **Date:** 2026-04-17
- **Our path:** rules/common/agents.md
- **Decision:** New rule set for writing well-formed agents. No upstream equivalent.

### web/security — ADDED (ours, not in upstream)
- **Date:** 2026-04-17
- **Our path:** rules/web/security.md
- **Decision:** Frontend security rules (XSS, CSP, CSRF) — not covered in upstream.

### web/testing — ADDED (ours, not in upstream)
- **Date:** 2026-04-17
- **Our path:** rules/web/testing.md
- **Decision:** Playwright, Vitest, jsdom testing rules — not in upstream.

### cpp/testing — ADDED (ours, not in upstream)
- **Date:** 2026-04-17
- **Our path:** rules/cpp/testing.md
- **Decision:** GoogleTest/Catch2 testing rules — upstream had cpp/coding-style and cpp/security but no testing.

---

## Skills

### configure-ecc — ADDED (ours, not in upstream)
- **Date:** 2026-04-17
- **Our path:** skills/configure-ecc.md
- **Decision:** Setup wizard skill — useful for onboarding new environments. No upstream equivalent.

### multi-agent-orchestration — ADDED (ours, not in upstream)
- **Date:** 2026-04-17
- **Our path:** skills/multi-agent-orchestration.md
- **Decision:** Formalized /multi-plan + /multi-execute patterns. Upstream has orchestrate skill but less structured.

### git-worktree-patterns — ADDED (ours, not in upstream)
- **Date:** 2026-04-17
- **Our path:** skills/git-worktree-patterns.md
- **Decision:** Cascade method for parallel development. Not in upstream.

### pm2-patterns — ADDED (ours, not in upstream)
- **Date:** 2026-04-17
- **Our path:** skills/pm2-patterns.md
- **Decision:** PM2 production process management. Not in upstream.

### investor-outreach — ADDED (ours, extends upstream)
- **Date:** 2026-04-17
- **Our path:** skills/investor-outreach.md
- **Decision:** Upstream has investor-materials; we added outreach/follow-up sequences as a complement.

### content-engine — ADDED (ours, extends upstream)
- **Date:** 2026-04-17
- **Our path:** skills/content-engine.md
- **Decision:** Systematic multi-channel content pipeline. Complements upstream article-writing skill.

---

## Infrastructure / Policy

### payload-protection pipeline — ADDED (ours, not in upstream)
- **Date:** 2026-04-16
- **Decision:** Classify/redact/review pipeline before external sends. ECC-specific safety requirement.

### phase1/2/3 policy layers — ADDED (ours, not in upstream)
- **Date:** 2026-04-16
- **Decision:** Graduated trust model for tool operations. ECC-specific governance layer.

### approval-boundary scenarios (20) — ADDED (ours)
- **Date:** 2026-04-16
- **Decision:** Scenario test suite for verifying approval policy. Not in upstream.

### prompt-injection scenarios (14) — ADDED (ours)
- **Date:** 2026-04-16
- **Decision:** Injection resistance test suite. Not in upstream.
