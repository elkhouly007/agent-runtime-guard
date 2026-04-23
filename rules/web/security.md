---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Web Frontend Security Rules

## Cross-Site Scripting (XSS)

- Never inject untrusted data into HTML without escaping — use your framework's template engine (React JSX, Vue template, Angular binding), which escapes by default.
- Never use `innerHTML`, `outerHTML`, or `document.write()` with user-controlled data.

```js
// BAD — direct innerHTML injection
element.innerHTML = userInput;

// GOOD — use textContent for text, or sanitize if HTML is required
element.textContent = userInput;

// If HTML is required, sanitize first
import DOMPurify from 'dompurify';
element.innerHTML = DOMPurify.sanitize(userInput);
```

- In React: never use `dangerouslySetInnerHTML` without sanitization.
- Sanitize rich text / markdown output with `DOMPurify` before rendering.
- Set `Content-Security-Policy` (CSP) header — see below.

## Content Security Policy (CSP)

- Set a strict CSP via HTTP response header (preferred) or `<meta http-equiv>`:

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';
  style-src 'self' 'nonce-{random}';
  img-src 'self' data: https:;
  connect-src 'self' https://api.yourdomain.com;
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
```

- Avoid `unsafe-inline` and `unsafe-eval` — use nonces or hashes for inline scripts.
- Do not use `*` in `script-src` or `default-src`.
- Use `frame-ancestors 'none'` (or `'self'`) to prevent clickjacking (replaces X-Frame-Options).
- Test your CSP with the [CSP Evaluator](https://csp-evaluator.withgoogle.com/).

## Cross-Site Request Forgery (CSRF)

- For cookie-based auth: use CSRF tokens (synchronizer token pattern or double-submit cookie).
- Prefer stateless auth (JWT in Authorization header) for SPAs — CSRF tokens are not needed because custom headers cannot be sent cross-origin without CORS preflight.
- Set `SameSite=Strict` or `SameSite=Lax` on session cookies.
- Never rely on `Origin` or `Referer` header alone for CSRF protection.

```http
Set-Cookie: session=...; HttpOnly; Secure; SameSite=Lax
```

## Sensitive Data Exposure

- Never store secrets, API keys, or credentials in frontend JavaScript — they are visible to anyone.
- Do not log sensitive user data (PII, tokens, passwords) to `console.*`.
- Treat `localStorage` and `sessionStorage` as untrusted — XSS can read them. Use HttpOnly cookies for session tokens.
- Mask sensitive fields in UI (passwords, card numbers, SSNs) — never display in plaintext after entry.

## Third-Party Scripts and Dependencies

- Audit npm dependencies: run `npm audit` in CI and fail on high/critical vulnerabilities.
- Use Subresource Integrity (SRI) for externally hosted scripts:

```html
<script src="https://cdn.example.com/lib.js"
        integrity="sha384-..."
        crossorigin="anonymous"></script>
```

- Minimize third-party script surface — every external script can exfiltrate data.
- Pin dependency versions (lockfile committed) — avoid floating `^` ranges for security-critical packages.

## URL and Redirect Safety

```js
// BAD — open redirect
window.location = userInput;

// GOOD — validate against allowlist
const ALLOWED_PATHS = ['/dashboard', '/profile', '/settings'];
if (ALLOWED_PATHS.includes(redirectPath)) {
    window.location = redirectPath;
}
```

- Validate redirect targets against an allowlist of known-good paths.
- Never construct URLs from user input without validation.
- Use `rel="noopener noreferrer"` on `target="_blank"` links.

## CORS Misconfiguration (Frontend Awareness)

- Do not set `withCredentials: true` on `fetch`/`axios` calls unless the API explicitly requires credentialed cross-origin requests.
- Never set `Access-Control-Allow-Origin: *` on APIs that use cookies — that is a backend concern but flag it in reviews.

## Security Headers (Reference Checklist)

Ensure the backend sets these for every HTML response:

| Header | Recommended value |
|---|---|
| `Content-Security-Policy` | (see above) |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` (or use CSP `frame-ancestors`) |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | restrict unused browser features |
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` |
