# Skill: content-hash-cache-pattern

## Purpose

Apply content-hash-based caching to avoid redundant LLM calls, expensive computations, or repeated file processing — cache results keyed by a hash of the input content.

## Trigger

- An LLM pipeline processes the same documents repeatedly
- A build step re-runs on unchanged inputs
- An embedding or classification step should not re-run if input hasn't changed
- Asked about caching LLM results or avoiding redundant processing

## Trigger

`/content-hash-cache-pattern` or `apply content hash cache to [pipeline]`

## Core Pattern

```python
import hashlib
import json
from pathlib import Path

def content_hash(content: str | bytes) -> str:
    """SHA-256 hash of content, hex-encoded."""
    if isinstance(content, str):
        content = content.encode()
    return hashlib.sha256(content).hexdigest()

class HashCache:
    def __init__(self, cache_dir: str = ".cache"):
        self.cache_dir = Path(cache_dir)
        self.cache_dir.mkdir(exist_ok=True)

    def get(self, key: str) -> dict | None:
        path = self.cache_dir / f"{key}.json"
        if path.exists():
            return json.loads(path.read_text())
        return None

    def set(self, key: str, value: dict) -> None:
        path = self.cache_dir / f"{key}.json"
        path.write_text(json.dumps(value))
```

## LLM Call Caching

```python
cache = HashCache(".llm-cache")

def classify_document(text: str) -> dict:
    # Build cache key from: model + prompt template + content
    key = content_hash(f"classify-v1:{text}")

    cached = cache.get(key)
    if cached:
        return cached  # skip LLM call entirely

    result = client.messages.create(
        model="claude-haiku-4-5-20251001",
        max_tokens=256,
        messages=[{"role": "user", "content": f"Classify this document:\n\n{text}"}],
    )
    data = {"label": result.content[0].text.strip()}
    cache.set(key, data)
    return data
```

- Include the model name and prompt version in the hash key — a prompt change should invalidate the cache.
- Use a version prefix in the key (`classify-v1:`) so you can invalidate all cached results for a task by bumping the version.

## File Processing Cache

```python
def process_file(path: str) -> dict:
    content = Path(path).read_bytes()
    key = content_hash(content)

    cached = HashCache().get(key)
    if cached:
        return cached

    result = expensive_process(content)
    HashCache().set(key, result)
    return result
```

## Embedding Cache

```python
def get_embedding(text: str) -> list[float]:
    key = content_hash(f"embed-v1:{text}")
    cached = cache.get(key)
    if cached:
        return cached["embedding"]

    embedding = embed_client.embed(text)
    cache.set(key, {"embedding": embedding})
    return embedding
```

## Cache Invalidation Strategy

| When to invalidate | How |
|-------------------|-----|
| Prompt changed | Bump version prefix in key (`v1` → `v2`) |
| Model changed | Include model name in key |
| Input content changed | Hash changes automatically |
| Force refresh | Delete cache entry or clear `.cache/` directory |

## Production Considerations

- **Storage**: file-based cache is fine for local dev; use Redis or a blob store for production.
- **TTL**: add an expiry timestamp to cached entries if results can become stale.
- **Security**: do not cache sensitive inputs (PII, credentials) — hash them only if necessary and store encrypted.
- **Size limits**: monitor cache directory size; prune old entries if it grows unbounded.

## Safe Behavior

- Cache files should not contain raw sensitive data — hash the key, store only the result.
- Cache directory should be in `.gitignore` — do not commit cached LLM outputs.
