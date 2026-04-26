#!/usr/bin/env node
// adapter.js — ClawCode PreToolUse adapter for Horus Agentic Power (best-effort).
//
// ClawCode hook API is not publicly documented. Based on available evidence,
// ClawCode mirrors the Claude Code hook shape:
//   { "tool_name": "Bash", "tool_input": { "command": "..." } }
//
// Falls back to flat { "command": "...", "cmd": "..." } shapes for resilience.
// Exit 2 blocks execution; exit 0 allows it.
// To enable block mode: export HORUS_ENFORCE=1

"use strict";

const { createAdapter } = require("../../claude/hooks/hook-utils");

createAdapter({
  harness:        "clawcode",
  rateLimitKey:   "clawcode-adapter",
  extractCommand: (i) => String(i.command || i.cmd || i.tool_input?.command || i.input?.command || i.args?.command || i.params?.command || ""),
  extractCwd:     (i) => String(i.cwd || i.workdir || i.working_directory || i.tool_input?.cwd || i.input?.cwd || i.args?.cwd || ""),
  extractTool:    (i) => String(i.tool_name || i.tool || i.type || "Bash"),
});
