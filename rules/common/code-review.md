---
last_reviewed: 2026-04-22
version_target: "Best Practices"
---

# Code Review Standards

## Purpose

Code review ensures quality, security, and maintainability before code is merged. This rule defines when and how to conduct code reviews.

## When to Review

**MANDATORY review triggers:**

- After writing or modifying code
- Before any commit to shared branches
- When security-sensitive code is changed (auth, payments, user data)
- When architectural changes are made
- Before merging pull requests

**Pre-Review Requirements:**

Before requesting review, ensure:

- All automated checks (CI/CD) are passing
- Merge conflicts are resolved
- Branch is up to date with target branch

## Review Checklist

Before marking code complete:

- [ ] Code is readable and well-named
- [ ] Functions are focused (<50 lines unless clearly justified)
- [ ] Files are cohesive (<800 lines unless generated or framework-driven)
- [ ] No deep nesting (>4 levels) without strong reason
- [ ] Errors are handled explicitly
- [ ] No hardcoded secrets or credentials
- [ ] No console.log or stray debug statements
- [ ] Tests exist for new functionality
- [ ] Coverage is appropriate for the change and risk level

## Security Review Triggers

**STOP and use `security-reviewer` when:**

- Authentication or authorization code
- User input handling
- Database queries
- File system operations
- External API calls
- Cryptographic operations
- Payment or financial code

## Review Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| CRITICAL | Security vulnerability or data loss risk | **BLOCK** - Must fix before merge |
| HIGH | Bug or significant quality issue | **WARN** - Should fix before merge |
| MEDIUM | Maintainability concern | **INFO** - Consider fixing |
| LOW | Style or minor suggestion | **NOTE** - Optional |

## Agent Usage

Use these agents for code review:

| Agent | Purpose |
|-------|---------|
| **code-reviewer** | General code quality, patterns, best practices |
| **security-reviewer** | Security vulnerabilities, OWASP Top 10 |
| **typescript-reviewer** | TypeScript/JavaScript specific issues |
| **python-reviewer** | Python specific issues |
| **go-reviewer** | Go specific issues |
| **rust-reviewer** | Rust specific issues |
| **java-reviewer** | Java specific issues |
| **kotlin-reviewer** | Kotlin specific issues |
| **cpp-reviewer** | C/C++ specific issues |
| **csharp-reviewer** | C# specific issues |
| **flutter-reviewer** | Flutter and Dart specific issues |

## Review Workflow

```text
1. Run git diff to understand changes
2. Check security checklist first
3. Review code quality checklist
4. Run relevant tests
5. Verify the claimed behavior actually works
6. Use the appropriate agent for detailed review when needed
```

## Common Issues to Catch

### Security

- Hardcoded credentials (API keys, passwords, tokens)
- SQL injection (string concatenation in queries)
- XSS vulnerabilities (unescaped user input)
- Path traversal (unsanitized file paths)
- CSRF protection missing
- Authentication bypasses

### Code Quality

- Large functions (>50 lines), split into smaller units when practical
- Large files (>800 lines), extract modules where cohesion is weak
- Deep nesting (>4 levels), prefer guard clauses and early returns
- Missing error handling, handle explicitly
- Mutation-heavy code, prefer clearer immutable or isolated state transitions
- Missing tests, add coverage for critical paths

### Performance

- N+1 queries, use JOINs or batching
- Missing pagination, add bounds to list endpoints
- Unbounded queries, add limits and filters
- Missing caching where repeated expensive work is obvious

## Approval Criteria

- **Approve**: No CRITICAL or HIGH issues
- **Warning**: Only HIGH issues remain and are explicitly accepted
- **Block**: CRITICAL issues found, or unverified risky behavior remains

## Integration with Other Rules

This rule works with:

- [testing.md](testing.md) - test and verification requirements
- [security.md](security.md) - security checklist
- [git-workflow.md](git-workflow.md) - commit standards
- [agents.md](agents.md) - agent delegation guidance
