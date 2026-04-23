---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# PHP Security

PHP-specific security rules.

## SQL Injection

Always use PDO or MySQLi prepared statements:

```php
// BAD
$result = $db->query("SELECT * FROM users WHERE id = {$_GET['id']}");

// GOOD
$stmt = $pdo->prepare("SELECT * FROM users WHERE id = :id");
$stmt->execute([':id' => $id]);
```

## XSS Prevention

- `htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8')` for all output into HTML.
- Use a templating engine (Twig, Blade) with auto-escaping enabled.
- `Content-Security-Policy` headers. No `unsafe-inline` without hashing.

## CSRF Protection

- Every state-changing form requires a CSRF token.
- Use `hash_equals()` for token comparison to prevent timing attacks.
- Framework CSRF middleware (Laravel, Symfony) preferred over manual implementation.

## Command Injection

Never pass user input to shell commands:

```php
// BAD
exec("convert " . $_FILES['image']['tmp_name'] . " output.png");

// GOOD
$safe_path = escapeshellarg($validated_tmp_path);
exec("convert $safe_path output.png");
// Better: use a PHP library that doesn't shell out
```

## File Upload Security

- Validate MIME type server-side (not just extension or Content-Type header).
- Store uploads outside webroot or block execution via `.htaccess`/nginx config.
- Generate random filenames. Never use the original filename.

## Authentication

- Password hashing: `password_hash($password, PASSWORD_ARGON2ID)`.
- Verification: `password_verify($input, $hash)`.
- Session regeneration after login: `session_regenerate_id(true)`.

## Secrets

- `.env` files loaded via `vlucas/phpdotenv`. Never committed to git.
- Access via `$_ENV['KEY']` or `getenv('KEY')`, not hardcoded strings.
