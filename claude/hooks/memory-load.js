#!/usr/bin/env node
/**
 * memory-load.js — ECC Safe-Plus  (SessionStart hook)
 *
 * Fires at session start. Reads the memory index file and prints a brief
 * orientation summary to stderr so Ahmed knows what context is loaded.
 *
 * SAFETY CONTRACT:
 * - Reads JSON from stdin.
 * - Echoes original input to stdout UNCHANGED.
 * - Writes orientation summary to stderr only.
 * - Reads ONLY the memory index file (titles/counts — never full content).
 * - No external packages, no network calls.
 * - Silent fail on errors.
 *
 * Memory file locations (in priority order):
 *   1. ~/.claude/projects/-home-khouly--openclaw-workspace-sand/memory/MEMORY.md
 *   2. ~/.openclaw/memory/MEMORY.md
 */

"use strict";

const fs   = require("fs");
const os   = require("os");
const path = require("path");

const HOME = os.homedir();

const MEMORY_PATHS = [
  path.join(HOME, ".claude", "projects", "-home-khouly--openclaw-workspace-sand", "memory", "MEMORY.md"),
  path.join(HOME, ".openclaw", "memory", "MEMORY.md"),
];

/** Extract entry titles from lines that start with `- [` (markdown list links). */
function parseEntries(content) {
  const titles = [];
  // Match lines like: - [Some Title](path) — description
  const linePattern = /^- \[([^\]]+)\]/gm;
  let match;
  while ((match = linePattern.exec(content)) !== null) {
    titles.push(match[1].trim());
  }
  return titles;
}

function readMemoryFile() {
  for (const candidate of MEMORY_PATHS) {
    try {
      const content = fs.readFileSync(candidate, "utf8");
      return content;
    } catch {
      // Try next candidate.
    }
  }
  return null;
}

function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => { data += chunk; });
    process.stdin.on("end", () => resolve(data));
  });
}

readStdin()
  .then((raw) => {
    // Always echo input unchanged first.
    process.stdout.write(raw || "");

    try {
      const content = readMemoryFile();
      if (!content) return; // Neither file found — silent.

      const titles = parseEntries(content);
      if (titles.length === 0) return; // No entries parsed — silent.

      const total    = titles.length;
      const preview  = titles.slice(0, 3);
      const overflow = total - preview.length;

      let msg = `[ECC Safe-Plus] Memory: ${total} item${total !== 1 ? "s" : ""} loaded.\n`;
      for (const title of preview) {
        msg += `  \u2022 ${title}\n`;
      }
      if (overflow > 0) {
        msg += `  (+ ${overflow} more)\n`;
      }

      process.stderr.write(msg);
    } catch {
      // Malformed content or unexpected error — do not block.
    }
  })
  .catch(() => process.exit(0));
