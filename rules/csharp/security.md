# C# Security

C#-specific security rules.

## SQL Injection

- Entity Framework and Dapper with parameterized queries. Never string-concatenated SQL.
- EF Core raw SQL: `FromSqlInterpolated()` is safe (uses parameterized queries). `FromSqlRaw()` requires manual parameterization.
- Dapper: always use `@parameter` placeholders, never string formatting.

## ASP.NET Security

- HTTPS enforced: `app.UseHttpsRedirection()` in production.
- HSTS: `app.UseHsts()` in production.
- CORS: configure explicitly with specific origins. Never `AllowAnyOrigin()` in production.
- CSRF: `[ValidateAntiForgeryToken]` on all form-handling POST endpoints.
- Rate limiting: `AddRateLimiter` middleware for authentication endpoints.
- Cookie security: `Secure = true`, `HttpOnly = true`, `SameSite = Strict`.

## Authentication

- ASP.NET Core Identity for user management. Do not implement auth from scratch.
- `BCrypt.Net` or `Argon2` for password hashing. `SHA256` is not a password hash.
- JWT validation: verify signature, expiry, issuer, and audience. Never `ValidateLifetime = false`.

## Dependency Injection Security

- Never register per-request state in a singleton service. This causes state leakage between requests.
- Scoped services should not be captured in background services (IHostedService) — lifetime mismatch causes data sharing.

## Secrets

- `IConfiguration` with secrets.json for development. Azure Key Vault or AWS Secrets Manager for production.
- Never deploy `appsettings.Production.json` with real secrets to source control.
- `dotnet user-secrets` for development-time secrets (stored outside the project directory).
