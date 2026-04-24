#!/usr/bin/env node
// adapter.js — OpenClaw PreToolUse adapter for Agent Runtime Guard.
//
// Reads OpenClaw hook input (stdin JSON) and routes through runtime.decide().
// Primary OpenClaw shape: { "tool": "shell", "cmd": "...", "cwd": "..." }
// Also accepts Claude Code shapes for cross-harness compatibility.
//
// In warn mode (default): prints warning to stderr, exits 0 (tool call proceeds).
// In block mode (ECC_ENFORCE=1): exits 2 (tool call aborted by harness).
//
// Patterns are loaded from claude/hooks/dangerous-patterns.json.
// Add project-specific entries there without editing this file.
//
// To enable block mode:  export ECC_ENFORCE=1

"use strict";

const fs   = require("fs");
const path = require("path");
const {
  readStdin, ENFORCE, hookLog, rateLimitCheck,
  runtimeDecision, runtimeContext,
  classifyCommandPayload, readSessionRisk, classifyPathSensitivity,
} = require("../../claude/hooks/hook-utils");

// ---------------------------------------------------------------------------
// Pattern loading
// ---------------------------------------------------------------------------

function loadPatterns() {
  const jsonPath = path.join(__dirname, "..", "..", "claude", "hooks", "dangerous-patterns.json");
  try {
    const raw  = fs.readFileSync(jsonPath, "utf8");
    const data = JSON.parse(raw);
    if (Array.isArray(data.patterns) && data.patterns.length > 0) {
      return data.patterns.map(({ name, pattern, severity, reason, flags }) => ({
        name,
        severity: severity || "medium",
        reason:   reason  || "",
        regex:    new RegExp(pattern, flags || ""),
      }));
    }
  } catch {
    // File missing or malformed — use built-in fallback patterns below.
  }

  return [
    { name: "rm recursive force",       severity: "critical", reason: "Recursive forced deletion is irreversible.",     regex: /\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive)\b/ },
    { name: "git push force",           severity: "critical", reason: "Force push can destroy shared history.",          regex: /\bgit\s+push\b.*(-f\b|--force\b|--force-with-lease\b)/ },
    { name: "curl pipe to shell",       severity: "critical", reason: "Executes untrusted remote code.",                 regex: /\bcurl\b.*\|\s*(ba)?sh\b|\bwget\b.*\|\s*(ba)?sh\b/ },
    { name: "DROP DATABASE / DROP TABLE", severity: "critical", reason: "Destroys database objects irreversibly.",       regex: /\b(DROP\s+(DATABASE|TABLE|SCHEMA)|TRUNCATE\s+TABLE)\b/i },
    { name: "npx -y auto-download",     severity: "high",     reason: "Downloads and executes remote npm packages.",     regex: /\bnpx\s+(-y\b|--yes\b)/ },
    { name: "sudo generic elevation",   severity: "medium",   reason: "Elevated privilege execution.",                  regex: /^\s*sudo\s+/ },
  ];
}

const dangerousPatterns = loadPatterns();

const SEVERITY_LABEL = { critical: "CRITICAL", high: "HIGH", medium: "WARN" };

// ---------------------------------------------------------------------------
// OpenClaw-specific input extraction
// ---------------------------------------------------------------------------

/**
 * Extract the shell command from an OpenClaw hook input.
 * OpenClaw primary shape: { "tool": "shell", "cmd": "..." }
 * Falls back to Claude Code shapes for cross-harness compatibility.
 */
function commandFromOpenClaw(input) {
  return String(
    input.cmd                   ||  // OpenClaw primary field
    input.input?.cmd            ||  // OpenClaw nested
    input.command               ||  // Claude Code direct
    input.args?.command         ||  // Claude Code args wrapper
    input.tool_input?.command   ||  // Claude Code tool_input wrapper
    input.input?.command        ||  // generic nested
    ""
  );
}

/**
 * Extract the working directory from an OpenClaw hook input.
 */
function cwdFromOpenClaw(input) {
  return String(
    input.cwd                   ||  // OpenClaw primary
    input.input?.cwd            ||  // OpenClaw nested
    input.args?.cwd             ||  // Claude Code args
    input.tool_input?.cwd       ||  // Claude Code tool_input
    ""
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

readStdin()
  .then((raw) => {
    if (!rateLimitCheck("openclaw-adapter")) {
      process.stdout.write(raw);
      return;
    }

    try {
      const input   = JSON.parse(raw || "{}");
      const command = commandFromOpenClaw(input).trim();

      if (!command) {
        process.stdout.write(raw);
        return;
      }

      const SEVERITY_RANK = { critical: 3, high: 2, medium: 1 };
      const hits = dangerousPatterns.filter(({ regex }) => regex.test(command));
      if (hits.length === 0) {
        process.stdout.write(raw);
        return;
      }
      hits.sort((a, b) => (SEVERITY_RANK[b.severity] || 0) - (SEVERITY_RANK[a.severity] || 0));
      const hit = hits[0];

      const label = SEVERITY_LABEL[hit.severity] || "WARN";
      console.error(`[Agent Runtime Guard] [${label}] Dangerous command pattern: "${hit.name}"`);
      if (hit.reason) {
        console.error(`[Agent Runtime Guard] Reason: ${hit.reason}`);
      }
      console.error(`[Agent Runtime Guard] Command: ${command.substring(0, 200)}${command.length > 200 ? "…" : ""}`);

      const targetPath      = cwdFromOpenClaw(input);
      const payloadClass    = classifyCommandPayload(command);
      const sessionRisk     = readSessionRisk();
      const pathSensitivity = classifyPathSensitivity(targetPath);

      let decision;
      let discovered;
      try {
        discovered = runtimeContext({ targetPath });
        decision = runtimeDecision({
          tool:        input.tool || "shell",
          command,
          targetPath,
          branch:      discovered.branch,
          projectRoot: discovered.projectRoot,
          configPath:  discovered.configPath,
          payloadClass,
          sessionRisk,
          pathSensitivity,
          notes: `openclaw-adapter:${hit.name}`,
        });
      } catch (runtimeErr) {
        const errMsg = runtimeErr instanceof Error ? runtimeErr.message : String(runtimeErr);
        console.error(`[Agent Runtime Guard] WARNING: runtime decision engine unavailable (${errMsg}). Applying severity fallback.`);
        if (ENFORCE && (hit.severity === "critical" || hit.severity === "high")) {
          console.error("[Agent Runtime Guard] BLOCKED (severity fallback — runtime unavailable).");
          try { hookLog("openclaw-adapter", "BLOCK", hit.name); } catch { /* non-fatal */ }
          process.exit(2);
        }
        try { hookLog("openclaw-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Proceeding in warn mode (runtime unavailable). Set ECC_ENFORCE=1 to tighten behavior.");
        process.stdout.write(raw);
        return;
      }

      if (payloadClass !== "A") {
        console.error(`[Agent Runtime Guard] Payload class: ${payloadClass}`);
      }
      if (pathSensitivity !== "low") {
        console.error(`[Agent Runtime Guard] Sensitive path detected (${pathSensitivity}): ${targetPath.substring(0, 120)}`);
      }
      if (sessionRisk > 0) {
        console.error(`[Agent Runtime Guard] Session risk: ${sessionRisk}`);
      }
      console.error(`[Agent Runtime Guard] Runtime decision: ${decision.action} (risk=${decision.riskLevel}:${decision.riskScore}, source=${decision.decisionSource})`);
      console.error(`[Agent Runtime Guard] Explanation: ${decision.explanation}`);
      if (decision.action === "escalate") {
        console.error("[Agent Runtime Guard] ESCALATION ROUTE: human gate required — do not auto-allow.");
      }
      const routeLane = decision.workflowRoute?.lane;
      if (routeLane && routeLane !== "direct") {
        console.error(`[Agent Runtime Guard] Workflow route: ${routeLane} → ${decision.workflowRoute?.suggestedTarget || "—"}`);
      }

      if (ENFORCE && decision.enforcementAction === "block") {
        console.error("[Agent Runtime Guard] BLOCKED by runtime policy.");
        console.error("[Agent Runtime Guard] To proceed, get explicit approval or adjust local learned policy intentionally.");
        try { hookLog("openclaw-adapter", "BLOCK", hit.name); } catch { /* non-fatal */ }
        process.exit(2);
      }

      if (discovered.branch) {
        console.error(`[Agent Runtime Guard] Detected branch: ${discovered.branch}`);
      }
      if (decision.promotionGuidance && decision.promotionGuidance.stage !== "new") {
        console.error(`[Agent Runtime Guard] Promotion: [${decision.promotionGuidance.stage}] ${decision.promotionGuidance.guidance}`);
        if (decision.promotionGuidance.cliHint) {
          console.error(`[Agent Runtime Guard] Promotion CLI: ${decision.promotionGuidance.cliHint}`);
        }
      }
      if (decision.pendingSuggestion) {
        console.error(`[Agent Runtime Guard] Pending local suggestion available: ./scripts/ecc-cli.sh runtime accept '${decision.pendingSuggestion}'`);
      }
      if (decision.actionPlan?.summary) {
        console.error(`[Agent Runtime Guard] Action plan: ${decision.actionPlan.summary}`);
      }
      if (Array.isArray(decision.actionPlan?.commands) && decision.actionPlan.commands.length > 0) {
        for (const item of decision.actionPlan.commands.slice(0, 3)) {
          console.error(`[Agent Runtime Guard] Suggested command: ${item}`);
        }
      }
      if (decision.actionPlan?.reviewType) {
        console.error(`[Agent Runtime Guard] Review type: ${decision.actionPlan.reviewType}`);
      }
      if (Array.isArray(decision.actionPlan?.modificationHints) && decision.actionPlan.modificationHints.length > 0) {
        for (const hint of decision.actionPlan.modificationHints.slice(0, 3)) {
          console.error(`[Agent Runtime Guard] Modification hint: ${hint}`);
        }
      }

      if (decision.action === "allow" && decision.decisionSource === "learned-allow") {
        try { hookLog("openclaw-adapter", "PASS", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Learned allow matched, proceeding in bounded-autonomy mode.");
      } else if (decision.action === "route") {
        try { hookLog("openclaw-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Route/escalation suggested, proceeding in warn mode.");
      } else if (decision.action === "require-tests") {
        try { hookLog("openclaw-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Require-tests suggested before continuing.");
      } else if (decision.action === "require-review") {
        try { hookLog("openclaw-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Review is required for this protected/high-risk context.");
      } else if (decision.action === "modify") {
        try { hookLog("openclaw-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Safer command/payload modification is recommended before continuing.");
      } else {
        try { hookLog("openclaw-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Proceeding in warn mode. Set ECC_ENFORCE=1 to tighten behavior.");
      }
    } catch {
      // Malformed input — non-blocking by design.
    }

    process.stdout.write(raw);
  })
  .catch(() => process.exit(0));
