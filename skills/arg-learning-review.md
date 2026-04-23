# Skill: arg-learning-review

---
name: arg-learning-review
description: Review what ARG has learned from past sessions — accumulated policies, trajectory history, and auto-allow patterns — to validate they reflect current intent
---

# ARG Learning Review

Audit the accumulated state ARG has learned to ensure it reflects current risk tolerance.

## When to Use

Use when you want to validate that ARG's accumulated learned policies still reflect your current risk tolerance — especially before a release, after a security incident, or as a quarterly hygiene check.

## What ARG Learns

1. **Learned-allow policies**: created when a user manually approves a blocked action and selects "always allow"
2. **Session trajectories**: escalation counts per session used to trigger trajectory nudges
3. **Auto-allow-once grants**: short-term single-use permits, should not persist

## Full State Audit

```bash
node -e "
  const {PolicyStore} = require('./runtime/policy-store');
  const ps = new PolicyStore();
  const all = ps.getAll();
  const learned = all.filter(p => p.createdBy === 'agent' || p.scope === 'session');
  console.log('Total policies:', all.length);
  console.log('Learned policies:', learned.length);
  console.log(JSON.stringify(learned, null, 2));
"
```

## Review Checklist

For each learned-allow policy:

- [ ] Is the command still in use in this project?
- [ ] Does the scope (session vs permanent) match the actual risk level?
- [ ] Was it created under a trajectory nudge (emergency approval) that should be re-evaluated?
- [ ] Does it match a pattern that has since become risky (e.g., new sensitive files added)?

## Cleanup Stale Policies

```bash
node -e "
  const {PolicyStore} = require('./runtime/policy-store');
  const ps = new PolicyStore();
  const cutoff = Date.now() - (30 * 24 * 60 * 60 * 1000); // 30 days
  const stale = ps.getAll().filter(p =>
    p.scope === 'session' || new Date(p.createdAt).getTime() < cutoff
  );
  console.log('Stale policies to review:', stale.length);
  stale.forEach((p, i) => console.log(i, p.pattern, p.decision, p.createdAt));
"
```

## When to Run

- Before a new release or deployment
- After a security incident
- Quarterly as part of a regular security review
- When onboarding a new contributor (they should understand the accumulated policy set)
