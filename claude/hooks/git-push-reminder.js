#!/usr/bin/env node
// git-push-reminder.js — PreToolUse hook for the Bash tool.
//
// Warns before any `git push` command. In enforce mode (ECC_ENFORCE=1)
// blocks force-pushes entirely; a regular push still proceeds with a reminder.
//
// Enforce levels:
//   ECC_ENFORCE=1  →  block mode: git push --force / --force-with-lease aborted.
//   Default        →  warn mode:  all git push commands print a reminder, none are blocked.

"use strict";

const { readStdin, commandFrom, ENFORCE, hookLog, rateLimitCheck } = require("./hook-utils");

const FORCE_PUSH  = /\bgit\s+push\b.*(-f\b|--force\b|--force-with-lease\b)/;
const ANY_PUSH    = /\bgit\s+push\b/;
const MAIN_BRANCH = /\b(main|master|production|prod|release)\b/;

readStdin()
  .then((raw) => {
    if (!rateLimitCheck("git-push-reminder")) {
      process.stdout.write(raw);
      return;
    }
    try {
      const input   = JSON.parse(raw || "{}");
      const command = commandFrom(input);

      if (ANY_PUSH.test(command)) {
        const isForce    = FORCE_PUSH.test(command);
        const targetMain = MAIN_BRANCH.test(command);

        if (isForce) {
          console.error("[ECC Safe-Plus] [CRITICAL] Force push detected.");
          if (targetMain) {
            console.error("[ECC Safe-Plus] Target appears to be a protected branch (main/master/prod).");
          }
          console.error("[ECC Safe-Plus] Force push can overwrite shared history and destroy teammates' work.");

          if (ENFORCE) {
            console.error("[ECC Safe-Plus] BLOCKED — ECC_ENFORCE=1 is active. Force push aborted.");
            console.error("[ECC Safe-Plus] To proceed: get explicit approval, then run the command manually.");
            try { hookLog("git-push-reminder", "BLOCK", "force-push"); } catch { /* log I/O is non-fatal */ }
            process.exit(2);
          }

          try { hookLog("git-push-reminder", "WARN", "force-push"); } catch { /* log I/O is non-fatal */ }
          console.error("[ECC Safe-Plus] Proceeding in warn mode. Set ECC_ENFORCE=1 to block force pushes.");
        } else {
          try { hookLog("git-push-reminder", "WARN", "git-push"); } catch { /* log I/O is non-fatal */ }
          console.error("[ECC Safe-Plus] Before pushing: review branch, remote, staged files, and diff.");
          if (targetMain) {
            console.error("[ECC Safe-Plus] Pushing directly to a main/master/prod branch — confirm this is intentional.");
          }
        }
      }
    } catch {
      // Non-blocking by design.
    }
    process.stdout.write(raw);
  })
  .catch(() => process.exit(0));
