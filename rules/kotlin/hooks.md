---
last_reviewed: 2026-04-23
version_target: 1.0.x
---

# Kotlin + ARG Hooks

Kotlin-specific ARG hook considerations.

## Gradle Build Commands

Kotlin/Android build commands that may trigger ARG:
- `./gradlew assembleRelease` with signing configs that reference keystores
- `./gradlew publish` publishing to Maven Central or Google Play
- Custom Gradle tasks that execute shell commands

## Kotlin Scripting

Kotlin scripts (`.kts` files) executed via the Bash tool have the same considerations as any script:
- `.kts` files can execute shell commands via `ProcessBuilder`
- Gradle build scripts run in the Gradle daemon with elevated permissions relative to the project

## Android-Specific

- Deploying to connected devices (`adb install`) is safe for development
- `adb shell` commands with destructive operations will trigger ARG
- Firebase deploy or Play Store upload commands require explicit approval

## Multiplatform Projects

Kotlin Multiplatform projects targeting multiple platforms:
- Platform-specific build commands for each target (iOS, JS, native) may have different risk profiles
- `kotlinc-native` compiles to native binaries — review what the binary does before running it
- JavaScript targets can run in Node.js environments — apply Node.js-specific security considerations

## Secrets in Kotlin Projects

Common secret locations in Kotlin projects:
- `local.properties`: API keys for Android builds (not committed to git)
- Gradle properties in `~/.gradle/gradle.properties`
- Environment variables for Kotlin backend services

ARG will intercept these if they appear in tool call inputs.
