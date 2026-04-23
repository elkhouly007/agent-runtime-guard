#!/usr/bin/env node
"use strict";

const { evaluate } = require("./promotion-guidance");

function unique(items = []) {
  return [...new Set(items.filter(Boolean))];
}

function verificationCommandsForStack(primaryStack = "", targetPath = "") {
  switch (String(primaryStack || "").trim().toLowerCase()) {
    case "node":
    case "typescript":
      return ["npm test", "npm run lint"];
    case "python":
      return ["pytest"];
    case "golang":
      return ["go test ./..."];
    case "rust":
      return ["cargo test"];
    case "java":
    case "kotlin":
      return ["./gradlew test"];
    default:
      if (/\b(node|ts|tsx|javascript|typescript)\b/i.test(targetPath)) return ["npm test", "npm run lint"];
      if (/\bpython|\.py\b/i.test(targetPath)) return ["pytest"];
      return [];
  }
}

function build(action, input = {}, risk = {}, discovered = {}, policyFacts = {}) {
  const reasons = Array.isArray(risk.reasons) ? risk.reasons : [];
  const branch = String(input.branch || discovered.branch || "").trim();
  const targetPath = String(input.targetPath || "").trim();
  const primaryStack = String(discovered.primaryStack || input.primaryStack || "").trim();
  const approvalCount = Number(policyFacts.approvalCount || 0);
  const pendingSuggestion = policyFacts.pendingSuggestion || null;
  const promotion = evaluate(policyFacts, risk);

  if (action === "require-tests") {
    const commands = verificationCommandsForStack(primaryStack, targetPath);
    if (commands.length === 0) commands.push("run the nearest relevant test suite", "run the project lint/check command");
    if (approvalCount >= 2) commands.push("promote this verification pattern into a reviewed project default if it keeps recurring");
    return {
      summary: pendingSuggestion
        ? "Run verification now, then consider accepting the pending learned policy if this pattern keeps repeating safely."
        : "Run verification before allowing this risky change to continue.",
      commands: unique(commands),
      reviewType: null,
      modificationHints: [],
      promotionHint: promotion.stage !== "new" ? promotion.guidance : null,
    };
  }

  if (action === "require-review") {
    const reviewType = reasons.includes("protected-branch")
      ? "protected-branch-review"
      : "high-risk-review";
    return {
      summary: pendingSuggestion
        ? "A repeated high-risk pattern exists, but reviewer confirmation is still required before continuing."
        : "Require human or reviewer confirmation before continuing in this context.",
      commands: [],
      reviewType,
      modificationHints: branch ? [`review changes intended for branch ${branch}`] : ["review high-risk change intent"],
      promotionHint: promotion.stage === "ineligible" ? promotion.guidance : (promotion.stage !== "new" ? promotion.guidance : null),
    };
  }

  if (action === "modify") {
    const hints = [];
    if (reasons.includes("sensitive-target-path")) {
      hints.push("reduce scope to the minimum necessary path", "avoid touching secrets or production material unless explicitly required");
    }
    if (reasons.includes("auto-download-pattern")) {
      hints.push("replace auto-download execution with a pinned, reviewed installation step");
    }
    if (approvalCount >= 2) hints.push("if this narrowed form keeps being approved, promote it to a reviewed local pattern");
    if (hints.length === 0) hints.push("rewrite the command in a narrower and safer form");
    return {
      summary: pendingSuggestion
        ? "A safer form is recommended now, and there is enough repetition to consider reviewing a reusable local policy."
        : "Modify the action into a safer form before proceeding.",
      commands: [],
      reviewType: null,
      modificationHints: unique(hints),
      promotionHint: promotion.stage !== "new" ? promotion.guidance : null,
    };
  }

  if (action === "route") {
    return {
      summary: pendingSuggestion
        ? "Use the safer/default workflow now, and review the pending local suggestion if the route keeps repeating safely."
        : "Route this task through the safer/default workflow instead of direct execution.",
      commands: [],
      reviewType: "workflow-review",
      modificationHints: [],
      promotionHint: promotion.stage !== "new" ? promotion.guidance : null,
    };
  }

  return {
    summary: "No extra action plan required.",
    commands: [],
    reviewType: null,
    modificationHints: [],
    promotionHint: promotion.stage === "promoted" ? promotion.guidance : null,
  };
}

module.exports = { build };
