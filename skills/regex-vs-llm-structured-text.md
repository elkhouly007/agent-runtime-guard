# Skill: regex-vs-llm-structured-text

## Purpose

Choose the right tool for structured text extraction — decide when to use regex/parsing vs. an LLM call, and apply the appropriate pattern for each case.

## Trigger

- Extracting structured data from text (logs, documents, user input, API responses)
- Unsure whether to write a parser or call an LLM for extraction
- An LLM extraction is slow or expensive and you want to know if a simpler approach works

## Trigger

`/regex-vs-llm-structured-text` or `should I use regex or LLM for [extraction task]`

## Decision Framework

### Use Regex / Parsing When

- The format is **deterministic and well-defined** (ISO dates, UUIDs, email addresses, log lines with fixed structure).
- The input volume is **high** (thousands of items) — LLM cost per item would be prohibitive.
- **Latency** is critical — regex runs in microseconds; LLM adds 100ms–5s.
- The extraction rule can be expressed as a pattern without ambiguity.

```python
# Regex — deterministic format
import re
LOG_PATTERN = re.compile(r'(?P<level>ERROR|WARN|INFO) (?P<ts>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}) (?P<msg>.+)')

def parse_log_line(line: str) -> dict | None:
    m = LOG_PATTERN.match(line)
    return m.groupdict() if m else None
```

### Use LLM When

- The format is **semi-structured or natural language** (emails, support tickets, free-form notes).
- The extraction requires **semantic understanding** (sentiment, intent, named entities in context).
- The format **varies** across sources and writing a comprehensive regex would be brittle.
- Volume is **low to moderate** and quality matters more than cost.

```python
# LLM extraction — variable format
response = client.messages.create(
    model="claude-haiku-4-5-20251001",  # use cheapest model sufficient for the task
    max_tokens=256,
    messages=[{
        "role": "user",
        "content": f"""Extract the customer name, issue type, and urgency from this support ticket.
Return JSON only.

Ticket:
{ticket_text}"""
    }]
)
data = json.loads(response.content[0].text)
```

### Hybrid — Parse First, LLM for Ambiguous Cases

```python
def extract(text: str) -> dict:
    # Fast path: try regex first
    m = SIMPLE_PATTERN.match(text)
    if m:
        return m.groupdict()
    # Slow path: fall back to LLM for ambiguous cases
    return llm_extract(text)
```

## Structured Output from LLMs

When using an LLM for extraction, always request structured output:

```python
# Anthropic — JSON mode via prompt instruction
"Return a JSON object with keys: name, issue_type, urgency. No other text."

# Validate the response
import json
from pydantic import BaseModel

class Extracted(BaseModel):
    name: str
    issue_type: str
    urgency: str

data = Extracted.model_validate_json(response.content[0].text)
```

- Always validate LLM JSON output with Pydantic or a schema — never trust it blindly.
- Use low temperature (0.0–0.2) for extraction tasks.
- Use the cheapest model that achieves sufficient quality — run quality evals before upgrading.

## Cost/Quality Tradeoff Table

| Input type | Volume | Recommended approach |
|------------|--------|----------------------|
| Fixed log format | Any | Regex |
| Structured API response | Any | JSON parsing, no LLM |
| Email/ticket | Low-medium | LLM (Haiku) |
| Legal/medical documents | Any | LLM (Sonnet/Opus) |
| Mixed formats, one pipeline | High | Hybrid (regex first) |

## Safe Behavior

- This skill is advisory — it recommends an approach, does not implement it.
- LLM extraction for sensitive data (PII, medical, financial) requires explicit handling rules.
