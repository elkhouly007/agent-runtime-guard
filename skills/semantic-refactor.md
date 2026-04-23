# Skill: semantic-refactor

# Semantic Refactor

Restructure code for clarity and maintainability using a test-protected, incremental approach.

## When to Use

Use when code is hard to read, names don't reveal intent, functions do too many things, or dependencies are hard to test — but when behavior must not change and tests must remain green throughout.

## What Semantic Refactoring Covers

- Renaming: variables, functions, classes, files to names that reveal intent
- Decomposition: splitting large functions/classes into single-responsibility units
- Extraction: pulling duplicated logic into a shared function or module
- Inversion: making dependencies explicit (dependency injection over global singletons)
- Abstraction: introducing an interface between a caller and its concrete dependency

## Safety Preconditions

Before starting:
1. All existing tests pass — `npm test` or equivalent
2. Test coverage is adequate for the area being refactored
3. The refactor scope is bounded (one module, one class, one file)

If tests are absent, write them first (use tdd-guide agent).

## Rename Protocol

```
1. Identify the old name
2. Find all references: grep -rn "oldName" --include="*.ts"
3. Rename in place using editor refactoring (not search-replace — preserves imports)
4. Run tests
5. Commit: "refactor: rename UserFetcher to UserRepository"
```

One rename per commit. Do not bundle renames with logic changes.

## Decomposition Protocol

```
1. Identify the function/class to split
2. List its responsibilities (each "and" in a description = a split point)
3. Extract the least-connected responsibility first
4. Write/update a test for the extracted unit
5. Remove the extracted logic from the original
6. Verify the original still passes its tests
7. Commit each extraction separately
```

## Dependency Inversion Protocol

```
1. Identify the concrete dependency: new HttpClient()
2. Define an interface: interface DataFetcher { fetch(url: string): Promise<Response> }
3. Update the consumer to accept the interface
4. Update all callers to inject the implementation
5. Update tests to inject a mock
```

## Verification Gate

After each step:
- All tests still pass
- No behavior change observable via tests
- The diff is smaller than you expected (if not, you changed behavior)

## When NOT to Refactor

- When there are no tests covering the area
- When you are under a deadline
- When the refactor scope has grown to touch 10+ files (stop, scope it down)
- When the refactor is motivated by style preference rather than a concrete comprehension problem
