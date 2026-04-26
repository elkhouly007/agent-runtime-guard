#!/usr/bin/env node
// adapter.js — Codex PreToolUse adapter for Horus Agentic Power (best-effort).
//
// Confirmed Codex hook shape (OpenAI Codex CLI, verified 2026-04):
//   { "session_id": "...", "hook_event_name": "PreToolUse",
//     "tool_name": "Bash", "tool_input": { "command": "..." } }
//
// Falls back to flat { "command": "...", "cmd": "..." } shapes for resilience.
// Exit 2 blocks execution; exit 0 allows it.
// To enable block mode: export HORUS_ENFORCE=1

"use strict";

const { createAdapter } = require("../../claude/hooks/hook-utils");

createAdapter({
  harness:        "codex",
  rateLimitKey:   "codex-adapter",
  extractCommand: (i) => String(i.command || i.cmd || i.tool_input?.command || i.input?.command || i.args?.command || i.params?.command || ""),
  extractCwd:     (i) => String(i.workdir || i.cwd || i.working_directory || i.tool_input?.cwd || i.input?.cwd || i.args?.cwd || ""),
  extractTool:    (i) => String(i.tool_name || i.tool || i.type || "Bash"),
});
