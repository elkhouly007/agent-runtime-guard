#!/usr/bin/env node
// output-sanitizer.js — Claude PostToolUse hook for secret scanning in tool output.
//
// Scans tool output and model responses for secrets before they propagate
// into context. PostToolUse hooks cannot block; this emits a warning to
// stderr so the operator sees it in the session log.
//
// Delegates scanning to runtime/secret-scan.js (same 23-pattern set used
// by the PreToolUse spine) so pre- and post-tool coverage is consistent.

"use strict";

const { readStdin, collectText, hookLog, rateLimitCheck } = require("./hook-utils");
const { scanSecrets } = require("../../runtime/secret-scan");

readStdin()
  .then((raw) => {
    if (process.env.HORUS_KILL_SWITCH === "1") {
      process.stdout.write(raw);
      return;
    }

    if (!rateLimitCheck("output-sanitizer")) {
      process.stdout.write(raw);
      return;
    }

    try {
      const input = JSON.parse(raw || "{}");
      // PostToolUse payload shape: { tool_use_id, tool_name, output, ... }
      // Scan the output field preferentially; fall back to full recursive collect.
      const outputText = String(input.output || input.tool_output || input.content || "");
      const text = outputText || collectText(input);
      const hit  = scanSecrets(text);

      if (hit) {
        process.stderr.write(`[Agent Runtime Guard] Possible ${hit.name} detected in tool output.\n`);
        process.stderr.write("[Agent Runtime Guard] Secret may have been echoed by the tool. Rotate the credential if unintentional.\n");
        try { hookLog("output-sanitizer", "WARN", hit.name); } catch { /* log I/O is non-fatal */ }
      }
    } catch { /* malformed payload — non-blocking */ }

    process.stdout.write(raw);
  })
  .catch(() => process.exit(0));
