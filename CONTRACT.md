# Contract Reference — ecc.contract.json

The contract pre-agrees all security permissions before agent work begins. It is the machine-readable answer to: "what is this agent allowed to do in this project?"

## Quick Start

```bash
# 1. Generate a draft (inspects project, languages, branches)
ecc-cli.sh contract init

# 2. Review and edit ecc.contract.json.draft

# 3. Accept — computes hash, writes final file
ecc-cli.sh contract accept

# 4. Verify at any time
ecc-cli.sh contract verify

# 5. See what's in the contract
ecc-cli.sh contract show

# 6. Amend (bumps revision, requires re-accept)
ecc-cli.sh contract amend
ecc-cli.sh contract accept
```

## Full Schema

```jsonc
{
  "$schema": "schemas/ecc.contract.schema.json",
  "version": 1,

  // Unique ID: "arg-" + YYYYMMDD + "-" + 12 random hex chars
  "contractId": "arg-20260425-a7b2f1c3d4e5",

  // Monotonic. Downgrade (lower revision) is rejected on accept.
  "revision": 1,

  "acceptedAt": "2026-04-25T12:00:00Z",
  "acceptedBy": "user@host",     // informational only

  // null = never expires
  "expiresAt": null,

  // Which harnesses this contract covers.
  // In strict mode (ECC_CONTRACT_REQUIRED=1), unlisted harnesses are blocked for gated classes.
  "harnessScope": ["claude", "opencode", "openclaw"],

  // relaxed | balanced | strict
  "trustPosture": "balanced",

  "scopes": {
    "filesystem": {
      // Glob patterns. ${projectRoot} is substituted at runtime.
      "readAllow": ["${projectRoot}/**"],
      "writeAllow": ["${projectRoot}/src/**", "${projectRoot}/tests/**"],
      "writeDeny":  ["**/.env*", "**/*.pem", "**/secrets/**"],

      // Per-class destructive allows. All-or-nothing: if any target escapes all globs, block.
      "destructiveAllow": [
        { "commandClass": "destructive-delete", "pathGlob": "${projectRoot}/build/**" },
        { "commandClass": "destructive-delete", "pathGlob": "${projectRoot}/dist/**" }
      ]
    },

    "network": {
      // Hostname allowlist. "*" blocks all outbound.
      "outboundAllow": ["registry.npmjs.org", "pypi.org", "github.com"],
      "outboundDeny":  ["*"],

      // Commands allowed to execute on remote hosts (ssh, docker exec, etc.)
      "remoteExecAllow": []
    },

    "secrets": {
      // "block" = hard-block on class-C secret patterns (floor; cannot be set to "off")
      // "warn"  = warn only
      "scanMode": "block",

      // Redact matched values before writing to decision journal
      "redactInJournal": true,

      // Exempt paths from secret scanning (e.g. test fixtures with fake keys)
      "allowSecretLikeInFiles": ["tests/fixtures/**/*.fake-key"]
    },

    "elevation": {
      "sudoAllow": false,
      // Explicit command allowlist when sudoAllow=true
      "sudoAllowCommands": []
    },

    "branches": {
      // Exact names and glob patterns for protected branches
      "protected": ["main", "master", "release/*"],

      // Push is allowed to these branches without require-review
      "pushAllow": ["feature/*", "fix/*"],

      // Force-push is allowed to these branches
      "forcePushAllow": []
    },

    "shell": {
      // Tools that may be invoked (Bash commands)
      "toolAllow": ["git", "npm", "node", "pytest", "rg", "jq"],
      "toolDeny":  ["curl", "wget", "nc", "ssh"],

      // false = global package installs (npm -g, pip install --user) are blocked
      "globalInstallAllow": false
    },

    "payloadClasses": {
      // A = allow, B = warn, C = block (cannot be set to "off" — floor)
      "A": "allow",
      "B": "warn",
      "C": "block"
    }
  },

  // SHA-256 hash of all fields above, excluding contractHash itself.
  // Computed over canonical JSON (keys sorted recursively).
  // Verified on every decide() call.
  "contractHash": "sha256:..."
}
```

## Gated Capability Classes

When `ECC_CONTRACT_REQUIRED=1`, these command classes are blocked unless the contract explicitly allows them:

| Class | Examples |
|---|---|
| `destructive-delete` | `rm -rf`, `shred`, `dd of=`, `mkfs` |
| `force-push` | `git push --force`, `--force-with-lease` |
| `remote-exec` | `curl ... \| sh`, `wget ... \| bash` |
| `auto-download` | `npx -y`, `npm i -g`, `pip install` |
| `hard-reset` | `git reset --hard` |
| `destructive-db` | `DROP TABLE`, `DROP DATABASE` |
| `disk-write` | `dd of=<device>` |
| `sudo` | Any `sudo`-prefixed command |
| `global-pkg-install` | `npm -g`, `pip install --user` (when globalInstallAllow=false) |
| `unknown` | Command the classifier cannot place — fail closed |

Low-risk read and safe-write operations proceed without a contract even in strict mode.

## Hash Verification

On every `decide()` call:
1. Load `ecc.contract.json`
2. Look up `accepted-contracts.json` for the current `projectRoot`
3. Recompute `sha256(canonicalJson(contractWithoutHash))`
4. If hash mismatches the accepted record → block gated classes (strict) or log warning (default)

If the contract file is missing but strict mode is active → block all gated classes.

## Scope Matching Algorithm

1. Classify `input.command` → `commandClass`
2. Extract argument targets via `runtime/arg-extractor.js`
3. Resolve each target with `path.resolve(projectRoot, arg)` + `fs.realpathSync`; on error → deny
4. Reject `..` escape after resolve; reject absolute paths outside `projectRoot`
5. For each matching scope entry, test every target against the path glob
6. **All-or-nothing**: if even one target escapes every allowed glob → scope violation

## Floors That Contracts Cannot Override

These actions are engine-baked and cannot be demoted by any contract-allow:

| Floor | Action |
|---|---|
| `ECC_KILL_SWITCH=1` | block (unconditional) |
| Critical risk (score 10) | block |
| Secret payload class C | block |
| Contract hash mismatch (strict) | block |
| Harness out of scope (strict) + gated class | block |
| Novel command class | escalate |
| Scope violation | escalate |
| Protected branch write | require-review |
| Session risk ≥ 3 | escalate |

Attempting to set a floor to a weaker action in `ecc.contract.json` fails schema validation.

## Amend Flow

1. `ecc-cli.sh contract amend` — copies accepted contract to a new draft, bumps `revision`
2. Edit the draft
3. `ecc-cli.sh contract accept` — re-hashes, verifies revision is higher than current, writes and records
4. Previous contract stays in force during the draft window

Downgrade (lower `revision`) is rejected. Every amend bumps monotonically.
