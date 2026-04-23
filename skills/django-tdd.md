# Skill: Django TDD

## Trigger

Use when:
- Writing new Django views, models, forms, or signals
- Fixing a bug in a Django application
- Adding API endpoints to a DRF application
- Setting up a new Django project's test infrastructure
- Any feature where behavior can be stated before coding starts

## The TDD Cycle (Django-Adapted)

```
RED    → Write a failing Django test (view returns 403, model raises, form rejects)
GREEN  → Write the minimum model/view/form code to make it pass
REFACTOR → Clean up, extract helpers, verify green with full suite
repeat
```

**Never skip RED.** If your test passes before you write the implementation, the test is wrong.

## Process

### 1. Choose the Right Test Class

| Class | Use When | DB Access | Speed |
|-------|----------|-----------|-------|
| `SimpleTestCase` | Testing pure logic, utilities, templates | No | Fastest |
| `TestCase` | Views, models, forms — isolated per test | Yes (wrapped in transaction, rolled back) | Fast |
| `TransactionTestCase` | Testing DB signals, `on_commit`, transactions | Yes (real commits, flushed after each test) | Slow |
| `LiveServerTestCase` | Selenium / browser tests | Yes | Slowest |

```python
from django.test import TestCase, SimpleTestCase, TransactionTestCase

class PureLogicTest(SimpleTestCase):
    def test_email_normalization(self):
        from myapp.utils import normalize_email
        self.assertEqual(normalize_email("USER@Example.COM"), "user@example.com")

class ModelTest(TestCase):
    def test_order_total_sums_line_items(self):
        order = Order.objects.create(status="pending")
        LineItem.objects.create(order=order, price=1000, qty=2)
        LineItem.objects.create(order=order, price=500, qty=1)
        self.assertEqual(order.total(), 2500)

class PostSaveSignalTest(TransactionTestCase):
    def test_invoice_created_on_order_complete(self):
        order = Order.objects.create(status="complete")
        self.assertTrue(Invoice.objects.filter(order=order).exists())
```

### 2. pytest-django Setup

```bash
pip install pytest pytest-django pytest-cov factory-boy
```

```ini
# pytest.ini
[pytest]
DJANGO_SETTINGS_MODULE = config.settings.test
python_files = tests.py test_*.py *_tests.py
addopts = --reuse-db --strict-markers
```

```python
# conftest.py
import pytest

@pytest.fixture(scope="session")
def django_db_setup():
    pass  # use default test DB

@pytest.fixture
def authenticated_client(client, django_user_model):
    user = django_user_model.objects.create_user(
        username="testuser", password="testpass123"
    )
    client.force_login(user)
    return client, user
```

### 3. factory_boy for Test Data

```bash
pip install factory-boy
```

```python
# factories.py
import factory
from factory.django import DjangoModelFactory
from myapp.models import User, Order, LineItem

class UserFactory(DjangoModelFactory):
    class Meta:
        model = User

    username = factory.Sequence(lambda n: f"user{n}")
    email = factory.LazyAttribute(lambda o: f"{o.username}@example.com")
    password = factory.PostGenerationMethodCall("set_password", "password123")

class OrderFactory(DjangoModelFactory):
    class Meta:
        model = Order

    user = factory.SubFactory(UserFactory)
    status = "pending"

class LineItemFactory(DjangoModelFactory):
    class Meta:
        model = LineItem

    order = factory.SubFactory(OrderFactory)
    price = 1000
    qty = 1
```

Usage in tests:
```python
from myapp.factories import UserFactory, OrderFactory, LineItemFactory

class OrderTotalTest(TestCase):
    def test_total_with_multiple_items(self):
        order = OrderFactory()
        LineItemFactory(order=order, price=500, qty=3)
        LineItemFactory(order=order, price=200, qty=1)
        self.assertEqual(order.total(), 1700)
```

### 4. Testing Views — Client vs RequestFactory

**Client** — Full request cycle including middleware, sessions, auth:
```python
from django.test import TestCase, Client

class DashboardViewTest(TestCase):
    def setUp(self):
        self.client = Client()
        self.user = UserFactory()

    def test_redirects_unauthenticated(self):
        response = self.client.get("/dashboard/")
        self.assertRedirects(response, "/login/?next=/dashboard/")

    def test_authenticated_user_sees_dashboard(self):
        self.client.force_login(self.user)
        response = self.client.get("/dashboard/")
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Welcome")

    def test_post_creates_order(self):
        self.client.force_login(self.user)
        response = self.client.post("/orders/create/", {"item": "widget", "qty": 2})
        self.assertRedirects(response, "/orders/")
        self.assertEqual(Order.objects.filter(user=self.user).count(), 1)
```

**RequestFactory** — No middleware, for unit-testing view functions directly:
```python
from django.test import RequestFactory
from myapp.views import dashboard_view

class DashboardViewUnitTest(TestCase):
    def setUp(self):
        self.factory = RequestFactory()
        self.user = UserFactory()

    def test_returns_200(self):
        request = self.factory.get("/dashboard/")
        request.user = self.user
        response = dashboard_view(request)
        self.assertEqual(response.status_code, 200)
```

### 5. Testing Models

```python
class OrderModelTest(TestCase):
    def test_str_representation(self):
        order = OrderFactory(status="pending")
        self.assertEqual(str(order), f"Order #{order.pk} — pending")

    def test_cannot_cancel_completed_order(self):
        order = OrderFactory(status="complete")
        with self.assertRaises(ValueError, msg="Cannot cancel a completed order"):
            order.cancel()

    def test_mark_complete_sets_completed_at(self):
        order = OrderFactory(status="pending")
        order.mark_complete()
        self.assertIsNotNone(order.completed_at)
        self.assertEqual(order.status, "complete")
```

### 6. Testing Forms

```python
from myapp.forms import RegistrationForm

class RegistrationFormTest(TestCase):
    def test_valid_data_passes(self):
        form = RegistrationForm(data={
            "username": "alice",
            "email": "alice@example.com",
            "password1": "Str0ng!Pass99",
            "password2": "Str0ng!Pass99",
        })
        self.assertTrue(form.is_valid())

    def test_duplicate_email_fails(self):
        UserFactory(email="alice@example.com")
        form = RegistrationForm(data={
            "username": "bob",
            "email": "alice@example.com",
            "password1": "Str0ng!Pass99",
            "password2": "Str0ng!Pass99",
        })
        self.assertFalse(form.is_valid())
        self.assertIn("email", form.errors)

    def test_password_mismatch_fails(self):
        form = RegistrationForm(data={
            "username": "carol",
            "email": "carol@example.com",
            "password1": "Str0ng!Pass99",
            "password2": "DifferentPass99",
        })
        self.assertFalse(form.is_valid())
```

### 7. Testing Signals

```python
from unittest.mock import patch
from django.test import TransactionTestCase

class OrderSignalTest(TransactionTestCase):
    def test_welcome_email_sent_on_user_create(self):
        with patch("myapp.signals.send_welcome_email") as mock_send:
            user = UserFactory()
            mock_send.assert_called_once_with(user)

    def test_invoice_auto_created_on_order_complete(self):
        order = OrderFactory(status="pending")
        order.status = "complete"
        order.save()
        self.assertTrue(Invoice.objects.filter(order=order).exists())
```

### 8. Coverage with pytest-cov

```bash
pytest --cov=myapp --cov-report=term-missing --cov-fail-under=90
```

```ini
# .coveragerc
[run]
source = myapp
omit =
    */migrations/*
    */tests/*
    conftest.py
    manage.py

[report]
exclude_lines =
    pragma: no cover
    def __repr__
    if TYPE_CHECKING:
```

## Test Naming Convention

| Bad | Good |
|-----|------|
| `test_order()` | `test_order_total_sums_all_line_items()` |
| `test_view()` | `test_dashboard_redirects_when_unauthenticated()` |
| `test_form_valid` | `test_registration_form_rejects_duplicate_email()` |
| `test_signal` | `test_invoice_created_when_order_status_becomes_complete()` |

## Anti-Patterns

- Using `TestCase` for signal tests that rely on `on_commit` — use `TransactionTestCase`.
- Creating test data with `User.objects.create()` instead of factories — hard to maintain.
- Testing implementation details (private method return values) instead of behavior.
- Sharing state between tests via class-level `setUpClass` mutations — leads to order-dependent failures.
- Mocking the ORM itself — use the test database; it's fast enough.
- Skipping the RED step by writing tests after code — produces confirmation tests, not behavior specs.

## Safe Behavior

- Run the full test suite before every commit: `pytest --tb=short`.
- New feature = new test file in `tests/` alongside the module.
- A failing test in CI blocks merge — no exceptions.
- Do not use `# noqa` or skip markers to silence failing tests; fix the root cause.
- Migrations must be applied before the test suite runs; use `--reuse-db` only in local dev, not CI.
