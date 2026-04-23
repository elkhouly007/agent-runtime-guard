---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# C# Security Rules

## OWASP Coverage Map

| OWASP Item | Section Below |
|------------|---------------|
| A01 Broken Access Control | Auth & Authorization |
| A02 Cryptographic Failures | Cryptography |
| A03 Injection | SQL / Command Injection, XSS |
| A04 Insecure Design | Deserialization, Validation |
| A05 Security Misconfiguration | ASP.NET Core Security, HTTPS |
| A06 Vulnerable Components | Dependencies |
| A07 Auth Failures | Auth & Authorization, JWT |
| A08 Software Integrity Failures | Deserialization, BinaryFormatter |
| A09 Logging Failures | Secrets, Logging |
| A10 SSRF | HTTP Clients, Input Validation |

---

## Input Validation

- Validate all inputs using Data Annotations (`[Required]`, `[MaxLength]`, `[Range]`, `[RegularExpression]`) or FluentValidation.
- Use model binding with validated DTOs in ASP.NET Core — never read raw `Request.Form` or `Request.QueryString` into domain objects.
- Call `ModelState.IsValid` before processing any controller action.
- Reject unexpected or oversized input early.

**BAD — no validation:**
```csharp
[HttpPost]
public IActionResult CreateUser(string name, string email) {
    // name could be "", email could be SQL injection
    _userService.Create(name, email);
    return Ok();
}
```

**GOOD — validated DTO:**
```csharp
public class CreateUserRequest {
    [Required, MaxLength(64)]
    public string Name { get; set; }

    [Required, EmailAddress]
    public string Email { get; set; }
}

[HttpPost]
public IActionResult CreateUser([FromBody] CreateUserRequest request) {
    if (!ModelState.IsValid) return BadRequest(ModelState);
    _userService.Create(request);
    return Ok();
}
```

---

## SQL Injection Prevention

**BAD — string interpolation in SQL:**
```csharp
var query = $"SELECT * FROM Users WHERE Name = '{name}'";
var users = context.Database.ExecuteSqlRaw(query);
```

**GOOD — parameterized query (ADO.NET):**
```csharp
var cmd = new SqlCommand("SELECT * FROM Users WHERE Name = @name", conn);
cmd.Parameters.AddWithValue("@name", name);
using var reader = cmd.ExecuteReader();
```

**GOOD — Entity Framework Core LINQ:**
```csharp
var users = context.Users.Where(u => u.Name == name).ToList();
```

**GOOD — FromSqlInterpolated (safe, uses parameters):**
```csharp
var users = context.Users
    .FromSqlInterpolated($"SELECT * FROM Users WHERE Name = {name}")
    .ToList();
```

**BAD — FromSqlRaw with string interpolation:**
```csharp
// NEVER do this — FromSqlRaw does not parameterize interpolated strings
var users = context.Users.FromSqlRaw($"SELECT * FROM Users WHERE Name = '{name}'").ToList();
```

---

## XSS Prevention (Razor / Blazor)

**BAD — unencoded output in Razor:**
```html
<!-- Razor view — dangerous -->
<p>@Html.Raw(userInput)</p>
```

**GOOD — auto-encoded output:**
```html
<!-- Razor auto-encodes by default -->
<p>@userInput</p>
```

**GOOD — Blazor auto-escapes:**
```razor
<!-- Blazor renders as text, not HTML, by default -->
<p>@userInput</p>
<!-- Use MarkupString only for trusted content -->
```

---

## Deserialization

- Never use `BinaryFormatter` — it is obsolete and allows remote code execution.
- Use `System.Text.Json` with explicit type mapping; avoid `Newtonsoft.Json` `TypeNameHandling.All`.
- If polymorphic deserialization is needed, use a discriminator field — never deserialize based on user-supplied type names.

**BAD — BinaryFormatter:**
```csharp
var formatter = new BinaryFormatter();
var obj = formatter.Deserialize(stream);  // RCE if stream is attacker-controlled
```

**BAD — Newtonsoft TypeNameHandling.All:**
```csharp
var settings = new JsonSerializerSettings {
    TypeNameHandling = TypeNameHandling.All  // lets attacker specify type → RCE
};
var obj = JsonConvert.DeserializeObject(json, settings);
```

**GOOD — System.Text.Json:**
```csharp
var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
var dto = JsonSerializer.Deserialize<CreateUserRequest>(json, options);
```

---

## Cryptography

- Password hashing: use `BCrypt.Net-Next` or `Microsoft.AspNetCore.Identity` (`PasswordHasher<T>`) — never MD5 or SHA-1.
- Random values: use `RandomNumberGenerator.GetBytes()` — not `System.Random`.
- AES: use AES-GCM (`AesGcm`) or AES-CBC with HMAC — never ECB mode.
- Do not implement custom cryptographic algorithms.

**BAD — MD5 for passwords:**
```csharp
using var md5 = MD5.Create();
var hash = BitConverter.ToString(md5.ComputeHash(Encoding.UTF8.GetBytes(password)));
```

**GOOD — BCrypt:**
```csharp
using BCrypt.Net;
string hash = BCrypt.HashPassword(password, workFactor: 12);
bool valid = BCrypt.Verify(rawPassword, hash);
```

**GOOD — secure random token:**
```csharp
var tokenBytes = RandomNumberGenerator.GetBytes(32);
var token = Convert.ToBase64String(tokenBytes);
```

**GOOD — AES-GCM encryption:**
```csharp
using var aesGcm = new AesGcm(key);
var nonce = RandomNumberGenerator.GetBytes(AesGcm.NonceByteSizes.MaxSize);
var ciphertext = new byte[plaintext.Length];
var tag = new byte[AesGcm.TagByteSizes.MaxSize];
aesGcm.Encrypt(nonce, plaintext, ciphertext, tag);
```

---

## Authentication and Authorization

- Use ASP.NET Core Identity or an external provider (Azure AD, Auth0) — do not roll your own auth.
- Apply `[Authorize]` at the controller level; use `[AllowAnonymous]` only for public endpoints.
- Use policy-based authorization (`AuthorizationPolicyBuilder`) for fine-grained access control.
- Validate JWTs with `Microsoft.AspNetCore.Authentication.JwtBearer`.

**GOOD — JWT validation in Startup:**
```csharp
services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.TokenValidationParameters = new TokenValidationParameters {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = config["Jwt:Issuer"],
            ValidAudience            = config["Jwt:Audience"],
            IssuerSigningKey         = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(config["Jwt:Secret"]))
        };
    });
```

---

## Open Redirect

**BAD — unvalidated redirect:**
```csharp
return Redirect(returnUrl);  // attacker passes "https://evil.com"
```

**GOOD — LocalRedirect (ASP.NET Core):**
```csharp
if (!Url.IsLocalUrl(returnUrl))
    return RedirectToAction("Index", "Home");
return LocalRedirect(returnUrl);  // throws if not local
```

---

## ASP.NET Core Security Configuration

- Enable anti-forgery (CSRF) tokens for form-based endpoints: `[ValidateAntiForgeryToken]`.
- Configure HTTPS redirection and HSTS (`app.UseHsts()`).
- Set security headers via middleware.
- Disable detailed error pages in production (`app.UseExceptionHandler`, not `app.UseDeveloperExceptionPage`).

**GOOD — security headers middleware:**
```csharp
app.Use(async (context, next) => {
    context.Response.Headers["X-Content-Type-Options"] = "nosniff";
    context.Response.Headers["X-Frame-Options"]        = "DENY";
    context.Response.Headers["Referrer-Policy"]        = "no-referrer";
    await next();
});
```

---

## Secrets Management

- Never commit secrets to source control — use `dotnet user-secrets` for local development.
- In production: use Azure Key Vault, AWS Secrets Manager, or environment variables.
- Read secrets from `IConfiguration` — never hardcode them.
- Fail fast if required secrets are missing (validate in `Startup`/`Program`).

**BAD — hardcoded secret:**
```csharp
private const string JwtSecret = "my-super-secret-key-12345";
```

**GOOD — from configuration:**
```csharp
var secret = config["Jwt:Secret"]
    ?? throw new InvalidOperationException("Jwt:Secret is required");
```

---

## File Operations

- Validate file paths using `Path.GetFullPath` and check they are within the allowed base directory.
- Validate file types by content (magic bytes), not just extension.
- Limit upload sizes via `[RequestSizeLimit]` or `MultipartBodyLengthLimit`.

**BAD — path traversal:**
```csharp
var path = Path.Combine("/uploads", filename);  // "../../etc/passwd"
return File(System.IO.File.ReadAllBytes(path), "application/octet-stream");
```

**GOOD — canonicalize and prefix-check:**
```csharp
var baseDir = Path.GetFullPath("/uploads");
var fullPath = Path.GetFullPath(Path.Combine(baseDir, filename));
if (!fullPath.StartsWith(baseDir + Path.DirectorySeparatorChar))
    return BadRequest("Invalid file path");
```

---

## Dependencies

- Run `dotnet list package --vulnerable` in CI to check for known vulnerabilities.
- Use `NuGet Audit` (built into .NET 8+) for automated vulnerability scanning.
- Keep ASP.NET Core, Entity Framework, and security libraries updated.

**Tooling commands:**
```bash
dotnet list package --vulnerable --include-transitive
dotnet build --no-incremental                    # full clean build
dotnet test --collect:"XPlat Code Coverage"      # tests with coverage
dotnet format                                     # code style
```

---

## Anti-Patterns Table

| Anti-Pattern | Why It's Dangerous | Fix |
|-------------|-------------------|-----|
| `BinaryFormatter.Deserialize` | Remote code execution | Use `System.Text.Json` |
| `TypeNameHandling.All` in Newtonsoft | Gadget-chain RCE | Use explicit type mapping |
| `$"... {userInput}"` in SQL | SQL injection | EF LINQ or `SqlParameter` |
| `Html.Raw(userInput)` | XSS | Use `@userInput` (auto-encoded) |
| `System.Random` for tokens | Predictable | Use `RandomNumberGenerator` |
| MD5/SHA-1 for passwords | Trivially cracked | BCrypt cost ≥ 10 |
| `Redirect(returnUrl)` unvalidated | Open redirect | `LocalRedirect` + `Url.IsLocalUrl` |
| Secrets in `appsettings.json` in repo | Credential exposure | Use Key Vault / env vars |
| `app.UseDeveloperExceptionPage()` in prod | Stack trace leakage | Use `UseExceptionHandler` in prod |
| `[AllowAnonymous]` on sensitive endpoints | Bypasses auth | Remove; require explicit authorization |
