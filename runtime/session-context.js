#!/usr/bin/env node
"use strict";

const fs     = require("fs");
const os     = require("os");
const path   = require("path");
const crypto = require("crypto");
const { emitEvent } = require("./telemetry");

function paths() {
  const baseDir = process.env.ECC_STATE_DIR
    ? path.resolve(process.env.ECC_STATE_DIR)
    : path.join(os.homedir(), ".openclaw", "agent-runtime-guard");
  return {
    baseDir,
    sessionFile: path.join(baseDir, "session-context.json"),
  };
}

function ensureBaseDir() {
  const { baseDir } = paths();
  if (!fs.existsSync(baseDir)) {
    fs.mkdirSync(baseDir, { recursive: true, mode: 0o700 });
  }
}

// ---------------------------------------------------------------------------
// Session ID — written once per SessionStart hook, read on every decide().
// Provides a real session boundary so getSessionRisk() partitions correctly.
// ---------------------------------------------------------------------------

function sessionIdPath() {
  return path.join(paths().baseDir, "current-session-id");
}

function currentSessionId() {
  try {
    const p = sessionIdPath();
    if (fs.existsSync(p)) return fs.readFileSync(p, "utf8").trim();
  } catch { /* best-effort */ }
  return null;
}

function startSession() {
  const id = crypto.randomBytes(8).toString("hex");
  try {
    const dir = paths().baseDir;
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true, mode: 0o700 });
    fs.writeFileSync(sessionIdPath(), id + "\n", { mode: 0o600 });
  } catch { /* best-effort */ }
  return id;
}

function emptyState() {
  return {
    sessions: {},
    recent: [],   // legacy field — kept for backward-compat
    updatedAt: null,
  };
}

// Module-level cache — valid for the lifetime of one Node.js process.
// Invalidated on saveState so trajectory + risk reads after a recordDecision
// within the same process observe the updated value.
let _stateCache = null;

function loadState() {
  if (_stateCache !== null) return _stateCache;
  const { sessionFile } = paths();
  try {
    _stateCache = JSON.parse(fs.readFileSync(sessionFile, "utf8"));
  } catch (err) {
    if (err && err.code !== "ENOENT") {
      try {
        const bak = `${sessionFile}.corrupt-${Date.now()}.bak`;
        fs.copyFileSync(sessionFile, bak);
        process.stderr.write(`[ARG] WARNING: session-context.json corrupt — backed up to ${path.basename(bak)}, resetting to defaults.\n`);
        emitEvent("session-context-corrupt", { file: "session-context.json", errCode: String(err.code || "parse-error") });
      } catch { /* backup is best-effort */ }
    }
    _stateCache = emptyState();
  }
  return _stateCache;
}

function saveState(state) {
  if (process.env.ECC_READONLY_CONTRACT === "1") { _stateCache = state; return; }
  _stateCache = null;
  try {
    ensureBaseDir();
    const { sessionFile } = paths();
    const data = JSON.stringify(state, null, 2) + "\n";
    const tmp = sessionFile + ".tmp";
    fs.writeFileSync(tmp, data, { mode: 0o600 });
    try {
      fs.renameSync(tmp, sessionFile);
    } catch {
      // Atomic rename failed (e.g. EPERM on Windows when file is locked by AV).
      try {
        fs.writeFileSync(sessionFile, data, { mode: 0o600 });
      } catch { /* best-effort fallback */ }
      try { fs.unlinkSync(tmp); } catch { /* tmp cleanup is best-effort */ }
    }
  } finally {
    // Always repopulate cache so callers in the same process see the new state,
    // even if the disk write failed.
    _stateCache = state;
  }
}

function sessionRecent(state) {
  const sid = currentSessionId();
  if (sid && state.sessions) {
    // In the partitioned format, a session with no prior decisions is a clean slate.
    // Do NOT fall back to the legacy `recent` field — that would bleed cross-session
    // trajectory into a new session. Fall back to `recent` only for old state files
    // that predate session partitioning (i.e., no `sessions` map at all).
    return Array.isArray(state.sessions[sid]) ? state.sessions[sid] : [];
  }
  return Array.isArray(state.recent) ? state.recent : [];
}

function getSessionRisk() {
  const state  = loadState();
  const recent = sessionRecent(state).slice(-8);
  let risk = 0;
  const highish    = recent.filter((item) => ["escalate", "block"].includes(item.action)).length;
  const destructive = recent.filter((item) => Array.isArray(item.reasonCodes) && item.reasonCodes.includes("destructive-delete-pattern")).length;
  if (highish >= 2)    risk += 2;
  if (destructive >= 2) risk += 1;
  return Math.min(3, risk);
}

function recordDecision(entry = {}) {
  const state = loadState();
  const next = {
    ts:          new Date().toISOString(),
    action:      String(entry.action    || "unknown"),
    riskLevel:   String(entry.riskLevel || "unknown"),
    reasonCodes: Array.isArray(entry.reasonCodes) ? entry.reasonCodes.slice(0, 8) : [],
  };

  const sid  = currentSessionId();
  const sessions = state.sessions || {};

  if (sid) {
    // Session-partitioned storage
    const sessionData = Array.isArray(sessions[sid]) ? sessions[sid].slice(-23) : [];
    sessionData.push(next);
    sessions[sid] = sessionData;
    // Also maintain legacy field for tools that read the old format
    const recent = Array.isArray(state.recent) ? state.recent.slice(-11) : [];
    recent.push(next);
    saveState({ sessions, recent, updatedAt: next.ts });
  } else {
    // No active session — legacy path
    const recent = Array.isArray(state.recent) ? state.recent.slice(-11) : [];
    recent.push(next);
    saveState({ sessions, recent, updatedAt: next.ts });
  }
  return next;
}

function getSessionTrajectory() {
  const windowMin   = Number(process.env.ECC_TRAJECTORY_WINDOW_MIN || "30");
  const state       = loadState();
  const recent      = sessionRecent(state);
  const windowStart = new Date(Date.now() - windowMin * 60 * 1000);
  const windowed    = recent.filter((item) => !item.ts || new Date(item.ts) >= windowStart);
  return {
    recentEscalations: windowed.filter((item) => ["escalate", "block"].includes(item.action)).length,
    recentReviews:     windowed.filter((item) => ["require-review", "review", "modify"].includes(item.action)).length,
    lastDecisionAt:    recent.length ? (recent[recent.length - 1]?.ts || null) : null,
  };
}

// Reset the in-process cache. Used by test scripts only to prevent cross-call
// state contamination when multiple runPreToolGate calls share one Node process.
function resetCache() {
  _stateCache = null;
}

module.exports = { paths, loadState, saveState, getSessionRisk, recordDecision, getSessionTrajectory, startSession, currentSessionId, resetCache };
