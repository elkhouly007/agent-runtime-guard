# Python Security

Python-specific security rules. These extend the common security rules.

## Injection Prevention

- Always use parameterized queries. Never construct SQL strings with f-strings or % formatting.
- `subprocess.run()` with a list of arguments, never with `shell=True`. Shell=True evaluates the command string in a shell, enabling injection.
- `shlex.split()` or `shlex.quote()` when shell=True is unavoidable.
- Template rendering: use `jinja2.Environment(autoescape=True)` always. Manual escaping is error-prone.

## Deserialization Safety

- Never use `pickle.loads()` on untrusted data. Pickle execution runs arbitrary Python code during deserialization.
- `yaml.safe_load()` only. `yaml.load()` without `Loader=yaml.SafeLoader` allows arbitrary Python object construction.
- `json.loads()` is safe for data types. Validate the structure and types after parsing.
- Use marshmallow, pydantic, or cattrs for structured deserialization with validation.

## File System Safety

- Validate file paths before opening. Reject paths containing `../` or absolute paths when only relative paths are expected.
- Use `pathlib.Path` for path construction. Avoid string concatenation for paths.
- Set explicit file permissions when creating files with sensitive content (`mode=0o600`).
- Temporary files: use `tempfile.NamedTemporaryFile(delete=True)` for auto-cleanup.

## Cryptography

- Use `cryptography` library for all cryptographic operations. Do not use `hashlib` for password hashing.
- Password hashing: `bcrypt`, `argon2-cffi`, or `passlib`. Never SHA/MD5 for passwords.
- `secrets` module for cryptographically secure random values. Never `random` for security-sensitive values.
- Store secrets in environment variables or a secrets manager. Never in Python source files.

## Web Security (when applicable)

- CSRF protection enabled in all form-handling views.
- `Content-Security-Policy` headers configured.
- `Secure` and `HttpOnly` flags on all session cookies.
- Rate limiting on authentication endpoints.
