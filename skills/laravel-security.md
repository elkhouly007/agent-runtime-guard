# Skill: Laravel Security

## Trigger

Use when:
- Starting a new Laravel project or auditing an existing one
- Adding authentication, API endpoints, or file uploads
- Deploying to staging or production
- Reviewing code for security vulnerabilities
- Setting up security headers, rate limiting, or input validation

## Process

### 1. CSRF Protection

Laravel enables CSRF middleware globally on web routes. Never disable it.

```php
// app/Http/Kernel.php — web middleware group must contain:
\App\Http\Middleware\VerifyCsrfToken::class,
```

Blade forms must include the CSRF token:
```html
<form method="POST" action="/orders">
    @csrf
    ...
</form>
```

For API routes using Sanctum tokens, CSRF is not required (token-based auth). Do not add `VerifyCsrfToken` exceptions for web views.

### 2. XSS — Blade Escaping

Blade's `{{ }}` auto-escapes HTML. `{!! !!}` does NOT — treat it as injection.

```blade
{{-- Safe — HTML-escaped --}}
<p>{{ $user->bio }}</p>

{{-- UNSAFE — only acceptable for content you generated yourself --}}
<p>{!! $user->bio !!}</p>
```

If you must render user-submitted HTML (e.g., a rich text editor), sanitize first:
```bash
composer require ezyang/htmlpurifier
```

```php
use HTMLPurifier;
use HTMLPurifier_Config;

$config = HTMLPurifier_Config::createDefault();
$purifier = new HTMLPurifier($config);
$cleanHtml = $purifier->purify($userInput);
```

### 3. SQL Injection — Eloquent vs Raw Queries

| Pattern | Safe? |
|---------|-------|
| `User::where('email', $email)->first()` | Yes — parameterized |
| `DB::select('SELECT * FROM users WHERE email = ?', [$email])` | Yes — parameterized |
| `DB::statement("DELETE FROM users WHERE id = $id")` | NO — injection |
| `User::whereRaw("email = '$email'")` | NO — injection |
| `User::whereRaw('email = ?', [$email])` | Yes — parameterized |

```php
// Safe Eloquent
$user = User::where('email', $request->email)
            ->where('active', true)
            ->first();

// Safe raw when necessary
$results = DB::select(
    'SELECT id, total FROM orders WHERE user_id = ? AND status = ?',
    [$userId, $status]
);

// Safe whereRaw
Order::whereRaw('created_at > ? AND total > ?', [$since, $minTotal])->get();
```

### 4. Mass Assignment — $fillable and $guarded

Always define `$fillable` or `$guarded` on every model.

```php
// app/Models/User.php

// Explicit allowlist (preferred)
protected $fillable = ['name', 'email', 'password'];

// Or explicit denylist (deny specific fields)
protected $guarded = ['id', 'is_admin', 'role'];

// Never do this — allows all fields to be mass-assigned
protected $guarded = [];
```

```php
// Correct — validated data only
$user = User::create($request->validated());

// Wrong — raw request data, bypasses intent
$user = User::create($request->all());
```

### 5. Authentication — Sanctum and Passport

**Sanctum** (SPAs, mobile, simple tokens):
```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

```php
// app/Http/Kernel.php — api middleware group
\Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
```

```php
// Issue token
$token = $user->createToken('mobile-app', ['orders:read', 'orders:write'])->plainTextToken;

// Protect routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn(Request $r) => $r->user());
});

// Ability check
if ($request->user()->tokenCan('orders:write')) { ... }
```

**Passport** (full OAuth2 for third-party clients):
```bash
composer require laravel/passport
php artisan passport:install
```

### 6. Rate Limiting

```php
// app/Http/Kernel.php — or RouteServiceProvider
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Support\Facades\RateLimiter;

RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->user()?->id ?: $request->ip());
});

RateLimiter::for('login', function (Request $request) {
    return [
        Limit::perMinute(5)->by($request->input('email')),
        Limit::perMinute(20)->by($request->ip()),
    ];
});
```

Apply to routes:
```php
Route::middleware(['throttle:api'])->group(...);
Route::post('/login', ...)->middleware('throttle:login');
```

### 7. .env Secrets Management

```bash
# .env — never commit this file
APP_KEY=base64:...
DB_PASSWORD=super_secret
STRIPE_SECRET=sk_live_...
```

```php
// Access via config files, not env() directly in code
// config/services.php
'stripe' => [
    'secret' => env('STRIPE_SECRET'),
    'webhook_secret' => env('STRIPE_WEBHOOK_SECRET'),
],

// In code — always use config()
$secret = config('services.stripe.secret');
```

Generate a fresh key for each environment:
```bash
php artisan key:generate
```

Validate required env vars at boot:
```php
// AppServiceProvider::boot()
$required = ['APP_KEY', 'DB_PASSWORD', 'STRIPE_SECRET'];
foreach ($required as $key) {
    if (empty(env($key))) {
        throw new \RuntimeException("Required env var '$key' is missing.");
    }
}
```

### 8. Security Headers Middleware

```php
// app/Http/Middleware/SecurityHeaders.php
namespace App\Http\Middleware;

use Closure;

class SecurityHeaders
{
    public function handle($request, Closure $next)
    {
        $response = $next($request);

        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-XSS-Protection', '1; mode=block');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
        $response->headers->set(
            'Content-Security-Policy',
            "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'"
        );

        if (app()->environment('production')) {
            $response->headers->set(
                'Strict-Transport-Security',
                'max-age=31536000; includeSubDomains; preload'
            );
        }

        return $response;
    }
}
```

Register in `app/Http/Kernel.php`:
```php
protected $middleware = [
    \App\Http\Middleware\SecurityHeaders::class,
    ...
];
```

### 9. OWASP Top 10 Coverage Checklist

| OWASP Risk | Laravel Control |
|---|---|
| A01 Broken Access Control | Policies + `authorize()`, route middleware |
| A02 Cryptographic Failures | `bcrypt`/`argon2` passwords, HTTPS-only cookies |
| A03 Injection | Eloquent ORM, parameterized raw queries, `$fillable` |
| A04 Insecure Design | Form Requests, Service layer, no business logic in models |
| A05 Security Misconfiguration | `APP_DEBUG=false` prod, `.env` not committed |
| A06 Vulnerable Components | `composer audit` in CI |
| A07 Auth Failures | Sanctum, rate limiting on login, secure session config |
| A08 Software Integrity | Composer lock file committed, verify package signatures |
| A09 Logging Failures | Log auth failures, exceptions to Sentry/Loggly |
| A10 SSRF | Validate URLs, whitelist outbound domains |

```bash
# Check for vulnerable Composer packages
composer audit

# Or with Enlightn (Laravel-specific security scanner)
composer require enlightn/enlightn --dev
php artisan enlightn --report
```

## Anti-Patterns

| Anti-Pattern | Risk | Fix |
|---|---|---|
| `{!! $input !!}` on user data | XSS | Use `{{ }}` or purify first |
| `User::create($request->all())` | Mass assignment | `$request->validated()` |
| `DB::statement("... $var")` | SQL injection | Use `?` placeholders |
| `APP_DEBUG=true` in production | Stack trace exposure | Env-controlled, always false in prod |
| Storing secrets in `.env` committed to Git | Credential leak | Use secret managers (Vault, AWS Secrets Manager) |
| No rate limit on `/login` | Brute force | `throttle:login` middleware |
| Exposing Telescope/Horizon in production without auth | Internal data leak | Gate behind `auth` middleware |

## Safe Behavior

- Run `php artisan enlightn --report` before every production deployment.
- Run `composer audit` in CI on every PR.
- All models define `$fillable` — no model has `$guarded = []`.
- Every `{!! !!}` usage is reviewed and justified in a code comment.
- Secrets are never logged, never in responses, never in version control.
- Authentication routes always have `throttle` middleware applied.
- `APP_DEBUG` and `APP_ENV` are validated to be production-safe in the deployment pipeline.
