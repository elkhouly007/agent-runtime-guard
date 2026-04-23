# Skill: Laravel Verification Loops

## Trigger

Use when:
- Completing a feature or bug fix before opening a PR
- Before deploying to staging or production
- After adding routes, migrations, or queue jobs
- Setting up CI for a Laravel project
- Diagnosing a production issue with queue workers or config cache

## Process

### 1. Run the Test Suite

```bash
# Standard run
php artisan test

# Parallel (faster on large suites)
php artisan test --parallel

# With coverage (requires XDEBUG_MODE=coverage or pcov)
XDEBUG_MODE=coverage php artisan test --coverage --min=85

# Pest
./vendor/bin/pest --parallel --coverage --min=85

# Filter to a specific test
php artisan test --filter OrderControllerTest
php artisan test --filter "test_place_order_creates_record"
```

### 2. PHPStan / Larastan Static Analysis

```bash
composer require --dev nunomaduro/larastan phpstan/phpstan
```

```neon
# phpstan.neon
includes:
    - vendor/nunomaduro/larastan/extension.neon

parameters:
    level: 8
    paths:
        - app
    excludePaths:
        - app/Http/Middleware/TrustProxies.php
    checkMissingIterableValueType: false
```

```bash
# Run analysis
./vendor/bin/phpstan analyse

# With memory limit
./vendor/bin/phpstan analyse --memory-limit=512M

# Generate baseline (suppress existing issues, track new ones only)
./vendor/bin/phpstan analyse --generate-baseline
```

### 3. Pint Code Style

```bash
composer require --dev laravel/pint
```

```bash
# Check only (CI)
./vendor/bin/pint --test

# Fix in place (local dev)
./vendor/bin/pint

# Check specific directory
./vendor/bin/pint app/Services --test
```

```json
// pint.json
{
    "preset": "laravel",
    "rules": {
        "ordered_imports": {"sort_algorithm": "alpha"},
        "no_unused_imports": true,
        "declare_strict_types": true
    }
}
```

### 4. Route List Checks

```bash
# List all registered routes
php artisan route:list

# Filter by method or path
php artisan route:list --method=POST
php artisan route:list --path=api/

# Check for duplicate or conflicting routes
php artisan route:list --json | jq '[.[] | {uri, method, name}] | group_by(.uri) | map(select(length > 1))'

# Verify a named route exists
php artisan route:list --name=orders.show
```

### 5. Config and Route Cache Validation

```bash
# Clear and rebuild caches (validate no errors)
php artisan config:clear && php artisan config:cache
php artisan route:clear && php artisan route:cache
php artisan view:clear && php artisan view:cache
php artisan event:clear && php artisan event:cache

# Or all at once
php artisan optimize

# Verify config values are resolved
php artisan config:show database
php artisan config:show cache
```

Watch for these cache errors:
- Closures in `config/` files — cannot be cached; use class references instead.
- Env calls outside `config/` — won't resolve after caching.

```php
// Wrong — env() in route file won't survive route:cache
Route::get('/admin', fn() => env('ADMIN_PATH'));

// Correct — use config()
Route::get('/admin', fn() => config('admin.path'));
```

### 6. Migration Status Checks

```bash
# Show migration status
php artisan migrate:status

# Check for pending migrations
php artisan migrate:status | grep -i "pending"

# Dry-run to see what would run
php artisan migrate --pretend

# Roll back last batch (staging only)
php artisan migrate:rollback --step=1 --pretend
```

Dangerous migration checklist before merging:
```bash
# Review migration file for table locks
cat database/migrations/$(ls -t database/migrations | head -1)

# Check for: ADD COLUMN NOT NULL without default on large table
# Check for: DROP COLUMN still referenced in code
# Check for: RENAME TABLE/COLUMN without backward compatibility
```

### 7. Queue Worker Health

```bash
# Check queue status (Laravel Horizon)
php artisan horizon:status

# Check jobs in queue
php artisan queue:monitor redis:default,redis:pdfs

# Retry failed jobs
php artisan queue:retry all

# Flush failed jobs
php artisan queue:flush

# Test a specific job inline
php artisan tinker
>>> dispatch(new App\Jobs\GenerateInvoicePdf(App\Models\Order::first()))
```

Supervisor config for queue workers:
```ini
; /etc/supervisor/conf.d/laravel-worker.conf
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=4
redirect_stderr=true
stdout_logfile=/var/www/storage/logs/worker.log
stopwaitsecs=3600
```

### 8. Horizon Monitoring

```bash
composer require laravel/horizon
php artisan horizon:install
php artisan migrate
```

```php
// config/horizon.php
'environments' => [
    'production' => [
        'supervisor-1' => [
            'maxProcesses' => 10,
            'balanceMaxShift' => 1,
            'balanceCooldown' => 3,
        ],
    ],
],
```

```bash
# Start Horizon
php artisan horizon

# Monitor throughput and wait times
# Dashboard: /horizon (protect with gate)
```

```php
// app/Providers/HorizonServiceProvider.php
Horizon::auth(function ($request) {
    return $request->user()?->hasRole('admin') ?? false;
});
```

### 9. Telescope for Debugging

```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate
```

Restrict Telescope to local/staging only:
```php
// TelescopeServiceProvider.php
public function register(): void
{
    Telescope::night();

    $this->hideSensitiveRequestDetails();
}

protected function gate(): void
{
    Gate::define('viewTelescope', function ($user) {
        return in_array($user->email, config('telescope.allowed_emails', []));
    });
}
```

Use Telescope to verify:
- Correct queries are being executed (no N+1)
- Jobs are being dispatched and completed
- Emails are queued (not synchronously sent)
- Cache hits/misses for expected keys

### 10. Full Pre-PR Verification Script

```bash
#!/bin/bash
set -e

echo "=== Code Style ==="
./vendor/bin/pint --test

echo "=== Static Analysis ==="
./vendor/bin/phpstan analyse --memory-limit=512M

echo "=== Tests ==="
php artisan test --parallel

echo "=== Route Cache ==="
php artisan route:cache && php artisan route:clear

echo "=== Config Cache ==="
php artisan config:cache && php artisan config:clear

echo "=== Migration Status ==="
php artisan migrate:status

echo "=== Security Audit ==="
composer audit

echo "=== All checks passed ==="
```

Save as `scripts/verify.sh`.

### 11. CI Integration (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_DATABASE: testing
          MYSQL_ROOT_PASSWORD: secret
        ports: ["3306:3306"]

    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: pdo_mysql, mbstring, pcov
          coverage: pcov

      - run: composer install --no-interaction --prefer-dist

      - name: Pint
        run: ./vendor/bin/pint --test

      - name: PHPStan
        run: ./vendor/bin/phpstan analyse

      - name: Tests with coverage
        run: php artisan test --parallel --coverage --min=85
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: secret

      - name: Composer audit
        run: composer audit
```

## Anti-Patterns

- Running `php artisan optimize` with closures in config files — breaks config cache silently.
- Not running `migrate:status` before deployment — finds migrations mid-deploy.
- Horizon/Telescope left accessible without auth gate in production — internal data exposure.
- Supervisor not set up for queue workers — jobs are lost on server restart.
- CI with no database service — tests pass with SQLite but fail on MySQL (type mismatches).
- Skipping `composer audit` in CI — shipping known vulnerable packages.

## Safe Behavior

- Every PR must pass the full verification script (pint + phpstan + tests + audit).
- `php artisan migrate:status` runs during the deployment pipeline — pending migrations are applied before traffic switches.
- Horizon is monitored; failed job count alerts fire if queue backlog exceeds threshold.
- Telescope is disabled (`TELESCOPE_ENABLED=false`) in production or gated to admin users only.
- Config and route caches are cleared and rebuilt after every deployment.
- Queue worker supervisor config is version-controlled and deployed alongside code.
