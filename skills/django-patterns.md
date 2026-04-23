# Skill: django-patterns

## Purpose

Apply Django best practices to a Python/Django codebase — project structure, ORM patterns, security hardening, testing, and performance.

## Trigger

- Starting a new Django project or app
- Reviewing an existing Django codebase for patterns and anti-patterns
- Asked about Django models, views, serializers, or admin

## Trigger

`/django-patterns` or `apply django patterns to [target]`

## Agents

- `python-reviewer` — code quality and style
- `security-reviewer` — Django security specifics

## Patterns

### Project Structure

```
myproject/
├── config/          # settings/, urls.py, wsgi.py, asgi.py
├── apps/
│   └── users/       # models, views, urls, serializers, tests per app
├── templates/
├── static/
└── manage.py
```

- One app per bounded domain. Keep `settings/` split: `base.py`, `local.py`, `production.py`.

### Models

```python
# Use explicit string FK references to avoid circular imports
class Order(models.Model):
    user = models.ForeignKey("users.User", on_delete=models.PROTECT)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["user", "created_at"])]
```

- Use `select_related` / `prefetch_related` — never N+1.
- Use `update()` for bulk updates — do not loop and save.
- Avoid signals for business logic — use service layer functions.

### Views and URLs

- Use class-based views (`APIView`, `ModelViewSet`) for REST.
- Keep views thin — delegate to service functions.
- Use `get_object_or_404` — do not catch `DoesNotExist` manually.

### Security

- `ALLOWED_HOSTS`, `SECRET_KEY` from environment — never hardcoded.
- `DEBUG = False` in production.
- Use `django-environ` or `python-decouple` for config.
- Enable `SecurityMiddleware`, `CsrfViewMiddleware`, `XFrameOptionsMiddleware`.
- Use `django.contrib.auth` — do not roll your own auth.

### Testing

```python
# Use pytest-django
@pytest.mark.django_db
def test_create_order(client, user_factory):
    client.force_login(user_factory())
    response = client.post("/orders/", {"product_id": 1})
    assert response.status_code == 201
```

- Use factories (`factory_boy`) — not fixtures for complex objects.
- Test at the view level for API contracts; unit test service functions.

### DRF (Django REST Framework)

- Use serializers for all input validation — never `request.data` directly.
- Use `permissions_classes` and `authentication_classes` explicitly.
- Return standard response shapes — use a base serializer or response wrapper.

## Safe Behavior

- Analysis only unless asked to modify code.
- When writing code, follow `rules/python/coding-style.md` and `rules/python/security.md`.
