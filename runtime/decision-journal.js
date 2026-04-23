#!/usr/bin/env node
"use strict";

const fs = require("fs");
const os = require("os");
const path = require("path");

function journalPaths() {
  const baseDir = process.env.ECC_STATE_DIR
    ? path.resolve(process.env.ECC_STATE_DIR)
    : path.join(os.homedir(), ".openclaw", "agent-runtime-guard");
  return {
    baseDir,
    logFile: path.join(baseDir, "decision-journal.jsonl"),
  };
}

function ensureBaseDir() {
  const { baseDir } = journalPaths();
  if (!fs.existsSync(baseDir)) {
    fs.mkdirSync(baseDir, { recursive: true, mode: 0o700 });
  }
}

function append(entry) {
  if (process.env.ECC_DECISION_JOURNAL === "0") return false;
  if (process.env.ARG_DECISION_JOURNAL === "0") {
    process.stderr.write("[ARG_DECISION_JOURNAL] deprecated — use ECC_DECISION_JOURNAL=0 instead\n");
    return false;
  }
  ensureBaseDir();
  const { logFile } = journalPaths();
  const record = {
    ts: new Date().toISOString(),
    kind: String(entry.kind || "decision"),
    action: String(entry.action || "unknown"),
    riskLevel: String(entry.riskLevel || "unknown"),
    riskScore: Number(entry.riskScore || 0),
    reasonCodes: Array.isArray(entry.reasonCodes) ? entry.reasonCodes.slice(0, 12) : [],
    tool: String(entry.tool || ""),
    branch: String(entry.branch || ""),
    targetPath: String(entry.targetPath || "").slice(0, 256),
    notes: String(entry.notes || "").slice(0, 256),
  };
  fs.appendFileSync(logFile, JSON.stringify(record) + "\n", { mode: 0o600 });
  return true;
}

module.exports = { append, journalPaths };
