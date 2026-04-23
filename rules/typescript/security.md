---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# TypeScript Security Rules

## Input Validation

- Validate **all** API request bodies, query params, path params, and headers with Zod or equivalent.
- Never trust `req.body`, `req.query`, or `req.params` directly — parse and validate first.
- Use Zod `.safeParse()` to avoid thrown exceptions from malformed input.
- Validate at the **system boundary** — once, explicitly — not scattered throughout the call chain.

```typescript
// Good
const schema = z.object({ email: z.string().email(), age: z.number().int().min(0) });
const result = schema.safeParse(req.body);
if (!result.success) return res.status(400).json({ error: result.error.flatten() });

// Bad
const { email, age } = req.body;  // no validation
```

## XSS Prevention

- Never build HTML strings with user data — use framework templating (React JSX, etc.).
- In React: never use `dangerouslySetInnerHTML` with user-supplied content.
- If rich text is required: sanitize with `DOMPurify` before rendering.
- Use `textContent` not `innerHTML` for plain text DOM manipulation.
- Set `Content-Security-Policy` headers on the server.

## SQL Injection

- Use parameterized queries or ORM query builders — never string interpolation in SQL.
- Validate sort/filter column names against an explicit allowlist.

```typescript
// Good — parameterized
const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

// Bad — interpolated
const user = await db.query(`SELECT * FROM users WHERE id = ${userId}`);
```

## CSRF Protection

- Use `SameSite=Strict` or `SameSite=Lax` on session cookies.
- For state-mutating endpoints (POST/PUT/DELETE) that use cookie auth: require a CSRF token header.
- Stateless JWT in `Authorization: Bearer` header is CSRF-safe by design.
- Do not accept both cookie auth and header auth on the same endpoint without CSRF protection.

## Authentication & Sessions

- Store session tokens in `httpOnly`, `SameSite=Strict` cookies — not `localStorage` or `sessionStorage`.
- `localStorage` is accessible to JavaScript — any XSS can steal it.
- Validate JWTs on the server — do not trust claims without cryptographic verification.
- Check `iss`, `aud`, `exp`, and `nbf` fields on every JWT validation.
- Do not implement custom crypto — use `jose`, `jsonwebtoken`, or `@auth/core`.
- Invalidate sessions server-side on logout — client-side token deletion is not sufficient.
- Rotate refresh tokens on use. Detect reuse (revoke entire session if reuse detected).

## Rate Limiting

- Rate-limit all public authentication endpoints (login, register, forgot-password, OTP).
- Rate-limit by IP and by account identifier separately.
- Use `express-rate-limit`, `upstash/ratelimit`, or equivalent.

```typescript
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 min
  max: 10,                    // 10 attempts per window
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/auth/login', limiter);
```

## Secrets Management

- No secrets in TypeScript/JavaScript source files — ever.
- No secrets in environment variables committed to source control.
- Validate env vars at startup with a Zod schema — fail fast if required vars are missing.
- `.env` files must be in `.gitignore`.
- In production: use a secrets manager (Vault, AWS Secrets Manager, Doppler).

```typescript
// Validate env at startup
const env = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  NODE_ENV: z.enum(['development', 'production', 'test']),
}).parse(process.env);
```

## Dependencies

- Run `npm audit` in CI — fail the build on HIGH or CRITICAL CVEs.
- Pin exact versions in production (`package-lock.json` committed, use `npm ci`).
- Review `npm audit fix --force` changes before applying — they may introduce breaking changes.
- Regularly update dependencies — stale deps accumulate CVEs.

## Node.js Specific

- Never pass user input to `child_process.exec()`, `eval()`, `new Function()`, or `vm.runInContext()`.
- Use `path.resolve()` and validate against a base directory before any file I/O with user-supplied paths.
- Set security headers with `helmet` on Express/Fastify apps.
- Disable `x-powered-by` header: `app.disable('x-powered-by')`.
- Never expose stack traces or internal error details to API clients in production.

```typescript
// Path traversal prevention
const safePath = path.resolve('/allowed/base', userInput);
if (!safePath.startsWith('/allowed/base')) {
  throw new Error('Path traversal attempt');
}
```

## TypeScript-Specific

- `unknown` over `any` — force explicit type narrowing at boundaries.
- Use strict mode: `"strict": true` in `tsconfig.json`.
- `as` casts are a code smell at API boundaries — validate with Zod instead of casting.
- Avoid `@ts-ignore` — fix the underlying type issue.
