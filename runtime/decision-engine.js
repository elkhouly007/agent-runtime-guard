#!/usr/bin/env node
"use strict";

const { score } = require("./risk-score");
const { append } = require("./decision-journal");
const { getApprovalCount, isLearnedAllowed, decisionKey, getSuggestionForInput, getPolicyFacts, hasAutoAllowOnce, consumeAutoAllowOnce } = require("./policy-store");
const { getSessionRisk, recordDecision, getSessionTrajectory } = require("./session-context");
const { loadProjectPolicy } = require("./project-policy");
const { discover } = require("./context-discovery");
const { build } = require("./action-planner");
const { evaluate } = require("./promotion-guidance");
const { recommend } = require("./workflow-router");

function decide(input = {}) {
  if (process.env.ECC_KILL_SWITCH === "1") {
    return {
      action: "block",
      enforcementAction: "block",
      riskScore: 10,
      riskLevel: "critical",
      reasonCodes: ["kill-switch"],
      confidence: 1,
      decisionSource: "kill-switch",
      policyKey: "kill-switch",
      explanation: "kill-switch engaged — all decisions blocked",
      pendingSuggestion: null,
      promotionGuidance: null,
      promotionState: null,
      promotionLifecycleSummary: null,
      workflowRoute: null,
      actionPlan: null,
      trajectoryNudge: null,
      context: {},
    };
  }

  const discovered = discover(input);
  const explicit = Object.fromEntries(
    Object.entries(input).filter(([, value]) => value !== "" && value != null)
  );
  const projectPolicy = loadProjectPolicy({ ...discovered, ...explicit });
  const mergedMarkers = [...new Set([
    ...(Array.isArray(projectPolicy.projectMarkers) ? projectPolicy.projectMarkers : []),
    ...(Array.isArray(discovered.projectMarkers) ? discovered.projectMarkers : []),
  ].filter(Boolean))];
  const enriched = {
    ...projectPolicy,
    ...discovered,
    ...explicit,
    projectMarkers: mergedMarkers,
    primaryStack: explicit.primaryStack || projectPolicy.primaryStack || discovered.primaryStack || null,
    repeatedApprovals: input.repeatedApprovals != null ? input.repeatedApprovals : getApprovalCount({ ...projectPolicy, ...discovered, ...explicit }),
    sessionRisk: input.sessionRisk != null ? input.sessionRisk : getSessionRisk(),
  };

  const learnedAllow = isLearnedAllowed(enriched);
  const risk = score(enriched);
  const policyKey = decisionKey(enriched);
  let action = "allow";
  let source = "risk-engine";

  if (risk.level === "critical") action = "block";
  else if (risk.level === "high" && risk.reasons.includes("protected-branch")) action = "require-review";
  else if (risk.level === "high" && risk.reasons.includes("destructive-delete-pattern")) action = learnedAllow ? "allow" : "require-tests";
  else if (risk.level === "high") action = "escalate";
  else if (risk.level === "medium" && risk.reasons.includes("sensitive-target-path")) action = learnedAllow ? "allow" : "modify";
  else if (risk.level === "medium") action = learnedAllow ? "allow" : "route";
  else action = "allow";

  if (learnedAllow && risk.level !== "critical" && (risk.level !== "high" || risk.reasons.includes("destructive-delete-pattern"))) {
    source = "learned-allow";
  }

  if (source !== "learned-allow" && risk.level !== "critical" && risk.level !== "high" && action !== "allow" && hasAutoAllowOnce(policyKey)) {
    consumeAutoAllowOnce(policyKey);
    action = "allow";
    source = "auto-allow-once";
  }

  const trajectory = getSessionTrajectory();
  const trajectoryThreshold = Number(process.env.ECC_TRAJECTORY_THRESHOLD || "3");
  let trajectoryNudge = null;
  if (source !== "learned-allow" && source !== "auto-allow-once" && trajectory.recentEscalations >= trajectoryThreshold) {
    if (action === "allow") { action = "route"; trajectoryNudge = "allow\u2192route"; }
    else if (action === "route") { action = "require-review"; trajectoryNudge = "route\u2192require-review"; }
    else if (action === "require-review") { action = "escalate"; trajectoryNudge = "require-review\u2192escalate"; }
    if (trajectoryNudge) source = "trajectory-nudge";
  }

  const pendingSuggestion = getSuggestionForInput(enriched);
  const policyFacts = getPolicyFacts(enriched);
  const promotionState = policyFacts.acceptedSuggestion || policyFacts.dismissedSuggestion || policyFacts.pendingSuggestion || null;
  const explanationParts = [
    `action=${action}`,
    `risk=${risk.level}:${risk.score}`,
    `source=${source}`,
  ];
  if (risk.reasons.length > 0) explanationParts.push(`reasons=${risk.reasons.join(",")}`);
  if (pendingSuggestion?.status === "pending") explanationParts.push(`suggestion=pending:${policyKey}`);
  if (learnedAllow && source === "learned-allow") explanationParts.push("learned-allow=matched");
  if (source === "auto-allow-once") explanationParts.push("auto-allow-once=consumed");
  if (trajectoryNudge) explanationParts.push(`trajectory-nudge=${trajectoryNudge} (${trajectory.recentEscalations} recent escalations in session)`);
  if (projectPolicy.projectScope && projectPolicy.projectScope !== 'global') explanationParts.push(`project=${projectPolicy.projectScope}`);
  if (discovered.primaryStack) explanationParts.push(`stack=${discovered.primaryStack}`);
  if (discovered.hasConfig === false && discovered.primaryStack) explanationParts.push('config=missing');
  if (projectPolicy.trustPosture) explanationParts.push(`trust=${projectPolicy.trustPosture}`);

  const actionPlan = build(action, enriched, risk, discovered, policyFacts);
  const promotionGuidance = evaluate(policyFacts, risk);

  if (promotionGuidance.stage !== "new" && promotionGuidance.stage !== "promoted") {
    explanationParts.push(`promotion=${promotionGuidance.stage}`);
  }

  const lifecycleSummary = promotionState
    ? [
        promotionState.createdAt ? `created=${promotionState.createdAt}` : null,
        promotionState.eligibleAt ? `eligible=${promotionState.eligibleAt}` : null,
        promotionState.acceptedAt ? `accepted=${promotionState.acceptedAt}` : null,
        promotionState.dismissedAt ? `dismissed=${promotionState.dismissedAt}` : null,
        promotionState.lastApprovedAt ? `last-approved=${promotionState.lastApprovedAt}` : null,
      ].filter(Boolean).join(" | ")
    : null;

  const workflowRoute = recommend(action, enriched, risk, discovered);

  const result = {
    action,
    enforcementAction: ["block", "escalate", "require-review"].includes(action) ? "block" : "warn",
    riskScore: risk.score,
    riskLevel: risk.level,
    reasonCodes: risk.reasons,
    confidence: source === "learned-allow"
      ? 0.92
      : risk.level === "low"
        ? 0.9
        : risk.level === "medium"
          ? 0.75
          : risk.level === "high"
            ? 0.55
            : 0.95,
    decisionSource: source,
    policyKey,
    explanation: explanationParts.join(" | "),
    pendingSuggestion: pendingSuggestion?.status === "pending" ? pendingSuggestion.key : null,
    promotionGuidance,
    promotionState,
    promotionLifecycleSummary: lifecycleSummary,
    workflowRoute,
    actionPlan,
    trajectoryNudge,
    context: risk.context,
  };

  append({
    kind: "runtime-decision",
    action: result.action,
    riskLevel: result.riskLevel,
    riskScore: result.riskScore,
    reasonCodes: result.reasonCodes,
    tool: input.tool || "",
    branch: input.branch || "",
    targetPath: input.targetPath || "",
    notes: `${source}${input.notes ? ` | ${input.notes}` : ""}`,
  });

  recordDecision({
    action: result.action,
    riskLevel: result.riskLevel,
    reasonCodes: result.reasonCodes,
  });

  return result;
}

module.exports = { decide };
