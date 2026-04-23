# Verify Safe

Run a practical verification loop using local project checks.

## Verification Order

1. relevant local type or syntax checks;
2. relevant local lint or quality checks;
3. relevant local tests if present;
4. relevant local build if present;
5. concise result summary.

## Safe-Plus Adjustments

- do not assume npm, npx, or any package manager command exists;
- prefer project-native verification commands;
- do not install dependencies during verification by default;
- report missing checks instead of faking them.
