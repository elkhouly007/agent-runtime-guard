# Skill: Plankton Write-Time Code Quality Enforcement

## Trigger

Use when configuring, authoring, or reviewing Plankton hooks in Claude Code — write-time linting that runs as a `PostToolUse` hook after every file write, enforcing code quality rules before the file is committed or even saved to disk as a final version.

## What Plankton Is

Plankton is a **write-time linter** that integrates with Claude Code's hook system. Unlike CI linters that catch issues after a push, Plankton runs immediately after Claude writes a file, giving the agent (and the user) instant feedback in the same turn.

Key properties:
- Runs as a `PostToolUse` hook on `Write` and `Edit` tool calls.
- Reads the written file, applies configured rules, and returns violations as structured output.
- Blocking (`error`) violations stop the task and require the agent to fix the file before proceeding.
- Non-blocking (`warning`) violations are surfaced as comments in the output but do not halt execution.
- Rules are defined in JSON — no compilation step.

## Pre-Configuration Checklist

Before setting up Plankton:
- [ ] Confirm Claude Code version supports `PostToolUse` hooks (v1.5+).
- [ ] Identify which rule violations should be blockers (errors) vs. suggestions (warnings).
- [ ] Decide on per-file bypass patterns (test files, generated files, config files).
- [ ] Understand that CI linters remain the source of truth — Plankton is a fast inner loop, not a replacement.

## Process

### 1. Hook configuration in settings.json

Plankton is registered as a `PostToolUse` hook in `.claude/settings.json` (project-level) or `~/.claude/settings.json` (global).

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "plankton check --file $CLAUDE_TOOL_OUTPUT_FILE --config .plankton.json",
            "blocking": true,
            "timeout": 10000
          }
        ]
      }
    ]
  }
}
```

`$CLAUDE_TOOL_OUTPUT_FILE` is an environment variable Claude Code injects — it is the path of the file just written or edited.

`blocking: true` means if Plankton exits with a non-zero code, Claude Code sees the violation and must address it before continuing.

### 2. Plankton config file — .plankton.json

```json
{
  "version": 1,
  "rules": [
    {
      "id": "no-console-log",
      "severity": "error",
      "pattern": "console\\.log\\(",
      "message": "console.log() must not appear in production code. Use the logger utility instead.",
      "fileTypes": ["ts", "tsx", "js", "jsx"],
      "bypass": ["**/*.test.*", "**/*.spec.*", "**/scripts/**"]
    },
    {
      "id": "no-todo-in-prod",
      "severity": "warning",
      "pattern": "//\\s*TODO(?!.*\\[TICKET-\\d+\\])",
      "message": "TODO comments must reference a ticket: // TODO [TICKET-123] description",
      "fileTypes": ["ts", "tsx", "js", "jsx", "swift", "py", "go"]
    },
    {
      "id": "require-error-handling",
      "severity": "error",
      "pattern": "await\\s+\\w+\\([^)]*\\)(?!\\s*[;,]?\\s*\\.catch|\\s*//\\s*safe)",
      "message": "Awaited calls must have error handling (try/catch or .catch()). Add // safe if intentional.",
      "fileTypes": ["ts", "tsx", "js", "jsx"],
      "bypass": ["**/*.test.*", "**/*.spec.*"]
    },
    {
      "id": "no-hardcoded-secrets",
      "severity": "error",
      "pattern": "(api_key|apikey|secret|password|token)\\s*=\\s*['\"][^'\"]{8,}['\"]",
      "message": "Potential hardcoded secret detected. Use environment variables.",
      "fileTypes": ["ts", "tsx", "js", "jsx", "py", "go", "swift"],
      "caseSensitive": false
    }
  ],
  "globalBypass": [
    "**/*.generated.*",
    "**/node_modules/**",
    "**/.build/**",
    "**/dist/**"
  ]
}
```

### 3. Rule definition format

Each rule has:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique identifier, used in bypass comments |
| `severity` | `"error"` or `"warning"` | yes | error = blocking, warning = non-blocking |
| `pattern` | string (regex) | yes | Regex to match in file contents |
| `message` | string | yes | Human-readable explanation and fix hint |
| `fileTypes` | string[] | no | Limit to these extensions (no dot) |
| `bypass` | string[] | no | Glob patterns of files to skip for this rule |
| `caseSensitive` | boolean | no | Default `true` |
| `multiline` | boolean | no | Enable multiline regex matching |

### 4. Built-in rules reference

| Rule ID | Severity | Detects |
|---------|----------|---------|
| `no-console-log` | error | `console.log()` / `console.error()` in non-test files |
| `no-todo-in-prod` | warning | `// TODO` without a ticket reference |
| `require-error-handling` | error | Unhandled awaited calls |
| `no-hardcoded-secrets` | error | API keys, passwords, tokens as string literals |
| `no-any-typescript` | warning | `any` type in TypeScript |
| `require-return-type` | warning | Functions missing explicit return type annotation (TypeScript) |
| `no-force-unwrap-swift` | error | `!` force unwrap on optionals in Swift |
| `no-print-swift` | error | `print()` in Swift production files |

### 5. Custom rule authoring

Rules use regex patterns. Tips for effective patterns:

```json
// Match a specific call
{
  "id": "no-sync-fs",
  "severity": "error",
  "pattern": "fs\\.(readFileSync|writeFileSync|existsSync|mkdirSync)",
  "message": "Use async fs functions (fs.promises) instead of sync variants.",
  "fileTypes": ["ts", "js"]
}

// Match missing validation
{
  "id": "require-zod-parse",
  "severity": "warning",
  "pattern": "req\\.body(?!\\.parse|\\s*=)",
  "message": "req.body access without Zod parse detected. Validate external input.",
  "fileTypes": ["ts", "js"]
}

// Match multiline pattern (function without try/catch)
{
  "id": "async-fn-no-trycatch",
  "severity": "warning",
  "pattern": "async\\s+function\\s+\\w+[^}]*await[^}]*(?!try)",
  "multiline": true,
  "message": "Async function with await but no try/catch block detected.",
  "fileTypes": ["ts", "js"]
}
```

### 6. Severity levels

| Level | Exit code | Claude Code behavior |
|-------|-----------|---------------------|
| `error` | 1 | Hook blocks — Claude must fix the file in the same turn |
| `warning` | 0 | Hook passes — violation is logged in output, agent may choose to fix |

Design principle: reserve `error` for violations that would cause runtime failures, security issues, or build failures. Use `warning` for style, best-practice, and maintainability issues.

### 7. Bypass mechanisms

**File-level bypass via config** (preferred):

```json
{
  "id": "no-console-log",
  "bypass": ["**/*.test.*", "**/*.spec.*", "**/scripts/**", "**/tools/**"]
}
```

**Inline bypass comment** (for exceptional cases):

```typescript
console.log("debug output");  // plankton-disable no-console-log
```

```swift
print("debug")  // plankton-disable no-print-swift
```

Inline bypass comments appear in the diff and are reviewable — they document the exception at the point of use.

**Global bypass** applies to all rules:

```json
{
  "globalBypass": [
    "**/*.generated.ts",
    "**/migrations/**",
    "**/__mocks__/**"
  ]
}
```

### 8. Integration with PostToolUse hooks

Full settings.json with multiple hooks:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "plankton check --file $CLAUDE_TOOL_OUTPUT_FILE --config .plankton.json --format json",
            "blocking": true,
            "timeout": 10000
          },
          {
            "type": "command",
            "command": "prettier --check $CLAUDE_TOOL_OUTPUT_FILE 2>&1 || true",
            "blocking": false,
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

Hooks run in order. The first blocking failure stops the chain.

### 9. CI vs. local behavior

Plankton is a **local / agent-side** tool. CI remains authoritative.

| Property | Plankton (local) | CI linter (authoritative) |
|----------|-----------------|--------------------------|
| When it runs | On every file write | On push / PR open |
| Speed | < 1s per file | Minutes for full lint |
| Blocking | Agent turn | Pipeline |
| False positives | Handle with bypass comment | Handle with CI disable comment |
| Source of truth | No | Yes |

Never configure Plankton as the only quality gate. Its value is speed — catching issues before the agent finishes, not replacing CI.

### 10. Plankton output format

Plankton writes to stdout when run with `--format json`:

```json
{
  "file": "src/api/handler.ts",
  "violations": [
    {
      "ruleId": "no-console-log",
      "severity": "error",
      "line": 42,
      "column": 5,
      "message": "console.log() must not appear in production code. Use the logger utility instead.",
      "snippet": "    console.log('user data:', data);"
    }
  ],
  "summary": {
    "errors": 1,
    "warnings": 0,
    "passed": false
  }
}
```

Claude Code reads this output and includes it in the tool response — the agent sees violations directly in the conversation.

## Anti-Patterns

| Anti-pattern | Problem | Fix |
|--------------|---------|-----|
| All rules as `error` | Too noisy, agent fights the linter | `error` for runtime/security issues only |
| No bypass for test files | Blocks legitimate test patterns | Always bypass `**/*.test.*` for strict rules |
| Complex multiline regex | Hard to maintain, high false-positive rate | Keep patterns simple; compose with multiple rules |
| Plankton as sole quality gate | Regex misses many issues; CI misses nothing | Plankton = fast inner loop, CI = authoritative |
| Bypass comments without explanation | Unexplained exceptions in code | Require `// plankton-disable <rule-id> reason: ...` |
| Timeout too low | Plankton killed on large files | Set `timeout` to at least 10000ms (10s) |
| Patterns without `fileTypes` | Runs on every file including images, binaries | Always specify `fileTypes` |

## Safe Behavior

- Read-only analysis of file contents — Plankton does not modify files.
- Does not approve its own output.
- Adding or modifying Plankton rules affects all future writes — rule changes require Ahmed's review.
- Rules targeting secrets or security patterns are CRITICAL and must never be bypassed without explanation.
