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
    policyFile: path.join(baseDir, "learned-policy.json"),
  };
}

function ensureBaseDir() {
  const { baseDir } = paths();
  if (!fs.existsSync(baseDir)) {
    fs.mkdirSync(baseDir, { recursive: true, mode: 0o700 });
  }
}

function emptyPolicy() {
  return {
    learnedAllows: {},
    approvalCounts: {},
    suggestions: {},
    autoAllowOnce: {},
  };
}

// Module-level cache — valid for the lifetime of one Node.js process.
// Each hook invocation is a fresh process, so this never stales across calls.
// Invalidated immediately on any write so reads after consumeAutoAllowOnce
// observe the updated value within the same decide() call.
let _policyCache = null;

function loadPolicy() {
  if (_policyCache !== null) return _policyCache;
  try {
    const { policyFile } = paths();
    _policyCache = JSON.parse(fs.readFileSync(policyFile, "utf8"));
  } catch {
    _policyCache = emptyPolicy();
  }
  return _policyCache;
}

function savePolicy(policy) {
  _policyCache = null; // invalidate before write
  ensureBaseDir();
  const { policyFile } = paths();
  fs.writeFileSync(policyFile, JSON.stringify(policy, null, 2) + "\n", { mode: 0o600 });
}

function decisionKey(input = {}) {
  const tool = String(input.tool || "").trim().toLowerCase() || "unknown-tool";
  const cmd = String(input.command || "").trim().toLowerCase();
  const payloadClass = String(input.payloadClass || "A").trim().toUpperCase();
  const targetClass = /\b(prod|production|secrets?|credentials?|\.env|terraform|infra)\b/i.test(String(input.targetPath || ""))
    ? "sensitive-target"
    : "default-target";

  let commandClass = "generic";
  if (/\brm\s+(-[A-Za-z]*r[A-Za-z]*f|-{1,2}recursive)\b/.test(cmd)) commandClass = "destructive-delete";
  else if (/\bgit\s+push\b.*(--force|-f\b|--force-with-lease\b)/.test(cmd)) commandClass = "force-push";
  else if (/\bcurl\b.*\|\s*(ba)?sh\b|\bwget\b.*\|\s*(ba)?sh\b/.test(cmd)) commandClass = "remote-exec";
  else if (/\bnpx\s+(-y\b|--yes\b)/.test(cmd)) commandClass = "auto-download";
  else if (/^\s*sudo\s+/.test(cmd)) commandClass = "sudo";

  return [tool, commandClass, targetClass, payloadClass].join("|");
}

function getApprovalCount(input = {}) {
  const policy = loadPolicy();
  const key = decisionKey(input);
  return Number(policy.approvalCounts?.[key] || 0);
}

function isLearnedAllowed(input = {}) {
  const policy = loadPolicy();
  const key = decisionKey(input);
  return Boolean(policy.learnedAllows?.[key]);
}

function recordApproval(input = {}) {
  const policy = loadPolicy();
  const key = decisionKey(input);
  const current = Number(policy.approvalCounts?.[key] || 0) + 1;
  const now = new Date().toISOString();
  policy.approvalCounts[key] = current;

  if (current >= 3 && !policy.learnedAllows?.[key]) {
    const previous = policy.suggestions?.[key] || {};
    policy.suggestions[key] = {
      type: "learned-allow",
      status: "pending",
      approvalCount: current,
      createdAt: previous.createdAt || now,
      eligibleAt: previous.eligibleAt || now,
      updatedAt: now,
      lastApprovedAt: now,
      summary: key,
    };
  }

  savePolicy(policy);
  return current;
}

function setLearnedAllow(input = {}, enabled = true) {
  const policy = loadPolicy();
  const key = decisionKey(input);
  policy.learnedAllows[key] = Boolean(enabled);
  if (policy.suggestions?.[key]) {
    policy.suggestions[key].status = enabled ? "accepted" : "dismissed";
    policy.suggestions[key].updatedAt = new Date().toISOString();
  }
  savePolicy(policy);
  return key;
}

function listSuggestions() {
  const policy = loadPolicy();
  return Object.entries(policy.suggestions || {})
    .map(([key, value]) => ({ key, ...value }))
    .filter((item) => item.status === "pending")
    .sort((a, b) => (b.approvalCount || 0) - (a.approvalCount || 0));
}

function getSuggestion(key) {
  const policy = loadPolicy();
  const value = policy.suggestions?.[key];
  return value ? { key, ...value } : null;
}

function getSuggestionForInput(input = {}) {
  const key = decisionKey(input);
  return getSuggestion(key);
}

function acceptSuggestion(key) {
  const policy = loadPolicy();
  if (!policy.suggestions?.[key]) return false;
  const now = new Date().toISOString();
  policy.learnedAllows[key] = true;
  policy.suggestions[key].status = "accepted";
  policy.suggestions[key].acceptedAt = now;
  policy.suggestions[key].updatedAt = now;
  savePolicy(policy);
  return true;
}

function dismissSuggestion(key) {
  const policy = loadPolicy();
  if (!policy.suggestions?.[key]) return false;
  const now = new Date().toISOString();
  policy.suggestions[key].status = "dismissed";
  policy.suggestions[key].dismissedAt = now;
  policy.suggestions[key].updatedAt = now;
  savePolicy(policy);
  return true;
}

function listAcceptedSuggestions() {
  const policy = loadPolicy();
  return Object.entries(policy.suggestions || {})
    .map(([key, value]) => ({ key, ...value }))
    .filter((item) => item.status === "accepted")
    .sort((a, b) => String(b.updatedAt || "").localeCompare(String(a.updatedAt || "")));
}

function listDismissedSuggestions() {
  const policy = loadPolicy();
  return Object.entries(policy.suggestions || {})
    .map(([key, value]) => ({ key, ...value }))
    .filter((item) => item.status === "dismissed")
    .sort((a, b) => String(b.updatedAt || "").localeCompare(String(a.updatedAt || "")));
}

function summarizePolicy() {
  const policy = loadPolicy();
  return {
    learnedAllowCount: Object.values(policy.learnedAllows || {}).filter(Boolean).length,
    approvalKeyCount: Object.keys(policy.approvalCounts || {}).length,
    pendingSuggestionCount: listSuggestions().length,
    acceptedSuggestionCount: listAcceptedSuggestions().length,
    dismissedSuggestionCount: listDismissedSuggestions().length,
  };
}

function grantAutoAllowOnce(key) {
  const policy = loadPolicy();
  if (!policy.suggestions?.[key] || policy.suggestions[key].status !== "pending") return false;
  if (!policy.autoAllowOnce) policy.autoAllowOnce = {};
  policy.autoAllowOnce[key] = (Number(policy.autoAllowOnce[key] || 0)) + 1;
  savePolicy(policy);
  return true;
}

function consumeAutoAllowOnce(key) {
  const policy = loadPolicy();
  const count = Number(policy.autoAllowOnce?.[key] || 0);
  if (count <= 0) return false;
  if (!policy.autoAllowOnce) policy.autoAllowOnce = {};
  if (count <= 1) delete policy.autoAllowOnce[key];
  else policy.autoAllowOnce[key] = count - 1;
  savePolicy(policy);
  return true;
}

function hasAutoAllowOnce(key) {
  const policy = loadPolicy();
  return Number(policy.autoAllowOnce?.[key] || 0) > 0;
}

function getPolicyFacts(input = {}) {
  const key = decisionKey(input);
  const policy = loadPolicy();
  const suggestion = policy.suggestions?.[key] || null;
  return {
    key,
    approvalCount: Number(policy.approvalCounts?.[key] || 0),
    learnedAllow: Boolean(policy.learnedAllows?.[key]),
    pendingSuggestion: suggestion && suggestion.status === "pending" ? { key, ...suggestion } : null,
    acceptedSuggestion: suggestion && suggestion.status === "accepted" ? { key, ...suggestion } : null,
    dismissedSuggestion: suggestion && suggestion.status === "dismissed" ? { key, ...suggestion } : null,
  };
}

module.exports = {
  paths,
  loadPolicy,
  savePolicy,
  decisionKey,
  getApprovalCount,
  isLearnedAllowed,
  recordApproval,
  setLearnedAllow,
  listSuggestions,
  listAcceptedSuggestions,
  listDismissedSuggestions,
  getSuggestion,
  getSuggestionForInput,
  acceptSuggestion,
  dismissSuggestion,
  summarizePolicy,
  getPolicyFacts,
  grantAutoAllowOnce,
  consumeAutoAllowOnce,
  hasAutoAllowOnce,
};
