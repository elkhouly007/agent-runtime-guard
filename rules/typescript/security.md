---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# TypeScript Security

TypeScript-specific security rules extending the common rules.

## Input Validation and Parsing

- Parse and validate all external input with a schema library: zod, valibot, or class-validator.
- `JSON.parse()` can throw — always wrap in try/catch, then validate the parsed structure.
- Validate types at runtime at every API boundary. TypeScript types are compile-time only; they do not protect against malformed runtime data.
- Use zod `safeParse()` to get a typed result/error pair without throwing.

## XSS Prevention

- Never assign to `innerHTML`, `outerHTML`, or `document.write()` with user-provided data.
- Use `textContent` for text, DOM manipulation methods for structure.
- When HTML must be generated from user data, use DOMPurify to sanitize first.
- Content Security Policy headers to restrict script sources.

## Prototype Pollution

- Never use `Object.assign(target, userInput)` where `userInput` is unvalidated.
- `JSON.parse()` of `{"__proto__": {"polluted": true}}` pollutes Object.prototype in older Node.js.
- Use `Object.create(null)` for dictionary objects that should not inherit from Object.prototype.

## Dependency Security

- `npm audit` in CI. Fail the build on high-severity vulnerabilities.
- Lock file (`package-lock.json` or `yarn.lock`) committed to version control.
- Review dependency changes in PRs. Malicious packages have been introduced via dependency updates.
- Minimize production dependencies. Each dependency is an attack surface.

## Environment and Secrets

- Never import `.env` files in production code. Use environment variables.
- Never log `process.env` contents. Environment variables often contain secrets.
- `dotenv` is a development tool only. Configure production secrets through the deployment environment.
