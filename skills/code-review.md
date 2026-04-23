# Skill: code-review

# Code Review

Comprehensive code review that surfaces security vulnerabilities, logic errors, maintainability issues, and standard violations.

## When to Use

Use when reviewing any code change — PR review, pre-merge check, or ad-hoc quality review of a file or module. Delegates to the appropriate specialist agents based on language and concern.

## Overview

This skill orchestrates the right review agents for the code being reviewed. It applies language-specific rules, common security checks, and architectural review as appropriate.

## Process

1. Identify the language(s) and frameworks in the code to review.
2. Apply the relevant language reviewer (python-reviewer, typescript-reviewer, go-reviewer, etc.).
3. Apply security-reviewer for any security-sensitive paths (auth, crypto, I/O, external calls).
4. Apply code-reviewer for overall quality, naming, structure, and test coverage.
5. Report findings grouped by: Critical → High → Medium → Low → Suggestions.

## What Gets Checked

- **Security**: injection, auth bypass, secrets exposure, insecure crypto, OWASP concerns
- **Logic**: edge cases, null handling, error propagation, race conditions
- **Maintainability**: naming, function length, single responsibility, duplication
- **Tests**: coverage of changed code, assertion quality, missing edge cases
- **Standards**: language-specific rules from `rules/<lang>/`

## Output Format

```
## Review Summary
Severity counts: Critical: N, High: N, Medium: N, Low: N

## Findings
### [CRITICAL] Description
Location: file.ts:42
Issue: ...
Fix: ...

### [HIGH] ...
```

## Constraints

- Does not auto-fix. Reports findings; the developer makes changes.
- Does not review generated files, lock files, or binary assets.
- Does not enforce style preferences — only rule-backed standards.
