---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Security

Universal security principles that apply to all code regardless of language or framework.

## Input Validation

- Validate all external input at the system boundary. External means: user input, HTTP requests, file content, database reads, environment variables, command-line arguments, inter-process communication.
- Validate type, format, length, and range. Reject inputs that fail validation — do not sanitize and proceed.
- Allowlists over denylists. Specifying what is allowed is safer than specifying what is forbidden.
- Never trust input that claims to come from a trusted source without verification.

## Authentication and Authorization

- Authentication: prove who the caller is.
- Authorization: verify the caller is permitted to perform this action on this resource.
- Never skip authorization checks because a caller is "internal." Internal services are compromised too.
- Fail closed: when authorization cannot be determined, deny access. Never fail open.
- Principle of least privilege: grant only the permissions required for the specific task.

## Secrets Management

- Never hardcode secrets, credentials, or API keys in source code.
- Never log secrets, credentials, or tokens — in any format, at any log level.
- Store secrets in a secrets manager (environment variables are acceptable for development only).
- Rotate credentials regularly. Design systems so rotation does not require downtime.
- Audit every place a secret is used. Each use is a potential exposure point.

## Cryptography

- Never implement cryptographic algorithms from scratch. Use well-reviewed library implementations.
- Use current standards: AES-256-GCM for symmetric encryption, RSA-4096 or ECDSA P-256 for asymmetric, bcrypt/argon2/scrypt for password hashing, SHA-256+ for general hashing.
- Never use MD5 or SHA-1 for security purposes.
- Authenticated encryption (AEAD) over encryption alone — ciphertext without authentication can be manipulated.

## Error Handling

- Never expose internal error details to external callers. Distinguish between internal error messages (for logs) and external error messages (for API responses).
- Log all security-relevant events: failed authentications, authorization denials, input validation failures.
- Do not reveal whether a username exists in a "wrong password" error. Return the same message for both.

## Dependency Security

- Track all third-party dependencies. Know what version each uses.
- Monitor for known vulnerabilities in dependencies. Use automated tools (dependabot, snyk, safety).
- Pin dependency versions in production. Unpinned dependencies can introduce vulnerabilities between deploys.
- Minimize third-party dependencies. Each dependency is a trust decision.
