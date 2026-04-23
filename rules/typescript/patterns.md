---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# TypeScript Design Patterns

## React Patterns

### Component Composition
Prefer composition over large monolithic components.
```typescript
// Prefer: small focused components composed together
<Card>
  <CardHeader title="User" />
  <CardBody>
    <UserDetails user={user} />
  </CardBody>
  <CardFooter>
    <ActionButtons onSave={handleSave} />
  </CardFooter>
</Card>
```

### Custom Hooks for Logic Reuse
Extract stateful logic into custom hooks.
```typescript
function useUserData(userId: string) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    fetchUser(userId)
      .then(setUser)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [userId]);

  return { user, loading, error };
}
```

### Context for Cross-Cutting Concerns
Use context for theme, auth, locale — not for frequently-changing state.

## Node.js Patterns

### Repository Pattern
Separate data access from business logic.
```typescript
interface UserRepository {
  findById(id: UserId): Promise<User | null>;
  save(user: User): Promise<void>;
}
```

### Service Layer
Business logic lives in services, not controllers or routes.
```typescript
class UserService {
  constructor(private readonly repo: UserRepository) {}

  async activateUser(id: UserId): Promise<void> {
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundError(`User ${id} not found`);
    user.activate();
    await this.repo.save(user);
  }
}
```

### Middleware Pattern
Chain request processing steps — keep each middleware focused.

## General TypeScript

### Builder Pattern for Complex Objects
```typescript
class QueryBuilder {
  private filters: Filter[] = [];
  
  where(filter: Filter): this {
    this.filters.push(filter);
    return this;
  }
  
  build(): Query {
    return new Query(this.filters);
  }
}
```

### Result Type for Expected Failures
```typescript
type Result<T, E = Error> =
  | { ok: true; value: T }
  | { ok: false; error: E };
```
