# Skill: Laravel Architecture Patterns

## Trigger

Use when:
- Designing a new Laravel feature or module
- Reviewing code for architectural consistency
- Extracting logic from fat controllers or models
- Setting up service layers, repositories, or event-driven flows
- Building API responses or handling complex authorization

## Process

### 1. Service / Repository Pattern

Keep controllers thin. Business logic lives in Services; data access lives in Repositories.

```php
// app/Repositories/OrderRepository.php
namespace App\Repositories;

use App\Models\Order;
use Illuminate\Pagination\LengthAwarePaginator;

class OrderRepository
{
    public function findPendingForUser(int $userId): LengthAwarePaginator
    {
        return Order::query()
            ->where('user_id', $userId)
            ->where('status', 'pending')
            ->with(['lineItems', 'customer'])
            ->latest()
            ->paginate(20);
    }

    public function create(array $data): Order
    {
        return Order::create($data);
    }
}
```

```php
// app/Services/OrderService.php
namespace App\Services;

use App\Repositories\OrderRepository;
use App\Events\OrderPlaced;
use App\Models\Order;

class OrderService
{
    public function __construct(private OrderRepository $orders) {}

    public function placeOrder(int $userId, array $items): Order
    {
        $order = $this->orders->create([
            'user_id' => $userId,
            'status' => 'pending',
            'total' => $this->calculateTotal($items),
        ]);

        foreach ($items as $item) {
            $order->lineItems()->create($item);
        }

        event(new OrderPlaced($order));

        return $order;
    }

    private function calculateTotal(array $items): int
    {
        return collect($items)->sum(fn($item) => $item['price'] * $item['qty']);
    }
}
```

```php
// app/Http/Controllers/OrderController.php
class OrderController extends Controller
{
    public function __construct(private OrderService $orderService) {}

    public function store(PlaceOrderRequest $request): OrderResource
    {
        $order = $this->orderService->placeOrder(
            auth()->id(),
            $request->validated('items')
        );

        return new OrderResource($order);
    }
}
```

### 2. Form Requests for Validation

Never validate in the controller directly.

```php
// app/Http/Requests/PlaceOrderRequest.php
namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class PlaceOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()->can('place-orders');
    }

    public function rules(): array
    {
        return [
            'items' => ['required', 'array', 'min:1'],
            'items.*.product_id' => ['required', 'integer', 'exists:products,id'],
            'items.*.qty' => ['required', 'integer', 'min:1', 'max:100'],
            'items.*.price' => ['required', 'integer', 'min:1'],
            'delivery_address' => ['required', 'string', 'max:500'],
        ];
    }

    public function messages(): array
    {
        return [
            'items.required' => 'At least one item is required.',
            'items.*.product_id.exists' => 'Product :input does not exist.',
        ];
    }
}
```

### 3. Resource Classes for API Responses

```php
// app/Http/Resources/OrderResource.php
namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
            'total' => $this->total,
            'total_formatted' => number_format($this->total / 100, 2),
            'placed_at' => $this->created_at->toIso8601String(),
            'items' => LineItemResource::collection($this->whenLoaded('lineItems')),
            'customer' => new UserResource($this->whenLoaded('customer')),
        ];
    }
}

// Collection resource
class OrderCollection extends ResourceCollection
{
    public $collects = OrderResource::class;

    public function toArray($request): array
    {
        return [
            'data' => $this->collection,
            'meta' => [
                'total' => $this->total(),
                'per_page' => $this->perPage(),
            ],
        ];
    }
}
```

### 4. Event / Listener Pattern

```php
// app/Events/OrderPlaced.php
namespace App\Events;

use App\Models\Order;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OrderPlaced
{
    use Dispatchable, SerializesModels;

    public function __construct(public Order $order) {}
}
```

```php
// app/Listeners/SendOrderConfirmation.php
namespace App\Listeners;

use App\Events\OrderPlaced;
use App\Mail\OrderConfirmationMail;
use Illuminate\Support\Facades\Mail;

class SendOrderConfirmation
{
    public function handle(OrderPlaced $event): void
    {
        Mail::to($event->order->customer->email)
            ->queue(new OrderConfirmationMail($event->order));
    }
}
```

```php
// app/Providers/EventServiceProvider.php
protected $listen = [
    OrderPlaced::class => [
        SendOrderConfirmation::class,
        UpdateInventory::class,
        NotifyFulfillmentTeam::class,
    ],
];
```

### 5. Jobs and Queues

```php
// app/Jobs/GenerateInvoicePdf.php
namespace App\Jobs;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateInvoicePdf implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public int $backoff = 60;

    public function __construct(private Order $order) {}

    public function handle(PdfService $pdfService): void
    {
        $pdf = $pdfService->generate('invoices.template', ['order' => $this->order]);
        $this->order->invoice->update(['pdf_path' => $pdf->store('invoices')]);
    }

    public function failed(\Throwable $e): void
    {
        logger()->error("Invoice PDF failed for order {$this->order->id}", [
            'error' => $e->getMessage(),
        ]);
    }
}
```

Dispatch:
```php
GenerateInvoicePdf::dispatch($order)->onQueue('pdfs')->delay(now()->addSeconds(5));
```

### 6. Eloquent Relationships and Eager Loading

```php
// app/Models/Order.php
class Order extends Model
{
    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function lineItems(): HasMany
    {
        return $this->hasMany(LineItem::class);
    }

    public function invoice(): HasOne
    {
        return $this->hasOne(Invoice::class);
    }

    // Scope
    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', 'pending');
    }
}
```

Eager loading — always specify relations to avoid N+1:
```php
// Bad — N+1
$orders = Order::all();
foreach ($orders as $order) {
    echo $order->customer->name;  // N queries
}

// Good — 2 queries total
$orders = Order::with(['customer', 'lineItems'])->pending()->get();

// Conditional eager loading
$orders = Order::with([
    'lineItems' => fn($q) => $q->where('qty', '>', 0),
    'customer:id,name,email',   // select only needed columns
])->get();
```

### 7. Policies for Authorization

```php
// app/Policies/OrderPolicy.php
namespace App\Policies;

use App\Models\Order;
use App\Models\User;

class OrderPolicy
{
    public function view(User $user, Order $order): bool
    {
        return $user->id === $order->user_id || $user->hasRole('admin');
    }

    public function cancel(User $user, Order $order): bool
    {
        return $user->id === $order->user_id
            && $order->status === 'pending';
    }

    public function refund(User $user, Order $order): bool
    {
        return $user->hasPermissionTo('issue-refunds');
    }
}
```

```php
// In controller
public function cancel(Order $order): JsonResponse
{
    $this->authorize('cancel', $order);  // throws 403 if denied
    $this->orderService->cancel($order);
    return response()->json(['message' => 'Order cancelled.']);
}
```

### 8. Service Provider Registration

```php
// app/Providers/AppServiceProvider.php
use App\Repositories\OrderRepository;
use App\Services\OrderService;

public function register(): void
{
    $this->app->singleton(OrderRepository::class);
    $this->app->singleton(OrderService::class);

    // Bind interface to implementation
    $this->app->bind(
        \App\Contracts\PaymentGateway::class,
        \App\Services\StripePaymentGateway::class
    );
}
```

### 9. Facades vs Dependency Injection

| Approach | When to Use |
|----------|------------|
| Facade (`Mail::`, `Cache::`, `Event::`) | Quick one-liners in controllers/listeners |
| DI via constructor | Services, repositories — enables easy mocking in tests |
| `app()->make()` | Dynamic resolution in factories or non-DI contexts |

```php
// Facade — concise for simple cases
Cache::remember("orders.{$userId}", 300, fn() => Order::forUser($userId)->get());

// DI — preferred in services (testable without facades)
class OrderService
{
    public function __construct(
        private OrderRepository $orders,
        private CacheManager $cache,
    ) {}
}
```

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| Logic in controller | Hard to test, not reusable | Move to Service |
| `request()->validate()` in controller | Mixed concerns | Use Form Request |
| Raw arrays as API responses | Inconsistent shape | Use Resource classes |
| `Order::all()` without eager loading | N+1 queries | `with(['relation'])` |
| `User::find($id)` in Policy | Extra DB query | Rely on `$user` injected by policy |
| Synchronous heavy work in request cycle | Slow responses, timeouts | Dispatch a Job |
| Catching all exceptions in services | Swallows errors | Catch specific exceptions only |

## Safe Behavior

- Controllers call Services; Services call Repositories. No DB queries in controllers.
- All incoming data goes through Form Requests before reaching the Service.
- All API responses use Resource classes — never `toArray()` on models directly.
- Authorization is enforced via Policies, not ad-hoc `if ($user->id !== $order->user_id)`.
- Expensive operations (PDF, email, report generation) are dispatched as queued Jobs.
- Eager load all relationships listed in the Resource class before returning.
