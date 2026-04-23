---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# PHP Testing Rules

## Framework

- Use **PHPUnit** for unit and integration tests — the standard PHP testing framework.
- Use **Pest PHP** as an alternative for a more expressive, Laravel-style syntax.
- Use **Mockery** for mocking (works with both PHPUnit and Pest).

```bash
composer require --dev phpunit/phpunit
composer require --dev pestphp/pest   # alternative
composer require --dev mockery/mockery
```

## Test Structure (PHPUnit)

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Services;

use App\Services\UserService;
use App\Repositories\UserRepository;
use PHPUnit\Framework\TestCase;
use PHPUnit\Framework\MockObject\MockObject;

class UserServiceTest extends TestCase
{
    private UserService $service;
    private UserRepository&MockObject $repository;

    protected function setUp(): void
    {
        $this->repository = $this->createMock(UserRepository::class);
        $this->service = new UserService($this->repository);
    }

    public function testFindsActiveUsers(): void
    {
        $this->repository
            ->expects($this->once())
            ->method('findWhere')
            ->with(['status' => 'active'])
            ->willReturn([['id' => 1, 'email' => 'alice@example.com']]);

        $result = $this->service->findActive();

        $this->assertCount(1, $result);
        $this->assertEquals('alice@example.com', $result[0]['email']);
    }

    public function testThrowsWhenUserNotFound(): void
    {
        $this->repository->method('findById')->willReturn(null);

        $this->expectException(\RuntimeException::class);
        $this->expectExceptionMessage('User not found');

        $this->service->getById(999);
    }
}
```

## Pest Syntax (Alternative)

```php
<?php

use App\Services\UserService;

beforeEach(function () {
    $this->repository = Mockery::mock(UserRepository::class);
    $this->service = new UserService($this->repository);
});

it('finds active users', function () {
    $this->repository
        ->shouldReceive('findWhere')
        ->with(['status' => 'active'])
        ->andReturn([['email' => 'alice@example.com']]);

    $result = $this->service->findActive();

    expect($result)->toHaveCount(1)
        ->and($result[0]['email'])->toBe('alice@example.com');
});

it('throws when user not found', function () {
    $this->repository->shouldReceive('findById')->andReturn(null);

    expect(fn() => $this->service->getById(999))
        ->toThrow(\RuntimeException::class, 'User not found');
});
```

## Test Organization

```
tests/
  Unit/           ← fast, no I/O, fully mocked dependencies
    Services/
      UserServiceTest.php
    Models/
  Integration/    ← hits real database or external services
    Repositories/
      UserRepositoryTest.php
  Feature/        ← full HTTP request/response cycle (Laravel)
    Http/
      UserControllerTest.php
```

- Unit tests mock all dependencies — no database, no filesystem, no HTTP.
- Integration tests use a real test database (separate from dev, reset between runs).
- Feature tests test full request lifecycle — use `RefreshDatabase` trait in Laravel.

## Mocking (PHPUnit)

```php
// Create mock
$mock = $this->createMock(InterfaceName::class);

// Set expectations
$mock->expects($this->once())      // called exactly once
     ->method('methodName')
     ->with($this->equalTo('arg')) // argument constraint
     ->willReturn('value');

// Stub (no call count verification)
$mock->method('getData')->willReturn([]);

// Stub with consecutive returns
$mock->method('next')
     ->willReturnOnConsecutiveCalls(1, 2, 3);
```

## Database Testing

```php
// Laravel — use RefreshDatabase to reset between tests
use Illuminate\Foundation\Testing\RefreshDatabase;

class UserRepositoryTest extends TestCase
{
    use RefreshDatabase;

    public function testStoresUser(): void
    {
        $user = User::factory()->create(['email' => 'test@example.com']);
        $found = $this->repository->findByEmail('test@example.com');
        $this->assertEquals($user->id, $found->id);
    }
}
```

## Coverage

```bash
# Generate coverage report (requires Xdebug or PCOV)
vendor/bin/phpunit --coverage-text
vendor/bin/phpunit --coverage-html coverage/

# With PCOV (faster than Xdebug)
php -d pcov.enabled=1 vendor/bin/phpunit --coverage-text
```

- Target: 80% line coverage minimum for service and repository layers.
- Enable coverage in CI — fail below threshold.
- Add `phpunit.xml` to version control with coverage thresholds configured:

```xml
<coverage>
    <report>
        <text outputFile="php://stdout" showUncoveredFiles="true"/>
    </report>
    <include>
        <directory suffix=".php">src</directory>
    </include>
</coverage>
```

## What Not to Test

- Don't test third-party library behavior (Eloquent, Doctrine, etc.).
- Don't test framework infrastructure (routing, middleware wiring) in unit tests — that's for feature tests.
- Don't test getters/setters that contain no logic.
