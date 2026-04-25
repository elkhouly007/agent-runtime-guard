#!/usr/bin/env node
"use strict";

// glob-match.js — Zero-dependency glob pattern matcher.
//
// Supports: ** (any path segments), * (any chars within one segment), ? (one char),
// [abc] character classes, ! leading negation, ${projectRoot} variable substitution.
//
// Used by runtime/contract.js for scope matching. No minimatch/picomatch dependency.

const path = require("path");

const SEP = /[\\/]/;

/**
 * Compile a glob pattern string to a RegExp.
 * @param {string} pattern
 * @param {{ nocase?: boolean }} opts
 * @returns {RegExp}
 */
function compileGlob(pattern, opts = {}) {
  const nocase = opts.nocase !== false && process.platform === "win32";
  let src = "";
  let i = 0;
  while (i < pattern.length) {
    const ch = pattern[i];
    if (ch === "*" && pattern[i + 1] === "*") {
      // ** — match zero or more path segments including separators
      src += "(?:[\\s\\S]*?)?";
      i += 2;
      if (pattern[i] === "/" || pattern[i] === "\\") i++;
    } else if (ch === "*") {
      // * — match anything except separator
      src += "[^\\\\/]*";
      i++;
    } else if (ch === "?") {
      src += "[^\\\\/]";
      i++;
    } else if (ch === "[") {
      // Character class — pass through until closing ]
      const end = pattern.indexOf("]", i + 1);
      if (end === -1) {
        src += "\\[";
        i++;
      } else {
        src += pattern.slice(i, end + 1);
        i = end + 1;
      }
    } else {
      // Escape regex metacharacters
      src += ch.replace(/[.+^${}()|\\]/g, "\\$&");
      i++;
    }
  }
  const flags = nocase ? "i" : "";
  return new RegExp(`^${src}$`, flags);
}

/**
 * Match a file path against a glob pattern.
 *
 * @param {string} filePath  — absolute or project-relative path (forward slashes)
 * @param {string} pattern   — glob pattern; may start with ! for negation
 * @param {object} [ctx]     — { projectRoot?: string }
 * @returns {boolean}
 */
function globMatch(filePath, pattern, ctx = {}) {
  let negated = false;
  let pat = String(pattern || "");

  if (pat.startsWith("!")) {
    negated = true;
    pat = pat.slice(1);
  }

  // Substitute ${projectRoot}
  if (ctx.projectRoot) {
    pat = pat.replace(/\$\{projectRoot\}/g, ctx.projectRoot.replace(/\\/g, "/"));
  }

  // Normalize separators in path
  const normalized = String(filePath || "").replace(/\\/g, "/");

  const re = compileGlob(pat.replace(/\\/g, "/"));
  const matched = re.test(normalized);
  return negated ? !matched : matched;
}

/**
 * Test a path against an array of patterns (later patterns override earlier ones).
 * Starts as denied (false). Each matching pattern flips the result.
 *
 * @param {string} filePath
 * @param {string[]} patterns
 * @param {object} [ctx]
 * @returns {boolean}
 */
function globMatchAny(filePath, patterns, ctx = {}) {
  let result = false;
  for (const pattern of patterns) {
    const negated = String(pattern || "").startsWith("!");
    if (globMatch(filePath, pattern, ctx)) {
      result = !negated;
    }
  }
  return result;
}

module.exports = { globMatch, globMatchAny, compileGlob };
