# Skill: market-research

## Purpose

Research a market, competitive landscape, or technology space — summarize key players, trends, and positioning to inform product or technical decisions.

## Trigger

- Evaluating a technology choice (library, platform, provider)
- Researching competitors before a product decision
- Asked to summarize the landscape for a domain or tool category

## Trigger

`/market-research [topic]` or `research the [topic] market/landscape`

## Steps

1. **Define the research question**
   - What decision does this research inform?
   - What specific aspects to cover: players, pricing, features, trends, adoption?
   - What is the time horizon? (current state vs. 12-month outlook)

2. **Gather information**
   - Use `docs-lookup` or web search for current data.
   - Check: official sites, GitHub stars/activity, community forums, recent blog posts.
   - Avoid relying solely on training data for fast-moving spaces.

3. **Analyze across dimensions**

   | Dimension | Questions to answer |
   |-----------|-------------------|
   | Players | Who are the main options? Open-source vs. commercial? |
   | Differentiation | What makes each option unique? |
   | Adoption | GitHub stars, downloads, community size, enterprise users |
   | Maturity | Version, age, breaking-change frequency, LTS support |
   | Pricing | Free tier? Open-core? Usage-based? Enterprise lock-in? |
   | Ecosystem | Integrations, plugins, docs quality, support |
   | Trajectory | Growing, stable, or declining? Recent releases? |

4. **Produce a structured summary**

## Output Format

```markdown
## Market Research: [Topic]

**Date**: YYYY-MM-DD
**Decision context**: [what this informs]

### Landscape Overview
[2–3 sentence summary]

### Key Players

| Option | Type | Strengths | Weaknesses | Adoption |
|--------|------|-----------|------------|----------|
| ...    |      |           |            |          |

### Trends
- ...

### Recommendation
[Concise recommendation with rationale, or "needs further evaluation" with what's unclear]

### Sources
- ...
```

## Safe Behavior

- Research only — no purchasing, signing up, or contacting vendors.
- Flag when data is from training knowledge vs. fetched live — they have different freshness.
- Competitive assessments are snapshots; products change — note the date prominently.
