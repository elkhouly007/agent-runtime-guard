#!/usr/bin/env node
"use strict";

// intent-classifier.js — Lightweight command-intent classifier for Agent Runtime Guard.
//
// Classifies a shell command string into one of seven intents:
//   explore   — read-only inspection (ls, cat, git status, git log, grep, ...)
//   build     — compilation, tests, linting (npm test, cargo test, pytest, make, ...)
//   deploy    — push/release operations (git push, kubectl apply, terraform apply, ...)
//   modify    — in-place file mutation (sed, patch, cp, mv, echo >, ...)
//   configure — package installation / environment setup (npm install, pip install, ...)
//   cleanup   — removal / pruning (rm, docker rm, git clean, ...)
//   debug     — interactive debugging / introspection (gdb, strace, console.log, ...)
//   unknown   — fallback when no pattern matches
//
// Design constraints:
//   - Zero external dependencies (Node.js built-ins only).
//   - Purely pattern-based; no I/O, no side effects.
//   - Returns { intent, confidence, indicators } — callers use intent as the primary value.
//
// Usage:
//   const { classifyIntent } = require("./intent-classifier");
//   const { intent, confidence } = classifyIntent("npm test");
//   // → { intent: "build", confidence: 0.9, indicators: ["build-tool"] }

/**
 * Classify the intent of a shell command string.
 *
 * @param {string} command — the shell command to classify
 * @returns {{ intent: string, confidence: number, indicators: string[] }}
 */
function classifyIntent(command) {
  const raw = String(command || "").trim();
  const cmd = raw.toLowerCase();

  if (!cmd) {
    return { intent: "unknown", confidence: 0.3, indicators: [] };
  }

  // ── Explore: read-only inspection ────────────────────────────────────────
  // Standard POSIX inspection tools
  if (/^(ls|cat|head|tail|find|grep|egrep|fgrep|rg|ripgrep|less|more|wc|file|stat|diff|xxd|od|strings|tree)\b/.test(cmd)) {
    return { intent: "explore", confidence: 0.92, indicators: ["read-only-command"] };
  }
  // git inspection commands — not git push, commit, add (those are modify/deploy)
  if (/^git\s+(status|log|diff|show|ls-files|blame|describe|rev-parse|branch|tag|remote\s+-v|stash\s+list|shortlog|reflog|bisect)\b/.test(cmd)) {
    return { intent: "explore", confidence: 0.92, indicators: ["git-read-command"] };
  }
  // Docker/kubectl inspection
  if (/^(docker\s+(ps|images|inspect|logs|stats|top)|kubectl\s+(get|describe|logs|top|explain))\b/.test(cmd)) {
    return { intent: "explore", confidence: 0.88, indicators: ["container-inspect"] };
  }

  // ── Build: compile, test, lint ────────────────────────────────────────────
  // npm/yarn/pnpm run subcommands (test, build, lint, start, dev, typecheck)
  if (/\b(npm|yarn|pnpm)\s+(run|test|build|lint|typecheck|format|start|dev|tsc)\b/.test(cmd)) {
    return { intent: "build", confidence: 0.9, indicators: ["build-tool"] };
  }
  // Common test runners and build systems
  if (/\b(jest|mocha|vitest|ava|tap|jasmine|karma)\b/.test(cmd)) {
    return { intent: "build", confidence: 0.9, indicators: ["test-runner"] };
  }
  if (/\b(cargo\s+(test|build|check|clippy|fmt))\b/.test(cmd)) {
    return { intent: "build", confidence: 0.9, indicators: ["rust-build"] };
  }
  if (/\b(go\s+(test|build|vet|generate|run))\b/.test(cmd)) {
    return { intent: "build", confidence: 0.9, indicators: ["go-build"] };
  }
  if (/\b(pytest|py\.test|python\s+-m\s+pytest)\b/.test(cmd)) {
    return { intent: "build", confidence: 0.9, indicators: ["python-test"] };
  }
  if (/\b(make|cmake|ninja|bazel|gradle|mvn|ant)\b/.test(cmd) &&
      !/^make\s+(clean|distclean|mrproper)\b/.test(cmd)) {
    return { intent: "build", confidence: 0.85, indicators: ["build-system"] };
  }
  if (/\b(tsc|webpack|rollup|vite|parcel|esbuild|swc|babel)\b/.test(cmd)) {
    return { intent: "build", confidence: 0.85, indicators: ["js-build-tool"] };
  }

  // ── Deploy: push/release/apply ────────────────────────────────────────────
  if (/^git\s+push\b/.test(cmd)) {
    return { intent: "deploy", confidence: 0.95, indicators: ["git-push"] };
  }
  if (/\b(kubectl\s+apply|kubectl\s+create|kubectl\s+replace)\b/.test(cmd)) {
    return { intent: "deploy", confidence: 0.92, indicators: ["k8s-apply"] };
  }
  if (/\b(terraform\s+(apply|destroy|import))\b/.test(cmd)) {
    return { intent: "deploy", confidence: 0.92, indicators: ["terraform-apply"] };
  }
  if (/\b(helm\s+(install|upgrade|rollback))\b/.test(cmd)) {
    return { intent: "deploy", confidence: 0.9, indicators: ["helm-deploy"] };
  }
  if (/\b(docker\s+(push|deploy))\b/.test(cmd)) {
    return { intent: "deploy", confidence: 0.9, indicators: ["docker-push"] };
  }
  if (/\b(aws\s+(deploy|ecs\s+update|lambda\s+update)|gcloud\s+(deploy|run\s+deploy))\b/.test(cmd)) {
    return { intent: "deploy", confidence: 0.88, indicators: ["cloud-deploy"] };
  }

  // ── Cleanup: removal, pruning ─────────────────────────────────────────────
  // rm / rmdir (before configure check to avoid false match on npm install cleanup)
  if (/^(rm|rmdir)\b/.test(cmd)) {
    return { intent: "cleanup", confidence: 0.88, indicators: ["rm-command"] };
  }
  if (/^make\s+(clean|distclean|mrproper)\b/.test(cmd)) {
    return { intent: "cleanup", confidence: 0.9, indicators: ["make-clean"] };
  }
  if (/\b(docker\s+(rm|rmi|system\s+prune|container\s+prune|image\s+prune))\b/.test(cmd)) {
    return { intent: "cleanup", confidence: 0.9, indicators: ["docker-cleanup"] };
  }
  if (/^git\s+clean\b/.test(cmd)) {
    return { intent: "cleanup", confidence: 0.9, indicators: ["git-clean"] };
  }
  if (/\b(kubectl\s+(delete|remove))\b/.test(cmd)) {
    return { intent: "cleanup", confidence: 0.85, indicators: ["k8s-delete"] };
  }

  // ── Configure: package installation, environment setup ───────────────────
  // Exclude npx -y (that's auto-download, handled by risk-score)
  if (/\b(npm|yarn|pnpm)\s+(install|add|i|ci)\b/.test(cmd) && !/\bnpx\b/.test(cmd)) {
    return { intent: "configure", confidence: 0.88, indicators: ["npm-install"] };
  }
  if (/\b(pip3?|pipenv|poetry)\s+install\b/.test(cmd)) {
    return { intent: "configure", confidence: 0.88, indicators: ["pip-install"] };
  }
  if (/\b(gem\s+install|bundle\s+install)\b/.test(cmd)) {
    return { intent: "configure", confidence: 0.88, indicators: ["gem-install"] };
  }
  if (/\b(cargo\s+install)\b/.test(cmd)) {
    return { intent: "configure", confidence: 0.88, indicators: ["cargo-install"] };
  }
  if (/\b(apt(-get)?\s+install|brew\s+install|yum\s+install|dnf\s+install|pacman\s+-S)\b/.test(cmd)) {
    return { intent: "configure", confidence: 0.85, indicators: ["system-package-install"] };
  }
  if (/\b(docker\s+build|docker\s+pull)\b/.test(cmd)) {
    return { intent: "configure", confidence: 0.85, indicators: ["docker-build-pull"] };
  }

  // ── Modify: in-place mutations ────────────────────────────────────────────
  if (/^(sed|awk|perl\s+-[piw])\b/.test(cmd)) {
    return { intent: "modify", confidence: 0.85, indicators: ["stream-editor"] };
  }
  if (/^patch\b/.test(cmd)) {
    return { intent: "modify", confidence: 0.88, indicators: ["patch-apply"] };
  }
  if (/^(chmod|chown|chgrp)\b/.test(cmd)) {
    return { intent: "modify", confidence: 0.85, indicators: ["permission-change"] };
  }
  if (/^(cp|mv|rename)\b/.test(cmd) && !/^(cp|mv)\s+--/.test(cmd)) {
    return { intent: "modify", confidence: 0.8, indicators: ["file-move-copy"] };
  }
  if (/^(touch|mkdir|mktemp)\b/.test(cmd)) {
    return { intent: "modify", confidence: 0.78, indicators: ["file-create"] };
  }
  // git operations that mutate state (commit, add, reset, rebase, merge, cherry-pick)
  if (/^git\s+(add|commit|reset|rebase|merge|cherry-pick|stash\s+(push|pop|drop)|tag\s+-[adf])\b/.test(cmd)) {
    return { intent: "modify", confidence: 0.85, indicators: ["git-mutate"] };
  }

  // ── Debug: interactive inspection and diagnostics ─────────────────────────
  if (/\b(gdb|lldb|pdb|ipdb|pycharm\s+debugger|node\s+--inspect|dlv)\b/.test(cmd)) {
    return { intent: "debug", confidence: 0.9, indicators: ["debugger"] };
  }
  if (/\b(strace|ltrace|perf|valgrind|heaptrack|cachegrind|massif)\b/.test(cmd)) {
    return { intent: "debug", confidence: 0.9, indicators: ["profiler-tracer"] };
  }
  if (/\b(curl|wget|httpie|http)\s+.*(localhost|127\.0\.0\.1|::1)/.test(cmd)) {
    return { intent: "debug", confidence: 0.78, indicators: ["local-http-probe"] };
  }

  // ── Unknown: fallback ─────────────────────────────────────────────────────
  return { intent: "unknown", confidence: 0.3, indicators: [] };
}

module.exports = { classifyIntent };
