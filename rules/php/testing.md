# PHP Testing

PHP-specific testing standards.

## Framework

- PHPUnit for all unit and integration tests.
- Pest as a modern alternative with fluent syntax.
- Mockery or PHPUnit mocks for dependency isolation.
- `php artisan test` (Laravel) or `vendor/bin/phpunit` for running tests.

## Test Structure

```php
<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Service\UserService;
use PHPUnit\Framework\TestCase;

final class UserServiceTest extends TestCase
{
    private UserService $service;

    protected function setUp(): void
    {
        $this->service = new UserService(
            repository: $this->createMock(UserRepository::class),
        );
    }

    public function test_creates_user_with_valid_data(): void
    {
        $user = $this->service->create('Alice', 'alice@example.com');

        $this->assertSame('Alice', $user->name);
    }

    public function test_throws_when_email_is_invalid(): void
    {
        $this->expectException(ValidationException::class);

        $this->service->create('Alice', 'not-an-email');
    }
}
```

## Naming

- Test classes: `{Class}Test` in `tests/Unit/` or `tests/Feature/`.
- Test methods: `test_verb_condition_expectation()` or `it_does_something()` with Pest.
- Data providers: `provide_invalid_emails()` returning arrays of cases.

## Data Providers

```php
#[DataProvider('provideInvalidEmails')]
public function test_rejects_invalid_email(string $email): void
{
    $this->expectException(ValidationException::class);
    new EmailAddress($email);
}

public static function provideInvalidEmails(): array
{
    return [
        'empty string' => [''],
        'no at sign'   => ['notanemail'],
        'no domain'    => ['user@'],
    ];
}
```

## Coverage

- `phpunit --coverage-html coverage/` for HTML reports.
- Target 80%+ for domain and service classes.
- 100% for critical security and validation paths.
