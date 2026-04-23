# Skill: Social Graph Ranker

## Trigger

Use when analyzing a professional network (LinkedIn connections, Twitter/X follows, email contacts) to identify which relationships to prioritize — for fundraising, hiring, partnerships, sales, or any goal that depends on warm introductions.

## Process

### Phase 1 — Define the Goal

Before ranking, specify:
- **Target:** what type of person do you need access to? (e.g., Series A VCs investing in B2B SaaS, senior engineers at FAANG, procurement at enterprise healthcare companies)
- **Desired outcome:** intro, meeting, referral, collaboration
- **Constraint:** geography, timeline, existing relationship strength required

### Phase 2 — Contact Inventory

Build a structured inventory of contacts:

```
Name | Company | Title | Relationship strength | Why relevant | Path to target
-----|---------|-------|----------------------|--------------|----------------
Ali S. | Sequoia | Partner | Strong (met 3x, warm) | Invests in our space | Direct approach
...
```

Relationship strength scale:
- **Strong:** regular communication, met in person, they know your work
- **Warm:** connected, interacted digitally, mutual context
- **Weak:** connected but dormant, no recent interaction
- **Cold:** connection exists but no real relationship

### Phase 3 — Graph Analysis

For each contact, score on:

| Factor | Weight | Scoring |
|---|---|---|
| **Proximity to target** | 40% | Do they know your target directly (1-hop) or through others (2-hop)? |
| **Relationship strength** | 30% | Strong/warm/weak/cold → 4/3/2/1 |
| **Willingness to intro** | 20% | Have they made intros before? Do they owe you a favor? |
| **Target overlap** | 10% | Do they work in the same sector/stage/geography as your target? |

Composite score = weighted average → rank contacts 1 to N.

### Phase 4 — Prioritized Action Plan

For top 10 contacts:
1. **Re-engagement actions** — contacts that are warm/weak need a touchpoint before the ask.
2. **Ask framing** — personalized to each relationship (what's in it for them to intro you?).
3. **Sequence** — who to approach in what order (don't burn your best connection first without a polished pitch).

## Output Format

```markdown
## Social Graph Ranking — [Goal]

### Top 10 Prioritized Contacts

| Rank | Name | Company | Strength | Score | Action |
|------|------|---------|----------|-------|--------|
| 1 | ... | ... | Strong | 0.92 | Direct ask — they know [Target] personally |
| 2 | ... | ... | Warm | 0.81 | Re-engage: share recent press, then ask |
| 3 | ... | ... | Weak | 0.64 | Reconnect first — comment on their post, then ask |

### Sequence Recommendation
[Ordered action plan: who, when, what to say]

### Gaps
[Who you need in your network but don't have — who could you meet to fill this gap?]
```

## Constraints

- Do not recommend cold-messaging someone as a "warm intro" — that misrepresents the relationship and damages trust.
- Do not rank based on perceived status alone — a mid-level person with a direct relationship to your target outranks a senior person with no connection.
- All contact data used must be voluntarily shared — do not scrape or use unauthorized data.
