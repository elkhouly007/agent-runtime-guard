# Skill: fastapi-patterns

## Purpose

Apply FastAPI best practices — project structure, dependency injection, Pydantic models, async patterns, security, and testing for Python async APIs.

## Trigger

- Starting or reviewing a FastAPI project
- Implementing routes, dependencies, or background tasks
- Asked about FastAPI routing, Pydantic, or async patterns

## Trigger

`/fastapi-patterns` or `apply fastapi patterns to [target]`

## Agents

- `python-reviewer` — Python code quality
- `security-reviewer` — API security

## Patterns

### Project Structure

```
app/
├── main.py              # App factory, router registration
├── config.py            # Settings via pydantic-settings
├── dependencies.py      # Shared FastAPI dependencies
├── routers/
│   └── orders.py        # APIRouter per domain
├── schemas/
│   └── order.py         # Pydantic request/response models
├── services/
│   └── order_service.py # Business logic
├── models/
│   └── order.py         # SQLAlchemy ORM models
└── tests/
```

### App Factory

```python
def create_app() -> FastAPI:
    app = FastAPI(title="My API", version="1.0.0")
    app.include_router(orders_router, prefix="/api/v1/orders")
    return app
```

### Pydantic Schemas

```python
from pydantic import BaseModel, Field, ConfigDict

class CreateOrderRequest(BaseModel):
    product_id: str
    quantity: int = Field(gt=0, le=1000)

class OrderResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    product_id: str
    quantity: int
```

- Use `Field` for constraints. Use `model_config = ConfigDict(from_attributes=True)` for ORM response models.
- Never return ORM objects directly — always serialize through a response schema.

### Dependency Injection

```python
async def get_current_user(token: str = Depends(oauth2_scheme), db: AsyncSession = Depends(get_db)) -> User:
    ...

@router.post("/", response_model=OrderResponse)
async def create_order(req: CreateOrderRequest, user: User = Depends(get_current_user)):
    return await order_service.create(req, user)
```

### Async Database (SQLAlchemy 2.x)

```python
async with AsyncSession(engine) as session:
    result = await session.execute(select(Order).where(Order.user_id == user_id))
    orders = result.scalars().all()
```

- Use `AsyncSession` everywhere — never mix sync and async sessions.
- Use `select()` statements, not legacy `Query` API.

### Configuration

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    secret_key: str
    model_config = SettingsConfigDict(env_file=".env")

settings = Settings()
```

- Use `pydantic-settings` — reads from environment variables automatically.
- Call `Settings()` once at startup — do not re-instantiate per request.

### Testing

```python
from httpx import AsyncClient, ASGITransport

@pytest.mark.anyio
async def test_create_order(async_client: AsyncClient):
    response = await async_client.post("/api/v1/orders", json={"product_id": "p1", "quantity": 2})
    assert response.status_code == 201
```

- Use `httpx.AsyncClient` with `ASGITransport` for async test client.
- Override dependencies with `app.dependency_overrides` in tests.

## Safe Behavior

- Analysis only unless asked to modify code.
- Follow `rules/python/coding-style.md` and `rules/python/security.md`.
