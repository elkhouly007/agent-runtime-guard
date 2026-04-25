#!/usr/bin/env node
"use strict";

// arg-extractor.js — Minimal argv splitter for scope matching.
//
// Splits a shell command string into tokens respecting single/double quotes
// and backslash escapes. Heredocs (<<EOF ... EOF) are treated as a single
// opaque token "<<HEREDOC" so the engine fails closed on unparseable input.
//
// Returns an array of string tokens. Does NOT expand variables or globs.
// Zero external dependencies.

const HEREDOC_RE = /<<-?\s*'?(\w+)'?/;

/**
 * Split a shell command into argument tokens.
 *
 * @param {string} command
 * @returns {string[]}
 */
function extractArgs(command) {
  const cmd = String(command || "");

  // Heredoc: treat everything after the << marker as opaque
  if (HEREDOC_RE.test(cmd)) {
    const before = cmd.slice(0, cmd.search(HEREDOC_RE)).trim();
    const tokens = splitTokens(before);
    tokens.push("<<HEREDOC");
    return tokens;
  }

  return splitTokens(cmd);
}

function splitTokens(str) {
  const tokens = [];
  let current = "";
  let i = 0;

  while (i < str.length) {
    const ch = str[i];

    if (ch === "\\" && i + 1 < str.length) {
      current += str[i + 1];
      i += 2;
      continue;
    }

    if (ch === "'") {
      // Single-quoted string — no escapes inside
      i++;
      while (i < str.length && str[i] !== "'") {
        current += str[i++];
      }
      i++; // consume closing '
      continue;
    }

    if (ch === '"') {
      // Double-quoted string — backslash escapes apply
      i++;
      while (i < str.length && str[i] !== '"') {
        if (str[i] === "\\" && i + 1 < str.length) {
          current += str[i + 1];
          i += 2;
        } else {
          current += str[i++];
        }
      }
      i++; // consume closing "
      continue;
    }

    if (ch === " " || ch === "\t" || ch === "\n") {
      if (current.length > 0) {
        tokens.push(current);
        current = "";
      }
      i++;
      continue;
    }

    // Shell metacharacters that terminate a word but aren't path args
    if (ch === "|" || ch === ";" || ch === "&" || ch === ">" || ch === "<") {
      if (current.length > 0) {
        tokens.push(current);
        current = "";
      }
      i++;
      continue;
    }

    current += ch;
    i++;
  }

  if (current.length > 0) tokens.push(current);
  return tokens;
}

/**
 * Extract candidate file/directory path arguments from a command.
 * Returns tokens that look like paths (start with /, ./, ~, or contain a slash).
 * Filters out flags (starting with -) and shell keywords.
 *
 * @param {string} command
 * @returns {string[]}
 */
function extractPaths(command) {
  const KEYWORDS = new Set(["rm", "git", "curl", "wget", "sudo", "npm", "npx",
    "pip", "pip3", "dd", "mkfs", "shred", "chmod", "chown", "cp", "mv", "ln",
    "find", "rsync", "scp", "ssh", "bash", "sh", "node", "python", "python3"]);

  return extractArgs(command).filter((token) => {
    if (token.startsWith("-")) return false;
    if (KEYWORDS.has(token)) return false;
    if (token.startsWith("/") || token.startsWith("./") || token.startsWith("../")) return true;
    if (token.startsWith("~")) return true;
    if (token.includes("/")) return true;
    return false;
  });
}

module.exports = { extractArgs, extractPaths };
