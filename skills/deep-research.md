# Skill: Deep Research

## Trigger

Use when a question requires synthesizing information from multiple sources — competitive analysis, technical landscape surveys, academic topic exploration, market sizing, or any research task where surface-level answers are insufficient.

## Process

### Phase 1 — Frame the Question

Before searching, clarify:
1. **Core question:** what specific answer do we need?
2. **Depth required:** overview vs. comprehensive vs. exhaustive
3. **Source types:** documentation, papers, news, forums, official specs
4. **Timeframe:** current state only, or historical context needed?
5. **Output format:** summary, comparison table, decision memo, full report

Badly framed questions produce shallow answers — spend 2 minutes framing before searching.

### Phase 2 — Multi-Source Research

Research across at least 3 independent source types to avoid single-source bias:

| Source type | Best for |
|---|---|
| Official documentation | Accurate technical specs, APIs, feature lists |
| Academic papers / arXiv | Methodology, benchmarks, rigorous comparisons |
| GitHub repos + issues | Real-world usage, known bugs, community sentiment |
| Industry blogs / engineering posts | Practical trade-offs, production experience |
| Forums (HN, Reddit, Stack Overflow) | Community opinion, gotchas, common mistakes |
| News and announcements | Timelines, vendor direction, competitive moves |

### Phase 3 — Synthesis

Structure findings before writing:
1. Cluster sources by position/finding — group agreement and disagreement.
2. Identify contradictions — note where sources disagree and why.
3. Weigh sources by authority — peer-reviewed > well-known practitioner > anonymous forum post.
4. Fill gaps — note what you couldn't find and what that implies.

### Phase 4 — Output

Every research output must include:
- **Executive summary** — 3-5 bullets, the most important findings
- **Source attribution** — every claim tied to a source
- **Confidence levels** — indicate where evidence is strong vs. thin
- **Contradictions noted** — don't smooth over disagreements
- **Limitations** — what wasn't searched, what's uncertain

## Output Formats

### Quick Brief (1-2 pages)
- Summary paragraph
- Key findings (5-7 bullets with sources)
- Recommended next step

### Comparison Table
```markdown
| Dimension | Option A | Option B | Option C |
|---|---|---|---|
| [criterion 1] | [finding] | [finding] | [finding] |
| Source | [cite] | [cite] | [cite] |
```

### Full Research Report
1. Executive summary (1 page)
2. Background / context
3. Key findings by theme
4. Comparison or analysis
5. Limitations
6. Sources / bibliography

## Source Attribution Format

Inline citation: "Postgres supports logical replication natively since v10 [PostgreSQL docs, 2023]."

Bibliography entry: `[Author/Org, Year] — Title — URL or reference`

## Quality Gates

Before delivering research:
- [ ] At least 3 independent sources per major claim
- [ ] Every key claim has a source citation
- [ ] Contradictory findings are explicitly noted, not resolved by picking one
- [ ] Confidence level stated for uncertain findings
- [ ] Limitations section present

## Constraints

- Never present a single-source finding as established fact — note it as preliminary.
- Do not fabricate sources or citations — only cite what was actually read.
- If a search found nothing substantive on a sub-question, say so explicitly rather than filling with speculation.
