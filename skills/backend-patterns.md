# Skill: Backend Patterns

## Trigger

Use when designing or reviewing backend service architecture: API layer structure, database access patterns, caching strategy, background job design, or service communication.

## API Layer

### Request Handling Pattern

```
Request → Validation → Auth → Handler → Service → Repository → DB
```

- Validate inputs at the boundary (controller/handler) — not deep in service logic.
- Keep controllers thin: parse request, call service, return response. No business logic.
- Services contain business logic. They do not know about HTTP.
- Repositories abstract database access. They do not contain business logic.

```typescript
// Controller — thin
async function createUser(req: Request, res: Response) {
    const dto = await validateBody(CreateUserSchema, req.body); // validate + parse
    const user = await userService.create(dto);                 // delegate
    res.status(201).json({ data: user });
}

// Service — business logic
async function createUser(dto: CreateUserDto): Promise<User> {
    if (await userRepo.existsByEmail(dto.email)) {
        throw new ConflictError('Email already registered');
    }
    const hash = await bcrypt.hash(dto.password, 12);
    return userRepo.create({ ...dto, password: hash });
}

// Repository — data access only
async function existsByEmail(email: string): Promise<boolean> {
    return db.users.exists({ where: { email } });
}
```

## Database Access

### Connection Pooling

- Always use a connection pool — never open a raw connection per request.
- Size the pool: `max = db_max_connections - headroom_for_admin`. Typical: 10-20 for web servers.
- Set a `connection_timeout` — fail fast if the pool is exhausted rather than queueing indefinitely.

### Query Patterns

```typescript
// BAD — N+1 query
const users = await getUsers();
for (const user of users) {
    user.orders = await getOrdersByUser(user.id); // N queries
}

// GOOD — single query with JOIN or include
const users = await db.users.findMany({
    include: { orders: true }
});

// BAD — loading full entities when only IDs needed
const users = await db.users.findMany(); // loads 100 columns
const ids = users.map(u => u.id);

// GOOD — select only what you need
const ids = await db.users.findMany({ select: { id: true } });
```

### Transactions

```typescript
// Wrap atomic multi-step operations
await db.$transaction(async (tx) => {
    const order = await tx.orders.create({ data: orderData });
    await tx.inventory.decrement({ where: { sku: item.sku }, qty: item.qty });
    await tx.payments.create({ data: { orderId: order.id, amount } });
});
// If any step throws, all steps are rolled back
```

## Caching

### Cache Strategy Decision Tree

```
Is data user-specific?
  → Yes: use per-user cache key (e.g., cache:user:{id}:profile)
  → No: use shared key (e.g., cache:products:featured)

How often does the data change?
  → Rarely: long TTL (1h+), invalidate on write
  → Frequently: short TTL (60s) or skip cache
  → Never: permanent cache, invalidate on deploy
```

### Cache-Aside Pattern (most common)

```typescript
async function getProduct(id: string): Promise<Product> {
    const cached = await redis.get(`product:${id}`);
    if (cached) return JSON.parse(cached);

    const product = await db.products.findUnique({ where: { id } });
    if (!product) throw new NotFoundError();

    await redis.setex(`product:${id}`, 3600, JSON.stringify(product)); // 1h TTL
    return product;
}

// Invalidate on update
async function updateProduct(id: string, data: UpdateProductDto) {
    const product = await db.products.update({ where: { id }, data });
    await redis.del(`product:${id}`); // invalidate
    return product;
}
```

- Never cache error responses.
- Always serialize/deserialize explicitly — don't store complex objects with circular refs.
- Use Redis for distributed caches; use in-memory (Map/LRU cache) only for single-instance, non-critical data.

## Background Jobs

### When to use a queue vs. inline

| Use queue when | Do inline when |
|---|---|
| Task can fail and needs retry | Task is fast and failure is acceptable |
| Task is slow (>200ms) | Task must complete before HTTP response |
| Task is a side effect (email, webhook) | Task is part of the core operation |
| Task workload is spiky | Load is steady |

### Job Design

```typescript
// Job payload — keep it small, include only IDs
interface SendWelcomeEmailJob {
    userId: string; // fetch fresh data in the job, don't embed a snapshot
}

// Job handler
async function handleSendWelcomeEmail(job: Job<SendWelcomeEmailJob>) {
    const user = await userRepo.findById(job.data.userId);
    if (!user) return; // user deleted — treat as stale job, discard
    await emailService.sendWelcome(user);
}
```

- Jobs are idempotent — re-running them must not cause duplicate side effects.
- Check for stale data at the start of a job — the world changes between enqueue and execution.
- Set a max retry count and a dead-letter queue for failed jobs.

## Service Communication

- Synchronous (HTTP/gRPC): use for requests that need an immediate response.
- Async (queue/event): use for side effects, notifications, and cross-service state propagation.
- Always set timeouts on outbound HTTP calls — never let a downstream service cause your service to hang.
- Use circuit breakers for critical external dependencies.
