---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# PHP Security Rules

## SQL Injection

```php
// BAD — direct interpolation
$query = "SELECT * FROM users WHERE email = '$email'";
$result = $db->query($query);

// GOOD — PDO prepared statements
$stmt = $pdo->prepare("SELECT * FROM users WHERE email = :email");
$stmt->execute([':email' => $email]);
$user = $stmt->fetch();

// GOOD — with named bindings
$stmt = $pdo->prepare("UPDATE users SET status = :status WHERE id = :id");
$stmt->bindValue(':status', $status, PDO::PARAM_STR);
$stmt->bindValue(':id', $id, PDO::PARAM_INT);
$stmt->execute();
```

- Always use PDO or MySQLi prepared statements — never string-concatenate user input into queries.
- Use `PDO::PARAM_INT` for integers, `PDO::PARAM_STR` for strings — type-binding prevents coercion attacks.
- Set PDO error mode to exceptions: `$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION)`.

## Cross-Site Scripting (XSS)

```php
// BAD — raw output
echo $_GET['name'];
echo "<p>Hello, $name</p>";

// GOOD — escape before output
echo htmlspecialchars($_GET['name'], ENT_QUOTES | ENT_HTML5, 'UTF-8');

// GOOD — in templates (Twig auto-escapes by default)
// {{ user.name }}     ← safe in Twig
// {{ user.html|raw }} ← ONLY when content is verified safe

// Blade (Laravel) — {{ }} escapes, {!! !!} does NOT
echo e($name);  // helper: htmlspecialchars wrapper
```

- Use `htmlspecialchars()` with `ENT_QUOTES | ENT_HTML5` and UTF-8 for all user-supplied output.
- Use a template engine with auto-escaping (Twig, Blade) — never raw PHP templates for user-facing output.
- Set the `Content-Type: text/html; charset=UTF-8` header to prevent charset-based XSS.

## CSRF Protection

```php
// Generate token and store in session
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));

// In form
echo '<input type="hidden" name="csrf_token" value="' . htmlspecialchars($_SESSION['csrf_token']) . '">';

// On POST — validate
if (!hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'] ?? '')) {
    http_response_code(403);
    exit('Invalid CSRF token');
}
```

- Use `hash_equals()` (timing-safe comparison) not `===` for token comparison.
- Generate tokens with `random_bytes()` — not `rand()` or `uniqid()`.
- Laravel/Symfony handle CSRF automatically — use the framework's built-in protection.

## Password Handling

```php
// BAD — MD5, SHA1, plain text
$hash = md5($password);

// GOOD — bcrypt via password_hash
$hash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

// Verify
if (password_verify($inputPassword, $storedHash)) {
    // authenticated
}

// Argon2id (PHP 7.3+ — preferred)
$hash = password_hash($password, PASSWORD_ARGON2ID);
```

- Never use MD5, SHA1, or SHA256 for passwords — they are fast hash functions, not password hashes.
- Use `PASSWORD_ARGON2ID` (preferred) or `PASSWORD_BCRYPT` — both are bcrypt/Argon2-based.
- Use `password_needs_rehash()` to upgrade old hashes on login.

## File Upload Security

```php
// Validate MIME type (not just extension)
$finfo = new finfo(FILEINFO_MIME_TYPE);
$mimeType = $finfo->file($_FILES['upload']['tmp_name']);

$allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
if (!in_array($mimeType, $allowedTypes, true)) {
    throw new \RuntimeException('Invalid file type');
}

// Generate safe filename — never use user-provided name
$extension = match($mimeType) {
    'image/jpeg' => 'jpg',
    'image/png'  => 'png',
    'image/gif'  => 'gif',
};
$filename = bin2hex(random_bytes(16)) . '.' . $extension;
$uploadPath = '/var/uploads/' . $filename;

// Move file
move_uploaded_file($_FILES['upload']['tmp_name'], $uploadPath);
```

- Never trust `$_FILES['upload']['type']` — it is user-controlled.
- Always validate MIME type from the file content (`finfo`), not the extension.
- Never serve uploaded files from a web-accessible directory without proper access control.
- Store uploads outside the document root when possible.

## Session Security

```php
// Secure session configuration
ini_set('session.cookie_httponly', '1');
ini_set('session.cookie_secure', '1');     // HTTPS only
ini_set('session.cookie_samesite', 'Lax');
ini_set('session.use_strict_mode', '1');
session_start();

// Regenerate session ID on privilege change
session_regenerate_id(true);  // true = delete old session
```

## Input Validation

```php
// Use filter_var for common validations
$email = filter_var($_POST['email'], FILTER_VALIDATE_EMAIL);
$url   = filter_var($_POST['url'],   FILTER_VALIDATE_URL);
$int   = filter_var($_POST['age'],   FILTER_VALIDATE_INT, ['options' => ['min_range' => 0, 'max_range' => 150]]);

if ($email === false) {
    throw new \InvalidArgumentException('Invalid email');
}
```

## Dependency Security

```bash
# Check for known vulnerabilities
composer audit

# Update to fix vulnerabilities
composer update
```

- Run `composer audit` in CI — block merges on HIGH/CRITICAL findings.
- Pin exact versions in `composer.lock` — `composer install` for production deploys (not `update`).
- Avoid abandoned packages — check Packagist for `abandoned` flag.
