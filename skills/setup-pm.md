# Skill: Setup Package Manager

## Trigger

Use when starting work on a JS/TS project, when the package manager is ambiguous, when a command like `npm install` fails because the project uses a different PM, or when you want to enforce a consistent package manager across the team.

## Detection Order

Detection runs in priority order. First match wins.

| Priority | Signal | Detected PM |
|----------|--------|-------------|
| 1 | `bun.lockb` exists | bun |
| 2 | `pnpm-lock.yaml` exists | pnpm |
| 3 | `yarn.lock` exists | yarn |
| 4 | `package-lock.json` exists | npm |
| 5 | `package.json` has `"packageManager"` field | per field value |
| 6 | `.claude/package-manager.json` (project-local) | saved preference |
| 7 | `~/.claude/package-manager.json` (global) | saved preference |
| 8 | `ECC_PACKAGE_MANAGER` env var | env override |
| 9 | Not found | ask user |

## Process

### 1. Auto-detect from lock files

```bash
ls bun.lockb pnpm-lock.yaml yarn.lock package-lock.json 2>/dev/null
```

Check which files are present. If exactly one lock file exists, use that PM with no further questions.

### 2. Check package.json packageManager field

```bash
cat package.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('packageManager',''))"
```

The field format is `<pm>@<version>` (e.g. `pnpm@9.1.0`). Strip the version to get the PM name.

### 3. Check saved preferences

```bash
# Project-local preference (highest priority among saved)
cat .claude/package-manager.json 2>/dev/null

# Global fallback
cat ~/.claude/package-manager.json 2>/dev/null
```

### 4. Check environment variable

```bash
echo $ECC_PACKAGE_MANAGER
```

The env var overrides everything except an explicit `--pm` flag passed to `/setup-pm`.

### 5. If ambiguous — ask

If multiple lock files exist or no signal is found, present options:

```
Multiple lock files found. Which package manager should I use?
  [1] bun     (bun.lockb present)
  [2] pnpm    (pnpm-lock.yaml present)
  [3] npm     (package-lock.json present)
  [4] yarn    (yarn.lock present)
```

Wait for confirmation before proceeding.

### 6. Save choice

```bash
# Project-local (commit to repo)
mkdir -p .claude
echo '{"packageManager":"pnpm"}' > .claude/package-manager.json

# Global (user-wide default)
echo '{"packageManager":"pnpm"}' > ~/.claude/package-manager.json
```

### 7. Show detected commands

After detection, print the resolved command set so the user can confirm:

```
Package manager: pnpm

  Install all:    pnpm install
  Add package:    pnpm add <pkg>
  Add dev dep:    pnpm add -D <pkg>
  Remove:         pnpm remove <pkg>
  Run script:     pnpm run <script>  (or: pnpm <script>)
  Execute bin:    pnpm exec <bin>
  Global add:     pnpm add -g <pkg>
```

## Decision Table

| Situation | Recommended PM | Reason |
|-----------|---------------|--------|
| New project, no constraint | bun | Fastest installs, single binary |
| Monorepo with workspaces | pnpm | Best workspace support, disk efficiency |
| Enterprise / corporate proxy | npm | Best compatibility with corporate registries |
| Legacy project, existing yarn.lock | yarn | Avoid breaking lockfile |
| Matching team convention | whatever the team uses | Consistency beats speed |

## PM Equivalents

| Operation | npm | pnpm | yarn | bun |
|-----------|-----|------|------|-----|
| Install all | `npm install` | `pnpm install` | `yarn` | `bun install` |
| Add dep | `npm install pkg` | `pnpm add pkg` | `yarn add pkg` | `bun add pkg` |
| Add dev dep | `npm install -D pkg` | `pnpm add -D pkg` | `yarn add -D pkg` | `bun add -d pkg` |
| Remove | `npm uninstall pkg` | `pnpm remove pkg` | `yarn remove pkg` | `bun remove pkg` |
| Run script | `npm run <s>` | `pnpm run <s>` | `yarn run <s>` | `bun run <s>` |
| Execute bin | `npx <bin>` | `pnpm exec <bin>` | `yarn dlx <bin>` | `bunx <bin>` |
| Global add | `npm install -g pkg` | `pnpm add -g pkg` | `yarn global add pkg` | `bun add -g pkg` |
| Lock file | `package-lock.json` | `pnpm-lock.yaml` | `yarn.lock` | `bun.lockb` |
| Workspace protocol | `npm:` | `workspace:` | `workspace:` | `workspace:` |

## Overrides

**Per-project override** — add to `.claude/package-manager.json`:
```json
{ "packageManager": "bun" }
```

**Global override** — add to `~/.claude/package-manager.json`:
```json
{ "packageManager": "pnpm" }
```

**Env var override** (useful in CI):
```bash
export ECC_PACKAGE_MANAGER=npm
```

**Inline flag** (highest priority, not persisted):
```
/setup-pm --pm yarn
```

## Safe Behavior

- Reads lock files and config; does not run `npm install` or equivalent unless explicitly asked.
- Does not delete existing lock files.
- If lock files conflict (e.g., both `yarn.lock` and `pnpm-lock.yaml` present), flags this as a problem rather than silently choosing one.
