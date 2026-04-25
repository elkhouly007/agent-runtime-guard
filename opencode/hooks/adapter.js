#!/usr/bin/env node
// adapter.js — OpenCode PreToolUse adapter for Agent Runtime Guard.
// OpenCode uses Claude Code's hook format: { "tool_name": "Bash", "tool_input": { "command": "..." } }
// Delegates all enforcement to runtime/pretool-gate.js. ECC_ENFORCE=1 = block mode.

"use strict";

const { createAdapter, commandFrom } = require("../../claude/hooks/hook-utils");

createAdapter({
  harness:        "opencode",
  rateLimitKey:   "opencode-adapter",
  extractCommand: (i) => commandFrom(i),
  extractCwd:     (i) => String(i.cwd || i.args?.cwd || i.tool_input?.cwd || i.input?.cwd || ""),
  extractTool:    (i) => String(i.tool_name || i.tool || "Bash"),
});
