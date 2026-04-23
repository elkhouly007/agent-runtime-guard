---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Security — Common Rules

These security rules apply across all languages and projects.

## OWASP Top 10 Coverage Map

| OWASP Item                        | Section Below              |
|-----------------------------------|----------------------------|
| A01 Broken Access Control         | Authentication & Authorization |
| A02 Cryptographic Failures        | Data Protection            |
| A03 Injection                     | Injection Prevention       |
| A04 Insecure Design               | Input Validation           |
| A05 Security Misconfiguration     | Least Privilege            |
| A06 Vulnerable Components         | Dependencies               |
| A07 Auth Failures                 | Authentication & Authorization |
| A08 Software Integrity Failures   | Dependencies               |
| A09 Logging Failures              | Logging and Monitoring     |
| A10 SSRF                          | Injection Prevention       |

---

## Input Validation

- Validate all inputs at system boundaries: HTTP requests, file reads, database results, CLI args, env vars.
- Reject invalid input early — do not attempt to sanitize and continue unless sanitization is provably safe.
- Use allowlists, not denylists.

**BAD — denylist, bypassable:**
```python
def is_safe(filename):
    return ".." not in filename  # bypassed with encoded paths
```

**GOOD — allowlist, explicit:**
```python
import re
SAFE_FILENAME = re.compile(r'^[a-zA-Z0-9_\-]+\.(csv|json)$')
def is_safe(filename):
    return bool(SAFE_FILENAME.match(filename))
```

## Authentication and Authorization

- Authentication verifies identity. Authorization verifies permission. Both are required on every request.
- Never skip authorization checks because a user is "trusted" or "internal."
- Session tokens must be invalidated on logout.
- Re-authenticate for sensitive operations (password change, payment, account deletion).

**BAD — authorization skipped for admin routes:**
```js
app.delete('/user/:id', (req, res) => {
  if (req.user.role === 'admin') deleteUser(req.params.id); // no ownership check
});
```

**GOOD — explicit ownership + role check:**
```js
app.delete('/user/:id', requireAuth, async (req, res) => {
  const allowed = req.user.role === 'admin' || req.user.id === req.params.id;
  if (!allowed) return res.status(403).json({ error: 'Forbidden' });
  await deleteUser(req.params.id);
});
```

## Secrets and Credentials

- No secrets in source code, ever.
- No secrets in log output or error messages returned to users.
- Use environment variables or a secrets manager (Vault, AWS Secrets Manager).
- Rotate secrets immediately if ever exposed.

**BAD:**
```python
DB_PASSWORD = "hunter2"  # committed to git
```

**GOOD:**
```python
import os
DB_PASSWORD = os.environ["DB_PASSWORD"]  # injected at runtime
```

## Data Protection

- Encrypt sensitive data at rest (AES-256 or better).
- Use TLS 1.2+ for all data in transit — reject older versions.
- Use bcrypt, argon2, or scrypt for passwords. Never MD5 or SHA1.
- Store PII only where necessary; delete it when no longer needed.

**BAD:**
```python
import hashlib
pw_hash = hashlib.md5(password.encode()).hexdigest()
```

**GOOD:**
```python
import bcrypt
pw_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
```

## Injection Prevention

- Parameterize all database queries — never build SQL with string concatenation.
- Escape all output rendered in HTML — use your framework's templating engine.
- Validate and restrict file paths before any file operation.
- Never pass user input to shell commands.

**BAD — SQL injection:**
```python
query = f"SELECT * FROM users WHERE email = '{email}'"
cursor.execute(query)
```

**GOOD — parameterized:**
```python
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
```

**BAD — XSS:**
```js
div.innerHTML = userInput;
```

**GOOD:**
```js
div.textContent = userInput;  // or use DOMPurify for rich HTML
```

## Dependencies

- Keep dependencies up to date; audit for known vulnerabilities.
- Pin versions in production — avoid floating ranges (`^`, `~`, `*`).
- Review the impact of updates before applying.

**Audit commands:**
```bash
npm audit --audit-level=high          # Node.js
pip-audit                             # Python (pip install pip-audit)
govulncheck ./...                     # Go
trivy fs --exit-code 1 .              # multi-ecosystem container/fs scan
```

## Least Privilege

- Database users have only the permissions they need (SELECT only for read-only services).
- Application processes run as non-root.
- API keys and tokens have only the required scopes.
- File permissions are as restrictive as possible (`chmod 600` for secrets).

## Logging and Monitoring

- Log: auth failures, authorization failures, high-risk operations (delete, payment, privilege change).
- Never log: passwords, tokens, session IDs, full PII.
- Set alerts for anomalous patterns (failed login spikes, sudden error rate increase).

**BAD:**
```python
logger.info(f"Login attempt: user={email} password={password}")
```

**GOOD:**
```python
logger.info("Login attempt", extra={"user": email, "success": False})
```

## Anti-Patterns

| Anti-Pattern                         | Why It's Dangerous                        | Correct Approach                    |
|--------------------------------------|-------------------------------------------|-------------------------------------|
| String-concatenated SQL              | SQL injection                             | Parameterized queries               |
| `eval(userInput)`                    | Remote code execution                     | Never eval untrusted input          |
| Hardcoded secrets                    | Credential exposure in git history        | Env vars / secrets manager          |
| MD5/SHA1 for passwords               | Rainbow table attacks                     | bcrypt / argon2                     |
| Returning raw DB errors to users     | Schema / path disclosure                  | Generic error messages              |
| Catching all exceptions silently     | Masks auth/security errors                | Log and re-raise appropriately      |
| `chmod 777` on files                 | World-writable attack surface             | Minimum necessary permissions       |
| Disabling TLS cert verification      | MITM attacks                              | Fix certs; never disable validation |
