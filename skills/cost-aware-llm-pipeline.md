# Skill: cost-aware-llm-pipeline

## Purpose

Design and optimize LLM pipelines to minimize token costs without sacrificing output quality — model routing, prompt caching, context trimming, and batch strategies.

## Trigger

- Building a production LLM pipeline where API costs matter
- A pipeline is working but costs too much to scale
- Asked about model selection, prompt caching, or context window usage

## Trigger

`/cost-aware-llm-pipeline` or `optimize llm pipeline costs for [task]`

## Agents

- `architect` — pipeline design
- `performance-optimizer` — latency and throughput

## Model Routing Strategy

Match model to task complexity — not every call needs the most capable model:

| Task | Recommended Model | Why |
|------|------------------|-----|
| Classification, routing, extraction | Haiku 4.5 | Fast, cheap, sufficient |
| Code generation, reasoning, drafting | Sonnet 4.6 | Balanced cost/quality |
| Complex multi-step reasoning, architecture | Opus 4.6 | Best quality, use sparingly |
| Simple templated responses | Haiku 4.5 | Overkill to use Sonnet |

Route at the application layer — check task type before every LLM call.

## Prompt Caching (Anthropic SDK)

```python
import anthropic

client = anthropic.Anthropic()

response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    system=[
        {
            "type": "text",
            "text": long_static_system_prompt,
            "cache_control": {"type": "ephemeral"},  # cache this prefix
        }
    ],
    messages=[{"role": "user", "content": user_message}],
)
```

- Cache static content: system prompts, large reference documents, few-shot examples.
- Cache TTL is 5 minutes — design pipelines so repeated calls hit the cache within that window.
- Check `response.usage.cache_read_input_tokens` to verify cache hits.
- Cost savings: cached tokens are ~90% cheaper than uncached on Claude.

## Context Trimming

- Never send the full conversation history when only recent turns matter — truncate to a sliding window.
- Summarize old turns rather than dropping them: `"Previous context summary: ..."` as a system message.
- Remove redundant tool results from context once their data is incorporated.
- Measure `input_tokens` per call — alert if it exceeds a threshold.

## Batching

```python
# Process multiple independent items in parallel
import asyncio

async def process_batch(items: list[str]) -> list[str]:
    return await asyncio.gather(*[call_llm(item) for item in items])
```

- Batch independent items with `asyncio.gather` or thread pools — do not call LLM serially for independent work.
- Use the Anthropic Batch API for large offline workloads (>100 items) — 50% cost reduction.

## Streaming for UX

```python
with client.messages.stream(model="claude-sonnet-4-6", max_tokens=1024, messages=messages) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

- Stream for user-facing responses — improves perceived latency significantly.
- Do not stream for batch/background processing — adds overhead.

## Cost Monitoring

- Log `input_tokens`, `output_tokens`, `cache_read_input_tokens` per call.
- Set per-user or per-session token budgets and enforce them.
- Track cost trends over time — a regression in prompt size compounds at scale.

## Safe Behavior

- This skill recommends patterns — does not make API calls itself.
- Model routing decisions that change behavior require explicit confirmation.
