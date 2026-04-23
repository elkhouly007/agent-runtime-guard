# Skill: Django Security

## Trigger

Use when:
- Starting a new Django project or auditing an existing one
- Adding authentication, authorization, or API endpoints
- Deploying to production or staging
- Reviewing code for security vulnerabilities
- Setting up HTTPS, secrets management, or hardening middleware

## Process

### 1. SECRET_KEY Management

Never commit `SECRET_KEY` to version control. Generate and inject via environment.

```python
# settings.py — correct approach
import os
from django.core.exceptions import ImproperlyConfigured

def get_env(var_name: str) -> str:
    value = os.environ.get(var_name)
    if not value:
        raise ImproperlyConfigured(f"Required env var '{var_name}' is missing.")
    return value

SECRET_KEY = get_env("DJANGO_SECRET_KEY")
```

Generate a strong key:
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 2. ALLOWED_HOSTS

```python
# settings.py
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "").split(",")
# e.g., ALLOWED_HOSTS=example.com,www.example.com

# Never in production:
# ALLOWED_HOSTS = ["*"]
```

### 3. CSRF Protection

Django enables CSRF middleware by default. Keep it in `MIDDLEWARE`:

```python
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",   # Do NOT remove
    ...
]
```

For APIs using DRF, use token-based auth and mark views with `@csrf_exempt` only when the endpoint is stateless and token-authenticated:

```python
from rest_framework.authentication import TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

class SecureView(APIView):
    authentication_classes = [TokenAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response({"data": "ok"})
```

### 4. SQL Injection — ORM vs Raw Queries

| Pattern | Safe? |
|---------|-------|
| `User.objects.filter(email=email)` | Yes — parameterized |
| `User.objects.raw("SELECT * FROM auth_user WHERE email = %s", [email])` | Yes — parameterized |
| `User.objects.raw(f"SELECT * WHERE email = '{email}'")` | NO — injection risk |
| `cursor.execute("... WHERE name = '%s'" % name)` | NO — injection risk |

```python
# Safe ORM query
users = User.objects.filter(username=request.POST["username"])

# Safe raw query when ORM is insufficient
from django.db import connection
with connection.cursor() as cursor:
    cursor.execute("SELECT id FROM myapp_order WHERE status = %s", [status])
    rows = cursor.fetchall()
```

### 5. XSS — Template Auto-Escaping

Django templates auto-escape by default. Never disable without explicit intent:

```html
<!-- Safe — auto-escaped -->
<p>{{ user.bio }}</p>

<!-- Unsafe — only use for pre-sanitized HTML you control -->
<p>{{ user.bio|safe }}</p>

<!-- Sanitize if you must render HTML from users -->
```

```bash
pip install bleach
```

```python
import bleach

ALLOWED_TAGS = ["b", "i", "u", "em", "strong", "a"]
ALLOWED_ATTRS = {"a": ["href", "title"]}

def clean_html(value: str) -> str:
    return bleach.clean(value, tags=ALLOWED_TAGS, attributes=ALLOWED_ATTRS)
```

### 6. Authentication — AbstractUser and Password Validators

```python
# models.py
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    email = models.EmailField(unique=True)
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]
```

```python
# settings.py
AUTH_USER_MODEL = "accounts.User"

AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
     "OPTIONS": {"min_length": 12}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]
```

### 7. Permissions and @login_required

```python
from django.contrib.auth.decorators import login_required, permission_required
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin

# Function-based views
@login_required
def dashboard(request):
    return render(request, "dashboard.html")

@permission_required("billing.can_issue_refund", raise_exception=True)
def issue_refund(request, order_id):
    ...

# Class-based views
class InvoiceListView(LoginRequiredMixin, PermissionRequiredMixin, ListView):
    permission_required = "billing.view_invoice"
    login_url = "/login/"
    model = Invoice
```

### 8. HTTPS / HSTS Settings

```python
# settings/production.py
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000          # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True        # Django < 4.0
X_FRAME_OPTIONS = "DENY"
```

### 9. Security Middleware Checklist

Run Django's deployment check:
```bash
python manage.py check --deploy
```

Expected middleware order:
```python
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",    # Must be first
    "whitenoise.middleware.WhiteNoiseMiddleware",       # If using WhiteNoise
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]
```

### 10. django-axes — Brute Force Protection

```bash
pip install django-axes
```

```python
# settings.py
INSTALLED_APPS += ["axes"]
MIDDLEWARE += ["axes.middleware.AxesMiddleware"]
AUTHENTICATION_BACKENDS = [
    "axes.backends.AxesStandaloneBackend",
    "django.contrib.auth.backends.ModelBackend",
]

AXES_FAILURE_LIMIT = 5          # Lock after 5 failures
AXES_COOLOFF_TIME = 1           # 1 hour cooloff
AXES_LOCKOUT_CALLABLE = "myapp.utils.axes_lockout_handler"
AXES_RESET_ON_SUCCESS = True
```

```bash
python manage.py migrate
# Unlock a specific user:
python manage.py axes_reset_ip --ip 192.168.1.1
```

### 11. Security Scanning — bandit + safety

```bash
pip install bandit safety
```

```bash
# Static security analysis
bandit -r . -x ./venv,./tests -ll

# Known vulnerability check
safety check --full-report

# Or with pip-audit (modern alternative)
pip install pip-audit
pip-audit
```

Add to CI:
```yaml
# .github/workflows/security.yml
- name: Run bandit
  run: bandit -r . -x ./venv,./tests -ll --exit-zero

- name: Run pip-audit
  run: pip-audit --requirement requirements.txt
```

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| `DEBUG = True` in production | Leaks stack traces, settings | Use env var to toggle |
| `ALLOWED_HOSTS = ["*"]` | Host header injection | Enumerate exact hosts |
| `SECRET_KEY` in settings.py | Key exposure via VCS | Use env var |
| `|safe` on user input | XSS | Use bleach or strip HTML |
| Raw SQL with f-strings | SQL injection | Use parameterized queries |
| `@csrf_exempt` on session views | CSRF | Only for token-auth APIs |
| No password validators | Weak passwords | Enable all 4 validators |
| HTTP in production | Credential sniffing | Force HTTPS + HSTS |

## Safe Behavior

- Always run `python manage.py check --deploy` before every production deployment.
- Never commit `.env` files or `SECRET_KEY` values to version control.
- Rotate `SECRET_KEY` immediately if it is ever exposed; this invalidates all sessions.
- Review every use of `|safe`, `mark_safe()`, and `@csrf_exempt` — each requires justification.
- Run `bandit` and `pip-audit` in CI on every pull request.
- Test authentication and permission gates explicitly in tests — do not rely on manual review.
