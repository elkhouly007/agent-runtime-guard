---
paths:
  - "**/*.kt"
  - "**/*.kts"
  - "**/build.gradle.kts"
last_reviewed: 2026-04-22
version_target: "Best Practices"
---
# Kotlin Hooks

> This file extends [common/hooks.md](../common/hooks.md) with Kotlin-specific content.

## PostToolUse Hooks

Configure in `~/.claude/settings.json`:

- **ktfmt/ktlint**: Auto-format `.kt` and `.kts` files after edit
- **detekt**: Run static analysis after editing Kotlin files
- **./gradlew build**: Verify compilation after changes
