# Skill: Update Docs

## Trigger

Use after making code changes, before a PR, or when running a documentation audit. Finds documentation that is stale relative to current source code and updates it to match.

## Stale Doc Signals

| Signal | Description |
|--------|-------------|
| Function name mismatch | Docs reference `createUser()` but code now has `registerUser()` |
| Removed parameter | Docs show `options.timeout` but the parameter was deleted |
| Old return shape | Docs describe `{ user, token }` but response is now `{ data: { user }, meta }` |
| Old route | README shows `POST /api/v1/users` but route changed to `/api/v2/users` |
| Example uses deleted import | Code example imports a module that no longer exists |
| Behavior description outdated | Docs say "returns 200 on success" but code now returns 201 |

## Process

### 1. Find recently changed source files

```bash
# Files changed in the last commit
git diff --name-only HEAD~1 HEAD

# Files with uncommitted changes
git diff --name-only

# Files changed in the last N commits
git diff --name-only HEAD~5 HEAD

# Files changed since branching from main
git diff --name-only main...HEAD
```

### 2. For each changed file, find related documentation

#### README.md references

```bash
# Find README sections that mention the file or its key exports
CHANGED_FILE="src/auth/token.ts"
BASENAME=$(basename "$CHANGED_FILE" | sed 's/\.[^.]*$//')
grep -n "$BASENAME" README.md 2>/dev/null
```

#### JSDoc / docstrings in the changed functions

```bash
# Show inline docs for changed functions (JS/TS)
git diff HEAD~1 HEAD -- "$CHANGED_FILE" | grep "^+" | grep -E "(@param|@returns|@throws|\/\*\*)"

# Python docstrings
git diff HEAD~1 HEAD -- "$CHANGED_FILE" | grep "^+" | grep -E '"""'
```

#### API docs if routes changed

```bash
# Detect route changes
git diff HEAD~1 HEAD -- "$CHANGED_FILE" | grep -E "(router\.|app\.|@(Get|Post|Put|Delete|Patch))"

# Find API documentation files
find . -name "openapi.yaml" -o -name "openapi.json" -o -name "swagger.yaml" \
       -o -name "API.md" -o -name "api-docs.md" 2>/dev/null | head -10
```

#### CHANGELOG.md

```bash
# Check if CHANGELOG mentions the last version entry date
head -20 CHANGELOG.md 2>/dev/null
```

### 3. Search for stale references

```bash
# Find all doc files that reference a renamed function
OLD_NAME="createUser"
NEW_NAME="registerUser"
grep -rn "$OLD_NAME" --include="*.md" --include="*.rst" --include="*.txt" . 2>/dev/null

# Find docs that reference a deleted parameter
grep -rn "options\.timeout" --include="*.md" . 2>/dev/null

# Find all markdown code blocks that import a changed module
grep -rn "from.*auth/token" --include="*.md" . 2>/dev/null
```

### 4. Delegate to doc-updater agent

Once stale sections are identified, delegate the actual rewriting to the `doc-updater` agent. Pass:
- The changed source file and the diff
- The stale doc file and the specific lines to update
- The new behavior to document

Do not attempt to bulk-rewrite docs — update only what changed.

### 5. Verify the update

After the `doc-updater` agent returns:

```bash
# Confirm old name no longer appears
grep -n "OLD_FUNCTION_NAME" README.md

# Confirm new name is present
grep -n "NEW_FUNCTION_NAME" README.md

# Confirm code examples use current API
grep -A10 "## Example" README.md
```

## Doc Types and Staleness Detection

| Doc Type | Location | Staleness Signal | How to Detect |
|----------|----------|-----------------|---------------|
| README | `README.md` | Old function names, old routes, old params | `grep -n <old_name> README.md` |
| JSDoc | Source files | Params don't match signature | `git diff` on the function |
| OpenAPI / Swagger | `openapi.yaml` | Route or schema mismatch | Compare route in code vs yaml |
| CHANGELOG | `CHANGELOG.md` | Missing entry for the change | Check if current version is documented |
| Architecture doc | `ARCHITECTURE.md`, `CODEBASE.md` | New modules not mentioned | Compare module list vs doc |
| API reference | `docs/api/*.md` | Endpoint behavior changed | Compare response shape |
| Inline comments | Source files | Comment describes old logic | `git diff` context lines |

## Grep Commands for Finding Stale References

```bash
# All markdown files in the project
find . -name "*.md" ! -path "*/node_modules/*" ! -path "*/.git/*"

# Find docs that mention a specific file being changed
grep -rn "src/auth/token" --include="*.md" .

# Find docs with outdated version numbers
grep -rn "v1\." --include="*.md" . | grep -v CHANGELOG

# Find docs that still reference deleted env vars
grep -rn "LEGACY_API_KEY\|OLD_SECRET" --include="*.md" --include="*.env.example" .

# Find example code blocks in markdown that import changed modules
python3 - <<'EOF'
import re, os
for root, _, files in os.walk("."):
    if "node_modules" in root or ".git" in root: continue
    for f in files:
        if not f.endswith(".md"): continue
        path = os.path.join(root, f)
        content = open(path).read()
        blocks = re.findall(r"```[\w]*\n(.*?)```", content, re.DOTALL)
        for block in blocks:
            if "createUser" in block:  # replace with old name
                print(f"{path}: {block[:100]}")
EOF
```

## Pre-commit Hook Automation

Add to `.git/hooks/pre-commit` to auto-flag stale docs on every commit:

```bash
#!/bin/bash
set -e

CHANGED=$(git diff --cached --name-only | grep -E "\.(ts|js|py|go|rs)$")
if [ -z "$CHANGED" ]; then exit 0; fi

echo "Checking for stale documentation references..."
STALE=0
for FILE in $CHANGED; do
  BASE=$(basename "$FILE" | sed 's/\.[^.]*$//')
  # Check if README references this file and warn if the function list looks outdated
  if grep -q "$BASE" README.md 2>/dev/null; then
    echo "  WARNING: README.md references $BASE — verify docs are current."
    STALE=1
  fi
done

if [ "$STALE" = "1" ]; then
  echo ""
  echo "Run /update-docs to sync documentation before committing."
  # Remove 'exit 1' if you want this to be advisory only
fi
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

## Safe Behavior

- Analysis is read-only. No files are modified without delegating to `doc-updater`.
- Does not delete documentation — only updates or flags for update.
- Does not update CHANGELOG automatically; CHANGELOG entries require explicit instruction.
- If a doc section is ambiguous (could be describing current or old behavior), flags it for human review rather than guessing.
