# Skill: Laravel TDD (PHPUnit / Pest)

## Trigger

Use when:
- Writing new Laravel controllers, services, models, or jobs
- Fixing a bug — the bug itself is a missing test
- Adding API endpoints to a Laravel application
- Setting up the test infrastructure for a new project
- Any feature where the behavior can be stated before coding

## The TDD Cycle (Laravel-Adapted)

```
RED    → Write a failing test (assertStatus 403, assertDatabaseMissing, assertThrows)
GREEN  → Write minimum controller/service/model code to make it pass
REFACTOR → Clean up, extract helpers, re-run full suite to confirm green
repeat
```

**Never skip RED.** Run the test before the implementation exists — confirm the failure message is what you expect, not a syntax error.

## Process

### 1. Feature vs Unit Tests

| Type | Location | When to Use |
|------|----------|-------------|
| Feature | `tests/Feature/` | HTTP endpoints, full stack (DB + middleware + auth) |
| Unit | `tests/Unit/` | Services, pure logic, calculations, utilities |

```php
// tests/Feature/OrderControllerTest.php — full HTTP test
class OrderControllerTest extends TestCase
{
    use RefreshDatabase;

    public function test_unauthenticated_user_cannot_place_order(): void
    {
        $response = $this->postJson('/api/orders', ['items' => []]);
        $response->assertStatus(401);
    }
}

// tests/Unit/OrderServiceTest.php — pure logic test
class OrderServiceTest extends TestCase
{
    public function test_total_sums_all_line_items(): void
    {
        $service = new OrderService(new FakeOrderRepository());
        $total = $service->calculateTotal([
            ['price' => 1000, 'qty' => 2],
            ['price' => 500, 'qty' => 1],
        ]);
        $this->assertEquals(2500, $total);
    }
}
```

### 2. RefreshDatabase vs DatabaseTransactions

| Trait | Behavior | Speed | Use When |
|-------|----------|-------|----------|
| `RefreshDatabase` | Runs full migration on first test, wraps each test in a transaction and rolls back | Moderate | Most Feature tests — clean DB state |
| `DatabaseTransactions` | Wraps test in transaction, rolls back after | Fast | No migrations needed between tests |
| Neither | Persistent data across tests | N/A | Tests that must survive rollback (e.g., testing `COMMIT`) |

```php
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\DatabaseTransactions;

class OrderFeatureTest extends TestCase
{
    use RefreshDatabase;    // each test starts with a clean DB
}
```

### 3. Factories and Seeders in Tests

```php
// database/factories/OrderFactory.php
namespace Database\Factories;

use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class OrderFactory extends Factory
{
    protected $model = Order::class;

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'status' => 'pending',
            'total' => $this->faker->numberBetween(500, 50000),
            'delivery_address' => $this->faker->address(),
        ];
    }

    public function completed(): static
    {
        return $this->state(['status' => 'complete', 'completed_at' => now()]);
    }

    public function withItems(int $count = 3): static
    {
        return $this->afterCreating(function (Order $order) use ($count) {
            LineItem::factory()->count($count)->create(['order_id' => $order->id]);
        });
    }
}
```

Usage in tests:
```php
// Create with factory states
$order = Order::factory()->completed()->withItems(2)->create();

// Create for a specific user
$user = User::factory()->create();
$orders = Order::factory()->count(5)->for($user)->create();
```

### 4. HTTP Test Helpers

```php
class OrderApiTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
    }

    public function test_authenticated_user_can_list_orders(): void
    {
        Order::factory()->count(3)->for($this->user)->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->getJson('/api/orders');

        $response->assertStatus(200)
            ->assertJsonCount(3, 'data')
            ->assertJsonStructure([
                'data' => [['id', 'status', 'total', 'placed_at']],
            ]);
    }

    public function test_place_order_creates_record_and_fires_event(): void
    {
        Event::fake([OrderPlaced::class]);

        $response = $this->actingAs($this->user, 'sanctum')
            ->postJson('/api/orders', [
                'items' => [
                    ['product_id' => Product::factory()->create()->id, 'qty' => 2, 'price' => 1500],
                ],
                'delivery_address' => '123 Main St',
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('status', 'pending');

        $this->assertDatabaseHas('orders', [
            'user_id' => $this->user->id,
            'status' => 'pending',
        ]);

        Event::assertDispatched(OrderPlaced::class);
    }

    public function test_cannot_cancel_completed_order(): void
    {
        $order = Order::factory()->completed()->for($this->user)->create();

        $response = $this->actingAs($this->user, 'sanctum')
            ->deleteJson("/api/orders/{$order->id}");

        $response->assertStatus(422)
            ->assertJsonPath('message', 'Cannot cancel a completed order.');
    }
}
```

### 5. Mocking — Mail, Event, Queue, Storage

```php
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Facades\Storage;

public function test_confirmation_email_queued_on_order_placed(): void
{
    Mail::fake();

    $order = Order::factory()->create();
    event(new OrderPlaced($order));

    Mail::assertQueued(OrderConfirmationMail::class, function ($mail) use ($order) {
        return $mail->order->is($order);
    });
}

public function test_pdf_job_dispatched_on_invoice_create(): void
{
    Queue::fake();

    $this->actingAs($this->user, 'sanctum')
        ->postJson('/api/orders', $this->validOrderPayload());

    Queue::assertPushed(GenerateInvoicePdf::class);
    Queue::assertPushedOn('pdfs', GenerateInvoicePdf::class);
}

public function test_report_file_stored_on_s3(): void
{
    Storage::fake('s3');

    $this->actingAs($this->user, 'sanctum')
        ->postJson('/api/reports/generate', ['type' => 'monthly']);

    Storage::disk('s3')->assertExists("reports/{$this->user->id}/monthly.pdf");
}
```

### 6. Pest Syntax Alternatives

```php
// tests/Feature/OrderTest.php — Pest style
use App\Models\Order;
use App\Models\User;

uses(\Illuminate\Foundation\Testing\RefreshDatabase::class);

beforeEach(function () {
    $this->user = User::factory()->create();
});

it('returns 401 for unauthenticated requests', function () {
    $this->getJson('/api/orders')->assertStatus(401);
});

it('lists only the authenticated user\'s orders', function () {
    Order::factory()->count(2)->for($this->user)->create();
    Order::factory()->count(3)->create();  // other users

    $this->actingAs($this->user, 'sanctum')
        ->getJson('/api/orders')
        ->assertStatus(200)
        ->assertJsonCount(2, 'data');
});

it('throws when cancelling a completed order', function () {
    $order = Order::factory()->completed()->for($this->user)->create();

    $this->actingAs($this->user, 'sanctum')
        ->deleteJson("/api/orders/{$order->id}")
        ->assertStatus(422);
})->throws(\App\Exceptions\InvalidOrderStateException::class);
```

## Test Naming Convention

| Bad | Good |
|-----|------|
| `test_order()` | `test_place_order_creates_record_and_dispatches_event()` |
| `test_cancel()` | `test_cannot_cancel_a_completed_order()` |
| `it('works')` | `it('returns 401 for unauthenticated requests')` |
| `test_validation` | `test_place_order_fails_when_items_array_is_empty()` |

## Anti-Patterns

- `DatabaseTransactions` on tests that fire queue jobs with `onCommit` — jobs never fire.
- `Event::fake()` without asserting what was dispatched — useless mock.
- Factories that call `User::factory()->create()` inside other factory `definition()` — leads to cascading DB insertions in tests.
- Testing via `actingAs($user)` without specifying the guard (`'sanctum'`, `'web'`) — wrong guard silently fails.
- Using `$this->seed()` to set up every test — slow and fragile; use specific factories.
- Mocking the Eloquent model itself — test against the real DB.

## Safe Behavior

- Run `php artisan test --parallel` before every commit.
- Feature tests cover every HTTP status code path (200, 201, 401, 403, 404, 422).
- Every new endpoint has at least: unauthenticated, unauthorized, valid, invalid-input test cases.
- Faked facades (`Mail::fake()`, `Queue::fake()`) always have assertions after them — no silent ignoring.
- `RefreshDatabase` is default; override with `DatabaseTransactions` only when justified.
- A failing test blocks PR merge — no exceptions, no `$this->markTestSkipped()` without a tracked issue.
