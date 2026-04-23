# Agents

Specialized subagents for delegation. Each agent has a focused role and defined tools.

## Available Agents

| Agent | Role | Activate When |
|---|---|---|
| `code-reviewer` | General code review | Any code change, PR review, quality check |
| `security-reviewer` | Security vulnerability analysis | Auth changes, user input, API endpoints, deps |
| `architect` | System design and trade-off analysis | New features, large refactors, architectural decisions |
| `planner` | Implementation planning | Complex features, multi-file changes |
| `tdd-guide` | Test-driven development | Writing new features or fixing bugs |
| `performance-optimizer` | Performance diagnosis and fixes | Slow endpoints, high memory, poor Lighthouse scores |
| `typescript-reviewer` | TypeScript/JS/React/Node.js review | TS/JS code changes |
| `python-reviewer` | Python/Django/FastAPI review | Python code changes |
| `go-reviewer` | Go code review | Go code changes |
| `rust-reviewer` | Rust code review | Rust code changes |
| `java-reviewer` | Java/Spring Boot review | Java code changes |
| `kotlin-reviewer` | Kotlin/Android review | Kotlin code changes |
| `database-reviewer` | Schema, query, and migration review | DB schema changes, slow queries, migrations |
| `refactor-cleaner` | Code structure improvement | Duplication, complexity, legacy code |
| `build-error-resolver` | Build and CI failure diagnosis | Build failures, compilation errors, CI issues |
| `silent-failure-hunter` | Find swallowed exceptions and silent errors | Mysterious bugs, missing error handling |
| `doc-updater` | Documentation maintenance | API changes, new features, outdated docs |
| `code-simplifier` | Code complexity reduction | Overly complex code, readability issues |

## How to Use

Reference an agent by its `name` field when delegating a task. Agents are scoped to their area — do not use a language-specific reviewer for general design questions.

## Safety

All agents are read-focused by default. Agents that write code (`tdd-guide`, `refactor-cleaner`, `code-simplifier`) do so only on instruction and after confirming tests are in place.
