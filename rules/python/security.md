---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Python Security Rules

## Input Validation

- Validate all external inputs with Pydantic or marshmallow at the boundary.
- Reject invalid input early — do not try to sanitize and continue.
- Use allowlists for accepted values, not denylists.

```python
from pydantic import BaseModel, field_validator
from typing import Literal

class CreateUserRequest(BaseModel):
    username: str
    role: Literal["admin", "editor", "viewer"]

    @field_validator("username")
    @classmethod
    def username_alphanumeric(cls, v: str) -> str:
        if not v.isalnum():
            raise ValueError("username must be alphanumeric")
        return v
```

## Injection Prevention

- Parameterize all database queries:

```python
# BAD — SQL injection risk
cursor.execute(f"SELECT * FROM users WHERE name = '{name}'")

# GOOD — parameterized
cursor.execute("SELECT * FROM users WHERE name = %s", (name,))

# GOOD — SQLAlchemy ORM
user = session.query(User).filter(User.name == name).first()
```

- Never use `eval()` or `exec()` on user-supplied input.
- Avoid `subprocess` with `shell=True` and user input.
- Validate file paths with `Path.resolve()` against a base directory.

```python
# BAD — path traversal
def read_file(filename: str):
    return open(f"/uploads/{filename}").read()

# GOOD — resolve and check
from pathlib import Path

BASE_DIR = Path("/uploads").resolve()

def read_file(filename: str) -> str:
    path = (BASE_DIR / filename).resolve()
    if not str(path).startswith(str(BASE_DIR)):
        raise PermissionError("Path traversal detected")
    return path.read_text()

# BAD — shell injection risk
subprocess.run(f"convert {user_input}", shell=True)

# GOOD — list form, no shell
subprocess.run(["convert", user_input], shell=False, check=True)
```

## Deserialization

- Never use `pickle.loads()` on untrusted data — it can execute arbitrary code.
- Use JSON, Pydantic, or other safe deserialization for untrusted input.
- `yaml.safe_load()` not `yaml.load()` without a Loader argument.

```python
# BAD
data = pickle.loads(request.body)
config = yaml.load(content)  # unsafe

# GOOD
data = UserModel.model_validate_json(request.body)
config = yaml.safe_load(content)
```

## Secrets

- Use `secrets` module for cryptographic randomness — not `random`.
- Store secrets in environment variables or a secrets manager — never in code.
- Do not log sensitive data.

```python
# BAD
token = random.randint(100000, 999999)
API_KEY = "sk-abc123hardcoded"

# GOOD
import secrets
token = secrets.token_hex(32)

import os
API_KEY = os.environ["API_KEY"]  # raises KeyError if missing — intentional

# BAD — logs PII
logger.info(f"Login attempt for user {email} with password {password}")

# GOOD
logger.info(f"Login attempt for user {user_id}")
```

## Django/FastAPI Specific

- `DEBUG = False` in production.
- `SECRET_KEY` must be long, random, and kept secret.
- Use Django's built-in CSRF protection — do not disable it.
- Validate all query parameters and request bodies explicitly.
- Use `get_object_or_404` and ORM methods — avoid raw SQL.

```python
# FastAPI — explicit body validation
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class ItemRequest(BaseModel):
    name: str
    quantity: int

@app.post("/items")
async def create_item(body: ItemRequest):
    return {"created": body.name}
```

## Dependencies

```bash
# Audit for known vulnerabilities
pip audit

# Alternative
safety check -r requirements.txt

# Check for outdated packages
pip list --outdated

# Pin exact versions for production
pip freeze > requirements.txt
```

## Security Scanning in CI

```yaml
# GitHub Actions example
- name: Security audit
  run: pip audit

- name: Static analysis
  run: bandit -r src/ -ll
```

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `eval(user_input)` | Parse with JSON/Pydantic |
| `subprocess(shell=True, input=user)` | Use list args, `shell=False` |
| `pickle.loads(untrusted)` | Use JSON or Pydantic |
| `yaml.load(content)` | `yaml.safe_load(content)` |
| `random.randint()` for secrets | `secrets.token_hex()` / `secrets.token_bytes()` |
| Hardcoded API keys | `os.environ["KEY"]` |
| Logging passwords/tokens | Log user IDs only |
