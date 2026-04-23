# Skills

High-level workflow definitions that orchestrate agents, rules, and tools for common development tasks. **199 skills** are available across development, security, testing, content, infrastructure, research, and ECC meta domains.

## Core Skills

| Skill | Use When |
|---|---|
| `code-review` | Reviewing any code change or PR |
| `security-review` | Auditing for vulnerabilities or reviewing security-sensitive changes |
| `plan-feature` | Starting a complex feature that spans multiple files or components |
| `refactor` | Improving code structure without changing behavior |
| `fix-build` | Diagnosing and fixing build or CI failures |
| `performance-audit` | Diagnosing and fixing performance bottlenecks |
| `tdd` | Test-driven development workflows |
| `deep-research` | Multi-source research with synthesis |
| `checkpoint` | Point-in-time project snapshot before large changes |
| `verification-loop` | Iterative verification until tests pass |

## Category Overview

This table is a set of selected examples, not an exhaustive index of all 199 skills.

| Category | Skills |
|---|---|
| **Code quality** | code-review, refactor, fix-build, quality-gate, verification-loop, tdd, tdd-workflow |
| **Security** | security-review, security-scan, django-security, laravel-security, perl-security, springboot-security |
| **Planning** | plan-feature, architect, multi-plan, multi-workflow, setup-pm |
| **Testing** | tdd, e2e-testing, eval-harness, eval, learn-eval, test-coverage, cpp-testing, golang-testing, python-testing |
| **Languages** | python-patterns, golang-patterns, cpp-coding-standards, java-coding-standards, laravel-patterns, django-patterns, perl-testing, swift-concurrency-6-2 |
| **Infrastructure** | docker-patterns, deployment-patterns, database-migrations, postgres-patterns |
| **Agents/LLM** | claude-api, model-route, orchestrate, multi-agent-orchestration, multi-execute, sessions, coding-standards |
| **Content/Docs** | article-writing, crosspost, update-docs, documentation-lookup, brand-voice, market-research |
| **ECC / Meta** | configure-ecc, skill-create, skill-stocktake, update-codemaps, prune, learn, evolve |
| **Observability** | ecc-tools-cost-audit, strategic-compact, loop-start, loop-status, search-first |

## How to Use

Skills are entry points. They select the right agents and rules for the task, then orchestrate the workflow.

Run a skill by typing its name (e.g. `/security-review`) or referencing it in an agent prompt.

## Adding Skills

New skills should:
- Have a clear trigger (when to use it).
- Define the process (which agents/rules to apply).
- Define the expected output.
- State the safe behavior (what the skill does and does not do automatically).

See `check-skills.sh` to validate a new skill's structure.
