# Skill: Security Review

## Trigger

Use when:
- Auditing a codebase for vulnerabilities
- Reviewing authentication, authorization, or session management changes
- Responding to a security report or incident
- Before releasing code that handles user data, payments, or external APIs

## Process

### 1. Delegate to security-reviewer agent
Start with `security-reviewer` for OWASP Top 10 analysis. Provide:
- The file(s) or diff to analyze
- The language/framework
- The context (public-facing? authenticated? handles PII?)

### 2. Dependency audit
```bash
# Node.js
npm audit --audit-level=moderate

# Python
pip audit
# or: safety check -r requirements.txt

# Go
go list -m -json all | nancy sleuth
# or: govulncheck ./...

# Rust
cargo audit

# Java / Maven
mvn dependency-check:check

# Ruby
bundle audit check --update
```

Flag any HIGH or CRITICAL CVEs. Moderate CVEs need context before dismissing.

### 3. Secrets scan
```bash
# Quick grep (adjust patterns as needed)
grep -rn \
  -e "password\s*=" \
  -e "api_key\s*=" \
  -e "secret\s*=" \
  -e "token\s*=" \
  -e "BEGIN.*PRIVATE KEY" \
  -e "AKIA[0-9A-Z]{16}" \
  --include="*.{js,ts,py,go,java,yaml,yml,json,env,config}" \
  .

# Better: use trufflehog or gitleaks if available
trufflehog filesystem . 2>/dev/null
gitleaks detect --source . 2>/dev/null
```

### 4. OWASP Top 10 checklist

| # | Category | What to check |
|---|----------|---------------|
| A01 | Broken Access Control | Auth checks on every route, IDOR, privilege escalation paths |
| A02 | Cryptographic Failures | Hashing (bcrypt/argon2, not MD5/SHA1), TLS, data at rest |
| A03 | Injection | SQL, NoSQL, command, LDAP, XPath — parameterized queries? |
| A04 | Insecure Design | Missing rate limits, no abuse cases considered |
| A05 | Security Misconfiguration | Debug mode, default creds, error messages leaking internals |
| A06 | Vulnerable Components | CVEs in dependencies (step 2 covers this) |
| A07 | Auth/Session | Session fixation, weak tokens, missing logout invalidation |
| A08 | Data Integrity | Unsigned JWTs, deserialization of untrusted data |
| A09 | Logging Failures | No audit log, PII in logs, missing security event logs |
| A10 | SSRF | User-controlled URLs, missing allowlist for outbound requests |

### 5. Language-specific rules
Apply `rules/common/security.md` plus `rules/<language>/security.md` for the primary language.

### 6. Classify all findings by severity

| Severity | Definition |
|----------|------------|
| CRITICAL | Exploitable now, high impact (RCE, auth bypass, data dump) |
| HIGH | Likely exploitable, significant impact |
| MEDIUM | Exploitable under specific conditions, moderate impact |
| LOW | Defense-in-depth issues, hardening improvements |
| INFO | Best practices, not a current vulnerability |

## Output Format

```
## Security Review — [scope]

### Dependency Audit
- X vulnerabilities: Y CRITICAL, Z HIGH, W MODERATE
- [CVE-XXXX-XXXX] package@version — description — fix: upgrade to version

### Secrets Scan
- PASS / FAIL — details if any found

### OWASP Analysis

#### CRITICAL: [Vulnerability Title] — file.py:88
**Type:** SQL Injection / Auth Bypass / etc.
**Location:** function_name() in file.py:88
**Exploitation scenario:** Attacker can...
**Fix:**
```code example with parameterized query / correct implementation```

#### HIGH: ...

### Overall Security Posture
[Brief assessment: good / needs work / critical action required]
```

## Escalation

**Any CRITICAL finding in production code → flag to Ahmed immediately.** Do not wait for a scheduled review cycle.

## Safe Behavior

- Read-only analysis.
- No automated patching without explicit instruction.
- Does not commit or push any changes.
- Does not run exploit code — analysis only.
- Personal data discovered during review stays in the report, is not echoed externally.
