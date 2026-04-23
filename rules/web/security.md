# Web Security

Security rules for web applications.

## Content Security Policy

Set a strict CSP header on every response:

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{random}';
  style-src 'self' 'nonce-{random}';
  img-src 'self' data: https:;
  connect-src 'self' https://api.example.com;
  frame-ancestors 'none';
```

- No `unsafe-inline` in `script-src`. Use nonces.
- Enforce via `Content-Security-Policy`, not just `Content-Security-Policy-Report-Only` in production.

## XSS Prevention

- Escape all dynamic content before insertion into HTML.
- Use `textContent` not `innerHTML` for inserting user data into the DOM.
- Framework output is escaped by default — never use `dangerouslySetInnerHTML` (React) or `[innerHTML]` (Angular) with user data.
- Sanitize HTML with DOMPurify when rich text must be rendered.

## CSRF Protection

- Same-site cookies: `SameSite=Lax` at minimum, `SameSite=Strict` where feasible.
- CSRF token for state-changing API calls from HTML forms.
- Verify `Origin` or `Referer` header server-side for sensitive actions.

## Authentication Headers

- `X-Frame-Options: DENY` (or `frame-ancestors 'none'` in CSP) to prevent clickjacking.
- `X-Content-Type-Options: nosniff` to prevent MIME-type sniffing.
- `Strict-Transport-Security: max-age=31536000; includeSubDomains` (HTTPS-only).
- `Referrer-Policy: strict-origin-when-cross-origin`.

## Secrets in Frontend Code

- No API keys in client-side JavaScript. They are public.
- All secret operations through a backend proxy.
- Environment variables prefixed `NEXT_PUBLIC_` / `VITE_` are bundled into client code — only put public values there.

## Third-Party Scripts

- Subresource Integrity (SRI) hashes on CDN-loaded scripts.
- Audit third-party scripts — they run in the same origin with full DOM access.
- Minimize third-party scripts loaded on authenticated pages.
