#!/usr/bin/env node
// adapter.js — Codex PreToolUse adapter for Agent Runtime Guard (best-effort).
//
// Codex hook API is not publicly documented. This adapter uses the broadest
// possible fallback chain to cover likely input shapes. Test against your
// actual Codex hook payload before relying on this in production.
//
// Likely Codex shapes (not verified):
//   { "tool": "bash", "command": "...", "workdir": "..." }
//   { "tool_name": "Bash", "tool_input": { "command": "..." } }  (Claude Code compat)
//
// To enable block mode: export ECC_ENFORCE=1

"use strict";

const { createAdapter } = require("../../claude/hooks/hook-utils");

createAdapter({
  harness:        "codex",
  rateLimitKey:   "codex-adapter",
  extractCommand: (i) => String(i.command || i.cmd || i.tool_input?.command || i.input?.command || i.args?.command || i.params?.command || ""),
  extractCwd:     (i) => String(i.workdir || i.cwd || i.working_directory || i.tool_input?.cwd || i.input?.cwd || i.args?.cwd || ""),
  extractTool:    (i) => String(i.tool_name || i.tool || i.type || "Bash"),
});
