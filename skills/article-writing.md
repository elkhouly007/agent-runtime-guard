# Skill: article-writing

## Purpose

Write technical blog posts, developer documentation, or explainer articles — structured, clear, and accurate.

## Trigger

- Writing a technical blog post or tutorial
- Creating a "how we built it" article for a feature or system
- Asked to explain a concept, architecture, or decision in article form

## Trigger

`/article-writing [topic]` or `write an article about [topic]`

## Steps

1. **Define the article**
   - Topic and angle (tutorial, explainer, case study, opinion)
   - Target audience (beginner, intermediate, expert)
   - Intended publication (internal docs, dev blog, Medium, company blog)
   - Target length (short: ~500w, medium: ~1500w, long: ~3000w)

2. **Outline first**
   ```
   Title
   Hook (why this matters)
   Background (what readers need to know)
   Main content (2–5 sections)
   Code examples (if applicable)
   Conclusion / takeaways
   Call to action (optional)
   ```

3. **Write with these principles**

   - **Lead with the point** — tell readers what they'll learn in the first paragraph.
   - **Show, don't tell** — use code examples for technical content; diagrams for architecture.
   - **One idea per section** — clear H2/H3 headings that summarize the section.
   - **Short paragraphs** — 3–5 lines max; one idea per paragraph.
   - **Active voice** — "we built X" not "X was built by us".
   - **Concrete over abstract** — specific examples beat vague generalities.

4. **Code examples**
   - Every code block must be correct and runnable.
   - Show the bad pattern first if illustrating an anti-pattern, then the good one.
   - Keep examples minimal — strip boilerplate to the essential point.

5. **Review checklist**
   - [ ] Title is specific and searchable.
   - [ ] First paragraph answers "why should I read this?"
   - [ ] All technical claims are accurate.
   - [ ] Code examples are correct.
   - [ ] No unexplained jargon for the target audience.
   - [ ] Conclusion summarizes key takeaways.

## Output Format

Markdown, ready to publish. Use:
- `#` for title, `##` for sections, `###` for subsections.
- Fenced code blocks with language tags.
- Bold for key terms on first use.

## Safe Behavior

- Does not publish anywhere — produces a draft for review.
- Technical claims must be verifiable — if uncertain, flag it explicitly rather than stating it as fact.
