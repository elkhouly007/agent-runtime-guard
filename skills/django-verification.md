# Skill: Django Verification Loops

## Trigger

Use when:
- Completing any feature or bug fix before opening a PR
- Before deploying to staging or production
- After writing migrations
- After changing settings, Celery tasks, or management commands
- Setting up CI for a Django project

## Process

### 1. Pre-Commit Checks

Install the toolchain:
```bash
pip install flake8 mypy black isort django-stubs
```

Run manually:
```bash
# Format
black .
isort .

# Lint
flake8 . --max-line-length=88 --extend-ignore=E203,W503

# Type check
mypy . --ignore-missing-imports
```

Configure `.pre-commit-config.yaml`:
```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 24.4.2
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/PyCQA/isort
    rev: 5.13.2
    hooks:
      - id: isort
        args: ["--profile", "black"]

  - repo: https://github.com/PyCQA/flake8
    rev: 7.0.0
    hooks:
      - id: flake8

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.10.0
    hooks:
      - id: mypy
        additional_dependencies: [django-stubs, types-requests]
```

Install hooks:
```bash
pre-commit install
pre-commit run --all-files   # verify on existing codebase
```

### 2. Django System Checks

```bash
# Full system check
python manage.py check

# Deployment-specific checks (catches insecure settings)
python manage.py check --deploy --settings=config.settings.production

# Check specific app
python manage.py check myapp
```

Expected output on clean project: `System check identified no issues (0 silenced).`

### 3. Migration Safety Checks

```bash
# Verify no missing migrations exist
python manage.py makemigrations --check --dry-run

# Show current migration state
python manage.py showmigrations

# Check for backwards-incompatible migrations
python manage.py migrate --plan

# Squash if migration count is excessive
python manage.py squashmigrations myapp 0001 0050
```

Dangerous migration patterns to catch before deployment:
| Operation | Risk | Mitigation |
|-----------|------|------------|
| `NOT NULL` column with no default on large table | Locks table | Add nullable first, backfill, then add constraint |
| Renaming a model/field | Breaks references | Use `db_column` or migrate in 3 steps |
| Deleting a column still referenced in code | Runtime error | Deploy code removal first, then migration |
| Adding unique constraint | Full table scan + lock | Use `CreateIndex` concurrently on PostgreSQL |

### 4. Management Command Testing

```bash
# Test a management command directly
python manage.py my_command --dry-run

# Test via Django's call_command in tests
from django.core.management import call_command
from io import StringIO

class ImportCommandTest(TestCase):
    def test_import_dry_run_prints_summary(self):
        out = StringIO()
        call_command("import_users", "--dry-run", stdout=out)
        self.assertIn("Would import 0 users", out.getvalue())

    def test_import_creates_records(self):
        call_command("import_users", "--file=tests/fixtures/users.csv")
        self.assertEqual(User.objects.count(), 3)
```

### 5. shell_plus Exploration

```bash
pip install django-extensions
```

```bash
# Enhanced shell with all models auto-imported
python manage.py shell_plus

# One-liners for quick verification
python manage.py shell_plus --quiet-load -c "
from myapp.models import Order
print(Order.objects.filter(status='pending').count())
"

# Run a script file
python manage.py shell_plus --script=scripts/verify_data.py
```

### 6. Health Check Endpoints

```python
# myapp/views.py
from django.http import JsonResponse
from django.db import connection
from django.core.cache import cache

def health_check(request):
    checks = {}
    # Database
    try:
        connection.ensure_connection()
        checks["db"] = "ok"
    except Exception as e:
        checks["db"] = f"error: {e}"

    # Cache
    try:
        cache.set("health_check", "ok", timeout=5)
        assert cache.get("health_check") == "ok"
        checks["cache"] = "ok"
    except Exception as e:
        checks["cache"] = f"error: {e}"

    status = 200 if all(v == "ok" for v in checks.values()) else 503
    return JsonResponse({"status": "ok" if status == 200 else "degraded", **checks},
                        status=status)
```

```python
# urls.py
from django.urls import path
from myapp.views import health_check

urlpatterns = [
    path("health/", health_check, name="health_check"),
]
```

Verify:
```bash
curl -s http://localhost:8000/health/ | python -m json.tool
```

### 7. Celery Task Verification

```bash
# Start worker in test mode (solo pool, no forking)
celery -A config worker --pool=solo --loglevel=info

# Inspect registered tasks
celery -A config inspect registered

# Test task execution inline (no broker needed in tests)
from myapp.tasks import send_report

# In test — eager execution
from django.test import override_settings

@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
def test_report_task_sends_email(self):
    with self.assertRaises(Exception):
        pass
    result = send_report.delay(user_id=self.user.pk)
    self.assertTrue(result.successful())
```

```python
# settings/test.py
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True
```

### 8. Staging vs Production Config Diff

```bash
# Compare settings side-by-side
python manage.py diffsettings --settings=config.settings.staging \
    --default=config.settings.production

# Print all effective settings (useful for debugging)
python manage.py print_settings --settings=config.settings.staging
```

Check these values differ correctly between environments:
| Setting | Staging | Production |
|---------|---------|------------|
| `DEBUG` | `False` | `False` |
| `ALLOWED_HOSTS` | staging domain | prod domain |
| `DATABASES` | staging DB | prod DB |
| `EMAIL_BACKEND` | `console` or `filebased` | `smtp` |
| `CELERY_BROKER_URL` | staging Redis | prod Redis |
| `SENTRY_DSN` | staging project | prod project |

### 9. Full Verification Loop (Pre-PR Checklist)

```bash
#!/bin/bash
set -e

echo "=== Format ==="
black --check .
isort --check-only .

echo "=== Lint ==="
flake8 .

echo "=== Type Check ==="
mypy . --ignore-missing-imports

echo "=== System Check ==="
python manage.py check

echo "=== Migration Check ==="
python manage.py makemigrations --check --dry-run

echo "=== Tests ==="
pytest --cov=. --cov-report=term-missing --cov-fail-under=85 -q

echo "=== Security ==="
bandit -r . -x ./venv,./tests -ll

echo "=== All checks passed ==="
```

Save as `scripts/verify.sh` and run before every PR.

## Anti-Patterns

- Running only `python manage.py test` without coverage thresholds — passes with 5% coverage.
- Skipping `--check` flag on `makemigrations` in CI — allows missing migrations to reach staging.
- Not testing management commands via `call_command` — they rot silently.
- Using `CELERY_TASK_ALWAYS_EAGER` in staging/prod to avoid broker — hides async bugs.
- Diverging settings files with no diff check — staging quietly becomes different from production.

## Safe Behavior

- The verification script runs in CI on every PR; no merge without green.
- `python manage.py check --deploy` runs in the deployment pipeline, not just locally.
- Migration files are reviewed for table locks before merging to main.
- Health check endpoint is monitored externally (uptime robot, Pingdom, etc.).
- `CELERY_TASK_ALWAYS_EAGER` is only `True` in test settings — never staging or production.
