# Skill: Claude API

## Trigger

Use when building applications with the Anthropic Claude API or SDK — sending messages, streaming responses, structuring tools/function calls, implementing prompt caching, managing conversation history, or integrating Claude into a backend service.

## Setup

```bash
# Python
pip install anthropic

# TypeScript/Node.js
npm install @anthropic-ai/sdk
```

```python
import anthropic
client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
```

```typescript
import Anthropic from '@anthropic-ai/sdk';
const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
```

Never hardcode the API key — use environment variables.

## Basic Message

```python
# Python
message = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Explain async/await in JavaScript in 3 sentences."}
    ]
)
print(message.content[0].text)
```

```typescript
// TypeScript
const message = await client.messages.create({
    model: 'claude-sonnet-4-6',
    max_tokens: 1024,
    messages: [
        { role: 'user', content: 'Explain async/await in JavaScript in 3 sentences.' }
    ],
});
console.log(message.content[0].text);
```

## System Prompt

```python
message = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=2048,
    system="You are a senior code reviewer. Be concise. Only flag issues that matter.",
    messages=[
        {"role": "user", "content": f"Review this code:\n\n{code}"}
    ]
)
```

## Streaming

```python
# Python — stream to avoid timeout on long responses
with client.messages.stream(
    model="claude-sonnet-4-6",
    max_tokens=4096,
    messages=[{"role": "user", "content": prompt}]
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

```typescript
// TypeScript
const stream = client.messages.stream({
    model: 'claude-sonnet-4-6',
    max_tokens: 4096,
    messages: [{ role: 'user', content: prompt }],
});

for await (const event of stream) {
    if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
        process.stdout.write(event.delta.text);
    }
}
const finalMessage = await stream.finalMessage();
```

## Multi-Turn Conversation

```python
history = []

def chat(user_message: str) -> str:
    history.append({"role": "user", "content": user_message})

    response = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        system="You are a helpful assistant.",
        messages=history
    )

    assistant_message = response.content[0].text
    history.append({"role": "assistant", "content": assistant_message})
    return assistant_message

# Usage
print(chat("What is the capital of France?"))
print(chat("What is its population?"))  # uses context from previous turn
```

## Tool Use (Function Calling)

```python
tools = [
    {
        "name": "get_weather",
        "description": "Get current weather for a city.",
        "input_schema": {
            "type": "object",
            "properties": {
                "city": {"type": "string", "description": "City name"},
                "unit": {"type": "string", "enum": ["celsius", "fahrenheit"]}
            },
            "required": ["city"]
        }
    }
]

response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    tools=tools,
    messages=[{"role": "user", "content": "What's the weather in Tokyo?"}]
)

# Check if Claude wants to call a tool
if response.stop_reason == "tool_use":
    tool_call = next(b for b in response.content if b.type == "tool_use")
    tool_name = tool_call.name          # "get_weather"
    tool_input = tool_call.input        # {"city": "Tokyo"}
    tool_use_id = tool_call.id

    # Execute the actual function
    result = get_weather(**tool_input)

    # Send result back to Claude
    follow_up = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=1024,
        tools=tools,
        messages=[
            {"role": "user", "content": "What's the weather in Tokyo?"},
            {"role": "assistant", "content": response.content},
            {
                "role": "user",
                "content": [{"type": "tool_result", "tool_use_id": tool_use_id, "content": str(result)}]
            }
        ]
    )
    print(follow_up.content[0].text)
```

## Prompt Caching (Cost Reduction)

Cache large, stable content (system prompts, documents) to cut cost by up to 90% on repeated calls:

```python
response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    system=[
        {
            "type": "text",
            "text": "You are an expert code reviewer.",
        },
        {
            "type": "text",
            "text": long_codebase_context,   # large stable context
            "cache_control": {"type": "ephemeral"}  # cache this block
        }
    ],
    messages=[{"role": "user", "content": "Review the auth module."}]
)

# Check cache status
usage = response.usage
print(f"Cache read: {usage.cache_read_input_tokens}")
print(f"Cache create: {usage.cache_creation_input_tokens}")
```

Caching rules:
- Minimum cacheable block: 1,024 tokens (Sonnet/Opus), 2,048 (Haiku)
- Cache TTL: 5 minutes
- Up to 4 cache breakpoints per request
- Cost: cache write = 1.25× normal input; cache read = 0.1× normal input

## Model Selection

| Model | ID | Best for | Cost |
|---|---|---|---|
| Claude Opus 4.6 | `claude-opus-4-6` | Complex reasoning, architecture | Highest |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | Balanced — default choice | Medium |
| Claude Haiku 4.5 | `claude-haiku-4-5-20251001` | Speed, cost, simple tasks | Lowest |

Default to `claude-sonnet-4-6`. Use Opus for tasks requiring deep reasoning. Use Haiku for high-volume, simple classification or extraction.

## Error Handling

```python
import anthropic
from anthropic import APIStatusError, APIConnectionError, RateLimitError

try:
    response = client.messages.create(...)
except RateLimitError as e:
    # Exponential backoff and retry
    time.sleep(2 ** retry_count)
except APIStatusError as e:
    if e.status_code == 529:  # overloaded
        time.sleep(60)
    else:
        raise
except APIConnectionError:
    # Network issue — retry with backoff
    raise
```

## Constraints

- Always use `max_tokens` — Claude will not infer it.
- Never log full API responses if they may contain PII or confidential content.
- Use streaming for responses expected to be longer than 2,000 tokens — avoids timeout issues.
- Use prompt caching when the same large context is sent on every request — the savings are significant.
- Do not include the API key in client-side (browser) code — all Claude API calls must go through your backend.
