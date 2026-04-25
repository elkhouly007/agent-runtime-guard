#!/usr/bin/env node
// adapter.js — OpenClaw PreToolUse adapter for Agent Runtime Guard.
// OpenClaw primary shape: { "tool": "shell", "cmd": "...", "cwd": "..." }
// Falls back to Claude Code shapes for cross-harness compatibility.
// Delegates all enforcement to runtime/pretool-gate.js. ECC_ENFORCE=1 = block mode.

"use strict";

const { createAdapter } = require("../../claude/hooks/hook-utils");

createAdapter({
  harness:        "openclaw",
  rateLimitKey:   "openclaw-adapter",
  extractCommand: (i) => String(i.cmd || i.input?.cmd || i.command || i.args?.command || i.tool_input?.command || i.input?.command || ""),
  extractCwd:     (i) => String(i.cwd || i.input?.cwd || i.args?.cwd || i.tool_input?.cwd || ""),
  extractTool:    (i) => String(i.tool || "shell"),
});
