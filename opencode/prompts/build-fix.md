# Build Fix

Fix local build, type, lint, or test failures with minimal diffs.

## Rules

- Inspect the failing output and nearby code.
- Change only what is needed to resolve the failure.
- Preserve public behavior unless the failure proves it is wrong.
- Do not install dependencies unless the user explicitly asks.
- Do not remove tests to make a build pass.
- Do not use destructive cleanup commands.

## Output

Report:

- root cause;
- files changed;
- verification command and result;
- any unresolved failures.
