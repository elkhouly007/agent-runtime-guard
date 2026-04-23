# Skill: Model Route

## Trigger

Use when selecting the right Claude model for a task, routing different task types to the most cost-effective model, or optimizing a multi-step pipeline where different steps have different complexity requirements.

## Model Tiers

| Model | ID | Characteristics | Use when |
|---|---|---|---|
| **Opus 4.6** | `claude-opus-4-6` | Highest reasoning, slowest, most expensive | Architecture decisions, complex debugging, multi-step planning, ambiguous requirements |
| **Sonnet 4.6** | `claude-sonnet-4-6` | Balanced — best default | Code review, implementation, analysis, most engineering tasks |
| **Haiku 4.5** | `claude-haiku-4-5-20251001` | Fastest, cheapest | Classification, extraction, formatting, summarization, routing decisions |

Cost ratio (approximate): Opus ~5×, Sonnet 1×, Haiku ~0.1×

## Routing Decision Tree

```
Is the task:
  → Purely mechanical? (classify, extract, reformat, summarize with given structure)
    → Haiku

  → Creative or complex? (write, analyze, debug, review, plan)
    Is it:
      → Single-domain, well-defined? (review this function, explain this error)
        → Sonnet

      → Multi-step, ambiguous, or architectural?
        (design system, debug intermittent race condition, review entire PR with cross-cutting concerns)
        → Opus
```

## Task Type → Model Mapping

### Use Haiku

- **Classification:** "Is this a bug report or a feature request?"
- **Extraction:** "Extract all function names from this file."
- **Reformatting:** "Convert this JSON to YAML."
- **Summarization with template:** "Summarize this PR in 3 bullet points using this format: [...]"
- **Routing:** "Which agent should handle this task?"
- **Validation:** "Does this JSON match this schema? Yes/No."
- **Simple transformation:** "Convert camelCase keys to snake_case."

### Use Sonnet (default)

- Code review (single file or module)
- Implementing a well-specified feature
- Debugging a clear error with a stack trace
- Writing tests for existing code
- Documenting an existing function or module
- Explaining what a piece of code does
- Security review of a known code surface
- Most agent tasks

### Use Opus

- Designing system architecture for a new feature
- Debugging an intermittent or non-deterministic failure
- Reviewing a large PR with cross-cutting concerns
- Writing a technical spec or ADR with trade-off analysis
- Complex refactoring where intent must be inferred
- Tasks where Sonnet has already failed or produced weak output

## Multi-Model Pipeline Pattern

```python
# Route different steps to appropriate models
import anthropic

client = anthropic.Anthropic()

def pipeline(user_request: str):
    # Step 1: Haiku classifies and extracts key info (cheap)
    classification = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=200,
        system="Classify this request: return JSON {type, language, complexity}",
        messages=[{"role": "user", "content": user_request}]
    )
    info = parse_json(classification.content[0].text)

    # Step 2: Route based on classification
    if info["complexity"] == "high":
        model = "claude-opus-4-6"
    elif info["type"] in ["review", "implement", "debug"]:
        model = "claude-sonnet-4-6"
    else:
        model = "claude-haiku-4-5-20251001"

    # Step 3: Run main task with routed model
    result = client.messages.create(
        model=model,
        max_tokens=4096,
        messages=[{"role": "user", "content": user_request}]
    )
    return result.content[0].text
```

## Cost Optimization Rules

1. **Classify before acting** — use Haiku to determine task type, then route.
2. **Fail fast to Sonnet** — start with Sonnet; escalate to Opus only if Sonnet output is insufficient.
3. **Cache the system prompt** — use prompt caching for any context repeated across calls.
4. **Batch small tasks** — combine multiple Haiku-level tasks into one call to reduce per-call overhead.
5. **Max tokens discipline** — set `max_tokens` to the realistic maximum for the task; don't default to 4096 everywhere.

## Output Format

When making a routing recommendation:
- State the recommended model and why.
- If a pipeline is involved: list each step, its model, and the rationale.
- Include cost estimate if the difference is significant (e.g., Opus vs Haiku for a 10K-call/day workload).

## Constraints

- Never downgrade model selection to save cost on high-stakes decisions (security review, production incidents, architectural choices).
- Never use Haiku for tasks requiring nuanced judgment or creative synthesis.
- Model IDs should be treated as current defaults — check Anthropic's model documentation for the latest versions before hardcoding in production systems.
