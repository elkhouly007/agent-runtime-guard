---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# PHP Coding Style

## Standard

Follow **PSR-12** (Extended Coding Style) — the community standard for PHP 7.4+. Use PHP-CS-Fixer or PHP_CodeSniffer to enforce it automatically.

```bash
# PHP-CS-Fixer
composer require --dev friendsofphp/php-cs-fixer
vendor/bin/php-cs-fixer fix src/ --rules=@PSR12

# PHP_CodeSniffer
composer require --dev squizlabs/php_codesniffer
vendor/bin/phpcs src/ --standard=PSR12
```

## Naming Conventions

```php
// Classes — PascalCase
class UserRepository {}
class OrderService {}

// Methods and functions — camelCase
public function findByEmail(string $email): ?User {}
function formatCurrency(float $amount): string {}

// Variables — camelCase
$userId = 42;
$orderItems = [];

// Constants — UPPER_SNAKE_CASE
const MAX_RETRY_COUNT = 3;
define('APP_VERSION', '2.0.0');

// Properties — camelCase, typed
private string $email;
protected int $retryCount = 0;
```

## Type Declarations

Always use type declarations — PHP 8.0+ supports union types, named arguments, and `mixed`.

```php
// BAD — no types
function getUser($id) {
    return User::find($id);
}

// GOOD — fully typed
function getUser(int $id): ?User {
    return User::find($id);
}

// GOOD — union types (PHP 8.0+)
function process(int|string $id): User|null {
    // ...
}

// GOOD — readonly properties (PHP 8.1+)
class UserDto {
    public function __construct(
        public readonly int $id,
        public readonly string $email,
    ) {}
}
```

- Never use `mixed` unless genuinely unavoidable — it disables type checking.
- Use `nullable` (`?Type`) over `Type|null` for simple cases.
- Enable strict mode in every file: `declare(strict_types=1);`

## File Structure

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use App\Repositories\UserRepository;
use Psr\Log\LoggerInterface;

class UserService
{
    public function __construct(
        private readonly UserRepository $repository,
        private readonly LoggerInterface $logger,
    ) {}

    public function findActive(): array
    {
        return $this->repository->findWhere(['status' => 'active']);
    }
}
```

- One class per file.
- File name must match class name exactly.
- `declare(strict_types=1)` must be the first statement after `<?php`.
- Imports ordered: built-in extensions, then vendor packages, then local namespaces.

## Modern PHP Features

```php
// Named arguments (PHP 8.0+) — self-documenting calls
$user = User::create(
    email: 'alice@example.com',
    role: 'admin',
    active: true,
);

// Match expression (PHP 8.0+) — exhaustive, no fallthrough
$label = match($status) {
    'active'  => 'Active',
    'pending' => 'Pending Review',
    'banned'  => 'Banned',
    default   => throw new \InvalidArgumentException("Unknown status: $status"),
};

// Nullsafe operator (PHP 8.0+)
$city = $user?->getAddress()?->getCity();

// Fibers (PHP 8.1+) — cooperative concurrency
$fiber = new Fiber(function(): void {
    $value = Fiber::suspend('hello');
});
```

## Formatting

- 4-space indentation (not tabs).
- Opening brace for classes and methods on the same line (PSR-12).
- No trailing whitespace.
- Blank line between method definitions.
- Line length: soft limit 120 chars, hard limit 160 chars.

## Composer and Autoloading

- Use Composer autoloading (`psr-4`) — never `require` or `include` manually.
- Keep `composer.lock` in version control for reproducible installs.
- Separate `require` (production) from `require-dev` (development tools).
