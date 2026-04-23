#!/usr/bin/env node
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");

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

function emptyState() {
  return {
    recent: [],
    updatedAt: null,
  };
}

// Module-level cache — valid for the lifetime of one Node.js process.
// Invalidated on saveState so trajectory + risk reads after a recordDecision
// within the same process observe the updated value.
let _stateCache = null;

function loadState() {
  if (_stateCache !== null) return _stateCache;
  try {
    const { sessionFile } = paths();
    _stateCache = JSON.parse(fs.readFileSync(sessionFile, "utf8"));
  } catch {
    _stateCache = emptyState();
  }
  return _stateCache;
}

function saveState(state) {
  _stateCache = null; // invalidate before write
  ensureBaseDir();
  const { sessionFile } = paths();
  const tmp = sessionFile + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(state, null, 2) + "\n", { mode: 0o600 });
  fs.renameSync(tmp, sessionFile);
}

function getSessionRisk() {
  const state = loadState();
  const recent = Array.isArray(state.recent) ? state.recent.slice(-8) : [];
  let risk = 0;
  const highish = recent.filter((item) => ["escalate", "block"].includes(item.action)).length;
  const destructive = recent.filter((item) => Array.isArray(item.reasonCodes) && item.reasonCodes.includes("destructive-delete-pattern")).length;
  if (highish >= 2) risk += 2;
  if (destructive >= 2) risk += 1;
  return Math.min(3, risk);
}

function recordDecision(entry = {}) {
  const state = loadState();
  const next = {
    ts: new Date().toISOString(),
    action: String(entry.action || "unknown"),
    riskLevel: String(entry.riskLevel || "unknown"),
    reasonCodes: Array.isArray(entry.reasonCodes) ? entry.reasonCodes.slice(0, 8) : [],
  };
  const recent = Array.isArray(state.recent) ? state.recent.slice(-11) : [];
  recent.push(next);
  saveState({ recent, updatedAt: next.ts });
  return next;
}

function getSessionTrajectory() {
  const windowMin = Number(process.env.ECC_TRAJECTORY_WINDOW_MIN || "30");
  const state = loadState();
  const recent = Array.isArray(state.recent) ? state.recent : [];
  const windowStart = new Date(Date.now() - windowMin * 60 * 1000);
  const windowed = recent.filter((item) => !item.ts || new Date(item.ts) >= windowStart);
  return {
    recentEscalations: windowed.filter((item) => ["escalate", "block"].includes(item.action)).length,
    recentReviews: windowed.filter((item) => ["require-review", "review", "modify"].includes(item.action)).length,
    lastDecisionAt: recent.length ? (recent[recent.length - 1]?.ts || null) : null,
  };
}

module.exports = { paths, loadState, saveState, getSessionRisk, recordDecision, getSessionTrajectory };
