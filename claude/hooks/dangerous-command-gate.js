#!/usr/bin/env node
// dangerous-command-gate.js — Claude PreToolUse adapter for Agent Runtime Guard.
// Delegates all enforcement to runtime/pretool-gate.js. ECC_ENFORCE=1 = block mode.

"use strict";

const { createAdapter, commandFrom } = require("./hook-utils");

createAdapter({
  harness:        "claude",
  rateLimitKey:   "dangerous-command-gate",
  extractCommand: (i) => commandFrom(i),
  extractCwd:     (i) => String(i.cwd || i.args?.cwd || i.tool_input?.cwd || ""),
  extractTool:    (i) => String(i.tool_name || i.tool || "Bash"),
});
