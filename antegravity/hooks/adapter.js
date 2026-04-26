#!/usr/bin/env node
// adapter.js — Antegravity PreToolUse adapter for Horus Agentic Power (best-effort).
//
// Antegravity hook API is not publicly documented (possibly an internal Google tool).
// This adapter applies the broadest possible fallback chain. Test against your
// actual Antegravity hook payload before relying on this in production.
//
// Assumed shape (unverified — best-effort based on Claude Code compat):
//   { "tool_name": "Bash", "tool_input": { "command": "..." } }
//
// Exit 2 blocks execution; exit 0 allows it.
// To enable block mode: export HORUS_ENFORCE=1

"use strict";

const { createAdapter } = require("../../claude/hooks/hook-utils");

createAdapter({
  harness:        "antegravity",
  rateLimitKey:   "antegravity-adapter",
  extractCommand: (i) => String(i.command || i.cmd || i.tool_input?.command || i.input?.command || i.args?.command || i.params?.command || ""),
  extractCwd:     (i) => String(i.cwd || i.workdir || i.working_directory || i.tool_input?.cwd || i.input?.cwd || i.args?.cwd || ""),
  extractTool:    (i) => String(i.tool_name || i.tool || i.type || "Bash"),
});
