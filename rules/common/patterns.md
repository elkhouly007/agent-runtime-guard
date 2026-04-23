---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Design Patterns — Common Rules

## When to Use Patterns

Patterns solve recurring problems — apply them when the problem they solve is present, not preemptively. Wait for the second use case before abstracting; wait for the third before reaching for a framework.

## High-Value Patterns

### Repository

Separate data access from business logic. The interface belongs to the domain; the implementation belongs to infrastructure.

```typescript
// BAD — business logic depends on the ORM directly
class OrderService {
  async getActive() {
    return prisma.order.findMany({ where: { status: "active" } }); // ORM leak
  }
}

// GOOD — interface in domain, implementation in infra
interface OrderRepo { findActive(): Promise<Order[]>; }
class PrismaOrderRepo implements OrderRepo {
  findActive() { return prisma.order.findMany({ where: { status: "active" } }); }
}
class OrderService { constructor(private repo: OrderRepo) {} }
```

When NOT to use: single-datasource CRUD apps with no testing requirement and no expected migration.

### Service Layer

Business logic lives in services, not controllers, routes, or UI components.

```typescript
// BAD — logic in the route handler
app.post("/checkout", async (req, res) => {
  const cart = await db.cart.findById(req.body.cartId);
  const total = cart.items.reduce((s, i) => s + i.price, 0);
  await db.order.create({ ...cart, total });
  await emailClient.send(req.body.email, "Order confirmed");
  res.json({ ok: true });
});

// GOOD — route delegates, service owns the logic
app.post("/checkout", async (req, res) => {
  const order = await checkoutService.checkout(req.body.cartId, req.body.email);
  res.json(order);
});
```

When NOT to use: pure CRUD operations with no business rules — a direct repo call from the controller is fine.

### Dependency Injection

Pass dependencies in; never construct them inside. Makes units testable without mocks of global state.

```typescript
// BAD — untestable; no way to swap the mailer
class UserService {
  async register(email: string) {
    const mailer = new SendGridMailer();   // hard-coded dependency
    await mailer.send(email, "Welcome");
  }
}

// GOOD — inject via constructor; swap in tests with a fake
class UserService {
  constructor(private mailer: Mailer) {}
  async register(email: string) { await this.mailer.send(email, "Welcome"); }
}
// In tests:
const svc = new UserService(new FakeMailer());
```

When NOT to use: pure functions and stateless utilities — they have no dependencies to inject.

### Builder

For constructing complex objects with many optional fields.

```typescript
// BAD — six-arg constructor; order matters; caller guesses
new Report(true, false, null, "pdf", 30, "admin");

// GOOD
const report = new ReportBuilder()
  .format("pdf")
  .ttlDays(30)
  .visibleTo("admin")
  .includeCharts()
  .build();
```

When NOT to use: objects with 1-2 fields — direct construction is cleaner.

### Strategy

Swap algorithms or behaviors at runtime without conditionals in the caller.

```typescript
// BAD — caller grows a new branch for every algorithm
function notify(user: User, channel: string) {
  if (channel === "email") { ... }
  else if (channel === "sms") { ... }
  else if (channel === "push") { ... }
}

// GOOD
interface Notifier { send(user: User, msg: string): Promise<void>; }
class NotificationService {
  constructor(private notifier: Notifier) {}
  notify(user: User, msg: string) { return this.notifier.send(user, msg); }
}
```

When NOT to use: only one algorithm exists and no variation is expected.

### Observer / Event System

Decouple producers from consumers. Producers emit; consumers subscribe.

```typescript
// BAD — OrderService directly calls every downstream system
class OrderService {
  async place(order: Order) {
    await inventoryService.decrement(order);
    await emailService.sendConfirmation(order);
    await analyticsService.track(order);
  }
}

// GOOD
class OrderService {
  async place(order: Order) {
    await this.repo.save(order);
    eventBus.emit("order.placed", order);  // zero direct coupling
  }
}
```

When NOT to use: the reaction is a hard business requirement (e.g., payment must succeed before order is confirmed) — use explicit orchestration instead of events.

### Adapter

Wrap third-party libraries behind your own interface so they can be replaced or mocked.

```typescript
// BAD — Stripe SDK referenced directly across 12 files
import Stripe from "stripe";
const stripe = new Stripe(process.env.STRIPE_KEY!);
await stripe.paymentIntents.create({ amount, currency: "usd" });

// GOOD — one adapter file; everything else uses PaymentGateway
interface PaymentGateway { charge(amountCents: number, currency: string): Promise<string>; }
class StripeAdapter implements PaymentGateway {
  private client = new Stripe(process.env.STRIPE_KEY!);
  charge(amountCents: number, currency: string) {
    return this.client.paymentIntents.create({ amount: amountCents, currency })
      .then(pi => pi.id);
  }
}
```

When NOT to use: you own and control the library and there is zero migration risk.

### Facade

Provide a simple interface to a complex subsystem.

```typescript
// BAD — caller must coordinate three services and know their internals
const user = await authService.getUser(token);
const prefs = await prefService.load(user.id);
const feed = await feedService.generate(user.id, prefs.topics, prefs.pageSize);

// GOOD — facade hides the coordination
const feed = await homePageFacade.getFeed(token);
```

When NOT to use: the subsystem is simple; adding a facade is pure indirection.

### Command

Encapsulate an operation as an object — enables undo/redo, queuing, logging.

When NOT to use: simple one-shot operations with no queuing, retry, or undo requirement.

## Anti-Patterns to Avoid

| Anti-pattern | Signal | Fix |
|---|---|---|
| God Object | Class named `*Manager`, `*Helper`, `*Utils` doing 10 things | Split by single responsibility |
| Premature Abstraction | Interface with one implementation, written "for future use" | Wait for the second use case |
| Anemic Domain Model | Domain objects are plain structs; all logic in services | Move behavior into the entity |
| Singleton Overuse | Global `getInstance()` passed everywhere implicitly | Replace with constructor injection |
| Pattern Cargo-Culting | Repository wrapping a repository | Apply only when the problem exists |
