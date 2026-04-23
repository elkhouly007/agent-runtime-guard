# PHP Design Patterns

PHP-specific patterns for clean architecture.

## Repository Pattern

Separate domain from persistence:

```php
interface UserRepository
{
    public function findById(int $id): ?User;
    public function save(User $user): void;
    public function delete(int $id): void;
}

final class EloquentUserRepository implements UserRepository
{
    public function findById(int $id): ?User
    {
        return UserModel::find($id)?->toDomain();
    }
}
```

## Service Layer

Encapsulate business logic in services, not controllers:

```php
final class RegisterUserService
{
    public function __construct(
        private readonly UserRepository $users,
        private readonly Mailer $mailer,
        private readonly PasswordHasher $hasher,
    ) {}

    public function execute(RegisterUserCommand $command): User
    {
        $user = new User(
            name: $command->name,
            email: new Email($command->email),
            password: $this->hasher->hash($command->password),
        );
        $this->users->save($user);
        $this->mailer->sendWelcome($user);
        return $user;
    }
}
```

## Value Objects

Wrap primitives in domain types:

```php
final readonly class Email
{
    public string $value;

    public function __construct(string $value)
    {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new \InvalidArgumentException("Invalid email: $value");
        }
        $this->value = strtolower($value);
    }
}
```

## Command/Query Separation

Commands mutate, queries return:

```php
// Command — void return
final class ActivateUserCommand { public function __construct(public readonly int $userId) {} }

// Query — returns data
final class GetUserByIdQuery { public function __construct(public readonly int $userId) {} }
```

## PHP 8 Enums

```php
enum OrderStatus: string
{
    case Pending  = 'pending';
    case Active   = 'active';
    case Closed   = 'closed';

    public function canTransitionTo(self $next): bool
    {
        return match($this) {
            self::Pending => $next === self::Active,
            self::Active  => $next === self::Closed,
            default       => false,
        };
    }
}
```
