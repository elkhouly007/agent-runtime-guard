# Skill: Update Codemaps

## Trigger

Use after adding new files, modules, or routes — when barrel exports, route registrations, or architecture docs have fallen behind the actual codebase. Also use when `index.ts` imports fail because a new file was never exported.

## What Gets Updated

| Artifact | Purpose | Update Trigger |
|----------|---------|---------------|
| `index.ts` / `index.js` barrel exports | Single import point for a module directory | New `.ts` file added to `src/` |
| Route registry | Registers controller methods with the router | New controller method or file added |
| `ARCHITECTURE.md` / `CODEBASE.md` | Human-readable map of the codebase | New top-level module or service added |
| OpenAPI route list | Machine-readable API surface | New endpoint added |
| Next.js App Router page map | Documents `app/` directory pages | New `page.tsx` added |

## Process

### 1. Detect what needs updating

```bash
# Check for TypeScript barrel file
ls src/index.ts src/index.js 2>/dev/null

# Check for architecture docs
ls ARCHITECTURE.md CODEBASE.md docs/architecture.md 2>/dev/null

# Check for route files
ls src/routes/ src/router/ app/routes/ routes.ts 2>/dev/null
```

### 2. TypeScript / JavaScript barrel exports

Find source files not yet exported from `index.ts`:

```bash
find src -name "*.ts" \
  ! -name "*.test.ts" \
  ! -name "*.spec.ts" \
  ! -name "*.d.ts" \
  ! -name "index.ts" \
  ! -path "*/node_modules/*" | while read f; do
    MODULE=$(basename "$f" .ts)
    if ! grep -q "$MODULE" src/index.ts 2>/dev/null; then
      echo "Missing export: $f"
    fi
done
```

Generate a full updated barrel from all source files:

```bash
find src -name "*.ts" \
  ! -name "*.test.ts" \
  ! -name "*.spec.ts" \
  ! -name "*.d.ts" \
  ! -name "index.ts" \
  ! -path "*/node_modules/*" | sort | while read f; do
    # Convert file path to relative export path
    EXPORT_PATH="./${f#src/}"
    EXPORT_PATH="${EXPORT_PATH%.ts}"
    echo "export * from '${EXPORT_PATH}';"
done
```

### 3. Route maps by framework

#### Express

```bash
# Find all registered routes
grep -rn "router\.\(get\|post\|put\|patch\|delete\)" src/ --include="*.ts" | \
  sed "s/.*router\.\([a-z]*\)('\([^']*\)'.*/\1 \2/" | sort
```

```bash
# Find all controller methods not registered in the router
CONTROLLERS=$(grep -rn "async " src/controllers/ --include="*.ts" -l)
for f in $CONTROLLERS; do
  BASE=$(basename "$f" .ts)
  METHODS=$(grep -oP "async \K\w+" "$f")
  for METHOD in $METHODS; do
    if ! grep -rq "$METHOD" src/routes/ 2>/dev/null; then
      echo "Unregistered: $BASE.$METHOD"
    fi
  done
done
```

#### FastAPI (Python)

```bash
# List all route decorators
grep -rn "@\(app\|router\)\.\(get\|post\|put\|patch\|delete\)" . --include="*.py" | \
  grep -oP '@\w+\.\w+\("[^"]*"\)' | sort
```

#### Django

```bash
# List all URL patterns
python3 -c "
import os, re
for root, _, files in os.walk('.'):
    for f in files:
        if f == 'urls.py':
            path = os.path.join(root, f)
            content = open(path).read()
            patterns = re.findall(r'path\(['\''\"](.*?)['\''\"]\s*,', content)
            for p in patterns:
                print(f'{path}: {p}')
"
```

#### Next.js App Router

```bash
# List all pages in the app directory
find app -name "page.tsx" -o -name "page.ts" -o -name "page.jsx" 2>/dev/null | \
  sed 's|app/||; s|/page\.[tj]sx\?$||' | sort
```

#### Django REST Framework (DRF)

```bash
# List all ViewSet routes
grep -rn "router\.register\|@action" . --include="*.py" | sort
```

### 4. Generate updated barrel index

After detecting missing exports, produce the full updated `index.ts`:

```typescript
// Auto-generated barrel — do not edit manually
// Run /update-codemaps to regenerate

export * from './auth/token';
export * from './auth/session';
export * from './billing/invoice';
export * from './billing/subscription';
export * from './jobs/scheduler';
export * from './utils/retry';
// ... all modules listed alphabetically
```

Write this only after confirmation if more than 5 new exports are being added.

### 5. Update CODEBASE.md

If `CODEBASE.md` or `ARCHITECTURE.md` exists, check for new top-level modules:

```bash
# Find top-level directories in src/ not mentioned in CODEBASE.md
for DIR in src/*/; do
  MODULE=$(basename "$DIR")
  if ! grep -q "$MODULE" CODEBASE.md 2>/dev/null; then
    echo "Missing module in CODEBASE.md: $MODULE"
  fi
done
```

## Good CODEBASE.md Structure

```markdown
# Codebase Map

## Directory Structure

| Path | Purpose |
|------|---------|
| `src/auth/` | Authentication: JWT issuance, session management, OAuth |
| `src/billing/` | Stripe integration, invoice generation, subscription lifecycle |
| `src/jobs/` | Background jobs: scheduler, retry logic, queue consumers |
| `src/api/` | HTTP layer: route handlers, middleware, request validation |
| `src/db/` | Database access: models, migrations, query helpers |
| `src/utils/` | Shared utilities: retry, logging, date helpers |

## Key Entry Points

| File | Role |
|------|------|
| `src/index.ts` | Barrel export — public API of the module |
| `src/api/router.ts` | Express router — all HTTP routes registered here |
| `src/jobs/scheduler.ts` | Cron scheduler — all background jobs registered here |

## External Dependencies

| Service | Used by | Purpose |
|---------|---------|---------|
| Stripe | `src/billing/` | Payment processing |
| Redis | `src/jobs/` | Job queue, session cache |
| PostgreSQL | `src/db/` | Primary datastore |

## Data Flow

Request → `src/api/router.ts` → handler → service layer → `src/db/` → response
```

## PostToolUse Hook Automation

Add to `.claude/settings.json` to auto-run codemap updates after file writes:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'echo \"File changed — run /update-codemaps if new modules were added\"'"
          }
        ]
      }
    ]
  }
}
```

For a fully automated approach (use carefully — barrel rewrites can be destructive):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash -c 'find src -name \"*.ts\" ! -name \"*.test.ts\" ! -name \"index.ts\" | while read f; do basename $f .ts; done | sort > /tmp/src_modules.txt && grep -oP \"from \\'\\./\\K[^']+\" src/index.ts | sort > /tmp/barrel_modules.txt && comm -23 /tmp/src_modules.txt /tmp/barrel_modules.txt > /tmp/missing_exports.txt && [ -s /tmp/missing_exports.txt ] && echo \"Missing barrel exports:\" && cat /tmp/missing_exports.txt || true'"
          }
        ]
      }
    ]
  }
}
```

## Safe Behavior

- Detection is read-only.
- Does not overwrite barrel files automatically — shows the diff and waits for confirmation if more than 5 lines change.
- Does not remove exports from barrel files without explicit instruction — removals can break consumers.
- Does not modify route registrations directly; flags unregistered controllers for human review.
- Architecture doc updates are written by the `doc-updater` agent, not applied automatically.
