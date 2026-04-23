# Skill: nestjs-patterns

## Purpose

Apply NestJS best practices — module structure, dependency injection, guards, pipes, interceptors, and testing for Node.js/TypeScript backend services.

## Trigger

- Starting or reviewing a NestJS project
- Implementing controllers, services, or modules
- Asked about NestJS DI, guards, pipes, or decorators

## Trigger

`/nestjs-patterns` or `apply nestjs patterns to [target]`

## Agents

- `typescript-reviewer` — TypeScript quality and patterns
- `security-reviewer` — API security

## Patterns

### Module Structure

```
src/
├── app.module.ts
├── config/
│   └── config.module.ts          # ConfigModule.forRoot(...)
├── auth/
│   ├── auth.module.ts
│   ├── auth.controller.ts
│   ├── auth.service.ts
│   ├── guards/jwt.guard.ts
│   └── strategies/jwt.strategy.ts
└── orders/
    ├── orders.module.ts
    ├── orders.controller.ts
    ├── orders.service.ts
    ├── dto/create-order.dto.ts
    └── entities/order.entity.ts
```

- One module per domain feature. Export only what other modules need.

### Controllers — Thin

```typescript
@Controller('orders')
@UseGuards(JwtAuthGuard)
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post()
  create(@Body() dto: CreateOrderDto, @CurrentUser() user: User) {
    return this.ordersService.create(dto, user);
  }
}
```

### DTOs and Validation

```typescript
import { IsString, IsInt, Min } from 'class-validator';

export class CreateOrderDto {
  @IsString()
  productId: string;

  @IsInt()
  @Min(1)
  quantity: number;
}
```

- Use `ValidationPipe` globally: `app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }))`.
- `whitelist: true` strips unknown properties. `forbidNonWhitelisted: true` rejects requests with unknown fields.

### Guards and Auth

```typescript
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
```

- Apply `JwtAuthGuard` at the controller or route level — or globally with `APP_GUARD`.
- Use `@Public()` decorator pattern to opt-out of global guard for public endpoints.

### Configuration

```typescript
@Injectable()
export class AppConfig {
  constructor(private configService: ConfigService) {}

  get dbUrl(): string {
    return this.configService.getOrThrow<string>('DATABASE_URL');
  }
}
```

- Use `@nestjs/config` with `ConfigService.getOrThrow` — fail fast at startup if required vars are missing.
- Never use `process.env` directly in services.

### Testing

```typescript
describe('OrdersService', () => {
  let service: OrdersService;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [OrdersService, { provide: OrdersRepository, useValue: mockRepo }],
    }).compile();
    service = module.get(OrdersService);
  });
});
```

- Use `Test.createTestingModule` for unit tests with mocked providers.
- Use `@nestjs/testing` + supertest for e2e tests.

## Safe Behavior

- Analysis only unless asked to modify code.
- Follow `rules/typescript/coding-style.md` and `rules/typescript/security.md`.
