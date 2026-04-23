# Skill: Fix Build

## Trigger

Use when a build, compile step, CI pipeline, or test suite is failing.

## Diagnostic Principle

**Read the root error, not the cascade.** Most build failures generate dozens of lines of output — the actual problem is usually the first error. Scroll to the top, find the original failure, ignore everything below it.

## Process

### 1. Read the full error output
Do not guess. Do not apply fixes before diagnosing.
- Find the first error, not the most prominent.
- Note: file path, line number, error type, error message.

### 2. Delegate to build-error-resolver agent
Pass the agent:
- The full error output (untruncated)
- The language and build tool
- What changed before the failure (git diff, recent commit)

For language-specific issues, also consult the relevant language agent:
- `go-build-resolver`, `java-build-resolver`, `kotlin-build-resolver`
- `rust-build-resolver`, `cpp-build-resolver`, `pytorch-build-resolver`, `dart-build-resolver`

### 3. Diagnose the category

| Category | Indicators | Fix direction |
|----------|-----------|---------------|
| Missing dependency | `Cannot find module`, `ModuleNotFoundError`, `package not found` | Install or add to manifest |
| Wrong runtime version | `SyntaxError` on valid code, `Unexpected token`, version mismatch | Check `.nvmrc`, `.tool-versions`, `.python-version` |
| Type error | `Type X is not assignable to Y`, `cannot use X as type Y` | Read the mismatch, fix the source not the type annotation |
| Missing env variable | `undefined is not a function`, `KeyError: 'VAR'` at startup | Check `.env.example`, set in local `.env` |
| Import path error | `cannot find file`, `no such file or directory` | Check path typo, renamed file, moved module |
| Stale cache | Build was clean before, fails after no changes | Clear cache and retry |
| Circular dependency | `circular import`, `dependency cycle` | Restructure imports |
| Linker / compilation | `undefined reference`, `cannot open shared object` | Missing system library or incorrect build flags |

### 4. Apply the targeted fix
Do not apply guesses. If unsure, read the relevant file before editing it.

### 5. Verify locally before pushing
```bash
# Node.js
npm install && npm run build && npm test

# Python
pip install -r requirements.txt && python -m pytest

# Go
go mod tidy && go build ./... && go test ./...

# Rust
cargo build && cargo test

# Java / Maven
mvn clean install

# Dart / Flutter
flutter pub get && flutter build
```

## Common Fixes

### Missing dependency
```bash
npm install <package>          # Node
pip install <package>          # Python
go get <module>                # Go
cargo add <crate>              # Rust
```
Then commit the updated lock file.

### Wrong Node/Python/Go version
```bash
node --version && cat .nvmrc   # compare
nvm use                        # switch to project version
pyenv local $(cat .python-version)
```

### Clear stale caches
```bash
rm -rf node_modules && npm install     # Node
find . -name "__pycache__" -type d -exec rm -rf {} +  # Python
go clean -cache                        # Go
cargo clean                            # Rust
mvn clean                              # Maven
```

### Environment variable missing
1. Check `.env.example` for the variable name.
2. Copy to `.env` and fill in the value.
3. Never commit secrets to `.env`.

## CI-Specific Failures

If it passes locally but fails in CI:
- **Environment diff**: CI has no `.env` — check for missing secrets/variables in CI config.
- **Platform diff**: CI might be Linux, local might be macOS — path separator, line ending issues.
- **Cache stale in CI**: trigger a fresh CI run with cache cleared.
- **Race condition in tests**: parallel test execution in CI may expose non-determinism.
- **Different dependency versions**: CI lockfile might be out of sync.

## What NOT to Do

- Do not disable type checking (`// @ts-ignore`, `#type: ignore`) as a permanent fix.
- Do not downgrade a dependency to avoid a CVE without assessing impact.
- Do not install packages globally — always project-local.
- Do not push broken code to shared branches while debugging.
- Do not silence compiler warnings with suppression flags.

## Safe Behavior

- Diagnose before fixing — do not guess.
- Do not install packages globally.
- Do not disable linting, type checks, or test steps as a fix.
- Verify fix locally before pushing to a shared branch.
- If the fix requires a secret or credential, flag to Ahmed for supply.
