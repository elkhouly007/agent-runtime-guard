# PHP Coding Style

PHP-specific standards following PSR-12.

## Standards

- PSR-12 for code style. Enforced with PHP_CodeSniffer or PHP-CS-Fixer in CI.
- PSR-4 autoloading. One class per file. Namespace mirrors directory structure.
- Strict types declaration in every file:

```php
<?php

declare(strict_types=1);

namespace App\Service;
```

## Naming

- Classes and interfaces: `PascalCase`
- Methods and properties: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private/protected: no underscore prefix (PSR convention)
- Interfaces: suffixed with `Interface` or described as a noun (`UserRepository`, not `IUserRepository`)

## Type Declarations

Use strict typing everywhere:

```php
public function findById(int $id): ?User
{
    // ...
}

public function createUser(string $name, string $email): User
{
    // ...
}
```

- Return types on all methods. `void` if nothing returned.
- Nullable types (`?Type`) over mixed or untyped returns.
- Typed properties (PHP 7.4+).

## Error Handling

- Throw exceptions for error conditions. Never return `false` or `null` to signal errors.
- Custom exception hierarchy: `AppException > DomainException > SpecificException`.
- Catch specific exceptions, not `\Exception` or `\Throwable` unless at boundary.

```php
try {
    $user = $this->repository->findOrFail($id);
} catch (UserNotFoundException $e) {
    throw new HttpNotFoundException("User $id not found", previous: $e);
}
```

## Modern PHP

- PHP 8.1+: enums, fibers, readonly properties, intersection types.
- Named arguments for clarity in calls with many parameters.
- Match expressions over switch where a value is returned.
- Constructor property promotion.
