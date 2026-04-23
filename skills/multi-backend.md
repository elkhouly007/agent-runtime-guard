# Skill: Multi-Backend

## Trigger

Command: `/multi-backend "feature"`

Use for backend features that require coordinated planning, test-first implementation, security review, and database review across a standard agent team. This is a pre-configured specialization of `/multi-plan` + `/multi-execute` for backend work.

Use this instead of a single agent when:
- The feature touches the database (new table, migration, query changes)
- The feature introduces or modifies authentication, authorization, or data access
- The feature is large enough that a single agent would exceed context limits
- You want TDD enforced from the start

Do not use for:
- Small bug fixes or single-function changes (delegate to `code-reviewer` or `python-reviewer` directly)
- Frontend-only work (use `/multi-frontend` instead)
- Tasks where the schema is already finalized and tests already exist (skip to implementation)

## Agent Team

| Agent | Role |
|-------|------|
| `architect` | Designs the data model, service structure, and API contract |
| `tdd-guide` | Writes failing tests based on the contract before implementation |
| `security-reviewer` | Audits the implementation for vulnerabilities in parallel |
| `database-reviewer` | Reviews migrations, queries, and schema changes |
| `code-reviewer` | Final quality review — logic, naming, structure, edge cases |

## Process

### Phase 1 — Design (sequential, architect only)

Assign `architect` to:
- Define the data model (entities, fields, relationships, constraints)
- Define the API contract (endpoints, request/response shapes, status codes, error cases)
- Identify migration requirements (new tables, altered columns, dropped constraints)
- Identify security requirements (who can call this, what data is exposed)

Output: a design document containing schema + API contract. This is the input to all subsequent phases.

Ahmed reviews Phase 1 output before Phase 2 begins if the schema change is irreversible.

### Phase 2 — Test Setup (sequential, requires Phase 1)

Assign `tdd-guide` to:
- Write failing unit tests for the service/model layer based on the Phase 1 contract
- Write failing integration tests for the API layer
- Confirm: 0 tests passing (all should fail — implementation does not exist yet)

Output: test files with failing tests. No implementation is written in this phase.

### Phase 3 — Implementation + Security Audit (parallel, requires Phase 2)

Run two agents simultaneously:

**Agent 1: implementation**
- Assign the language-appropriate agent (`python-reviewer`, `go-reviewer`, etc.) to implement the feature until all Phase 2 tests pass
- The agent works only against the Phase 1 contract and Phase 2 test suite — no scope expansion

**Agent 2: security-reviewer**
- Receives the Phase 1 design document and the partial implementation (or design alone if implementation is not yet complete)
- Audits for: injection vulnerabilities, auth bypass, data over-exposure, rate limiting gaps, insecure defaults

Output: implementation diff + security findings list. Security findings are not optional — they are a gate.

### Phase 4 — Review (parallel, requires Phase 3)

Run two agents simultaneously:

**Agent 1: database-reviewer**
- Reviews migration files for: irreversible operations, missing indexes, N+1 query risks, constraint safety, rollback feasibility

**Agent 2: code-reviewer**
- Reviews implementation for: logic correctness, edge case handling, error handling completeness, naming, docstrings, complexity

Output: two review reports. Any CRITICAL finding stops the pipeline.

### Phase 5 — Ahmed Approval Gate

Surface the merged report to Ahmed:
- Phase 1 design doc
- Phase 2 test count (failing as expected)
- Phase 3 implementation diff + security findings
- Phase 4 database review + code review findings

Ahmed approves before any files are written or migrations are applied.

## Example: "User Authentication" Feature

**Phase 1 — architect output:**
```
Schema:
  users table: id (UUID), email (unique), password_hash (bcrypt), created_at, updated_at
  sessions table: id (UUID), user_id (FK), token_hash, expires_at, created_at

API contract:
  POST /auth/register  → 201 {user_id, email} | 409 email taken | 422 validation error
  POST /auth/login     → 200 {token, expires_at} | 401 invalid credentials
  POST /auth/logout    → 204 | 401 unauthorized
  GET  /auth/me        → 200 {user_id, email} | 401 unauthorized

Security requirements:
  - Passwords hashed with bcrypt (cost factor >= 12)
  - Tokens are opaque random bytes (32 bytes, stored as hash)
  - Rate limit: 5 login attempts per IP per minute
```

**Phase 2 — tdd-guide output:**
```
test_auth.py: 18 tests written, 18 failing
  - test_register_success
  - test_register_duplicate_email
  - test_register_invalid_email_format
  - test_login_success
  - test_login_wrong_password
  - test_login_nonexistent_email
  - test_logout_valid_token
  - test_logout_invalid_token
  - test_get_me_authenticated
  - test_get_me_unauthenticated
  - ... (8 more)
```

**Phase 3 — security-reviewer findings:**
```
[CRITICAL] Token not invalidated on logout — sessions table not checked on /auth/me
[MAJOR]    No rate limiting implemented on /auth/login
[MINOR]    Error message reveals whether email exists (use generic "invalid credentials")
```

**Phase 4 — database-reviewer findings:**
```
[MAJOR]   Missing index on sessions.token_hash — O(n) lookup on every request
[MINOR]   sessions.expires_at has no DB-level NOT NULL constraint
[INFO]    Consider a partial index on sessions WHERE expires_at > NOW()
```

## Scoping to Avoid Context Explosion

- Each agent receives only the files it needs — not the full codebase
- `architect` receives: requirements + existing model files + existing migration list
- `tdd-guide` receives: Phase 1 design doc + test scaffold
- `security-reviewer` receives: Phase 1 design doc + implementation diff only
- `database-reviewer` receives: migration files + existing schema only
- `code-reviewer` receives: implementation diff + Phase 1 contract only

If any agent's context budget exceeds **Large** (>50k tokens), split the feature further before starting.

## Trigger Multi-Backend vs. Single Agent

| Situation | Use |
|-----------|-----|
| New endpoint, no DB changes, no auth | Single agent (`code-reviewer` or language reviewer) |
| New endpoint + new DB table | `/multi-backend` |
| Bug fix in existing service | Single agent |
| New service with auth, migrations, tests | `/multi-backend` |
| Refactor existing backend module | `/refactor` skill or single `code-reviewer` |
| Full feature spanning frontend + backend | `/multi-workflow` |

## Safe Behavior

- Phase 1 is read-only (design only, no writes).
- No files are written until Ahmed approves the Phase 5 report.
- Security findings from Phase 3 are a hard gate — CRITICAL findings block all writes.
- Migration files are never applied without explicit Ahmed approval.
