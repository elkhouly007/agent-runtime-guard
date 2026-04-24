#!/usr/bin/env node
// adapter.js — OpenCode PreToolUse adapter for Agent Runtime Guard.
//
// Reads OpenCode hook input (stdin JSON) and routes through runtime.decide().
// OpenCode inherits Claude Code's hook format:
//   { "tool_name": "Bash", "tool_input": { "command": "..." }, "args": { "command": "..." } }
//
// In warn mode (default): prints warning to stderr, exits 0 (tool call proceeds).
// In block mode (ECC_ENFORCE=1): exits 2 (tool call aborted by harness).
//
// Patterns are loaded from claude/hooks/dangerous-patterns.json.
// Add project-specific entries there without editing this file.
//
// To enable block mode:  export ECC_ENFORCE=1
//
// Wiring: in your OpenCode config, add this script as a PreToolUse hook on
// shell/bash tool calls. Point the command at the absolute path of this file.

"use strict";

const fs   = require("fs");
const path = require("path");
const {
  readStdin, commandFrom, ENFORCE, hookLog, rateLimitCheck,
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
    { name: "rm recursive force",         severity: "critical", reason: "Recursive forced deletion is irreversible.",     regex: /\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive)\b/ },
    { name: "git push force",             severity: "critical", reason: "Force push can destroy shared history.",          regex: /\bgit\s+push\b.*(-f\b|--force\b|--force-with-lease\b)/ },
    { name: "curl pipe to shell",         severity: "critical", reason: "Executes untrusted remote code.",                 regex: /\bcurl\b.*\|\s*(ba)?sh\b|\bwget\b.*\|\s*(ba)?sh\b/ },
    { name: "DROP DATABASE / DROP TABLE", severity: "critical", reason: "Destroys database objects irreversibly.",         regex: /\b(DROP\s+(DATABASE|TABLE|SCHEMA)|TRUNCATE\s+TABLE)\b/i },
    { name: "npx -y auto-download",       severity: "high",     reason: "Downloads and executes remote npm packages.",     regex: /\bnpx\s+(-y\b|--yes\b)/ },
    { name: "sudo generic elevation",     severity: "medium",   reason: "Elevated privilege execution.",                  regex: /^\s*sudo\s+/ },
  ];
}

const dangerousPatterns = loadPatterns();

const SEVERITY_LABEL = { critical: "CRITICAL", high: "HIGH", medium: "WARN" };

// ---------------------------------------------------------------------------
// OpenCode uses the same hook input format as Claude Code.
// commandFrom() from hook-utils handles all relevant shapes.
// ---------------------------------------------------------------------------

function cwdFromOpenCode(input) {
  return String(
    input.cwd               ||
    input.args?.cwd         ||
    input.tool_input?.cwd   ||
    input.input?.cwd        ||
    ""
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

readStdin()
  .then((raw) => {
    if (!rateLimitCheck("opencode-adapter")) {
      process.stdout.write(raw);
      return;
    }

    try {
      const input   = JSON.parse(raw || "{}");
      const command = commandFrom(input).trim();

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

      const targetPath      = cwdFromOpenCode(input);
      const payloadClass    = classifyCommandPayload(command);
      const sessionRisk     = readSessionRisk();
      const pathSensitivity = classifyPathSensitivity(targetPath);

      let decision;
      let discovered;
      try {
        discovered = runtimeContext({ targetPath });
        decision = runtimeDecision({
          tool:        input.tool_name || input.tool || "Bash",
          command,
          targetPath,
          branch:      discovered.branch,
          projectRoot: discovered.projectRoot,
          configPath:  discovered.configPath,
          payloadClass,
          sessionRisk,
          pathSensitivity,
          notes: `opencode-adapter:${hit.name}`,
        });
      } catch (runtimeErr) {
        const errMsg = runtimeErr instanceof Error ? runtimeErr.message : String(runtimeErr);
        console.error(`[Agent Runtime Guard] WARNING: runtime decision engine unavailable (${errMsg}). Applying severity fallback.`);
        if (ENFORCE && (hit.severity === "critical" || hit.severity === "high")) {
          console.error("[Agent Runtime Guard] BLOCKED (severity fallback — runtime unavailable).");
          try { hookLog("opencode-adapter", "BLOCK", hit.name); } catch { /* non-fatal */ }
          process.exit(2);
        }
        try { hookLog("opencode-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
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
        try { hookLog("opencode-adapter", "BLOCK", hit.name); } catch { /* non-fatal */ }
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
        try { hookLog("opencode-adapter", "PASS", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Learned allow matched, proceeding in bounded-autonomy mode.");
      } else if (decision.action === "route") {
        try { hookLog("opencode-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Route/escalation suggested, proceeding in warn mode.");
      } else if (decision.action === "require-tests") {
        try { hookLog("opencode-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Require-tests suggested before continuing.");
      } else if (decision.action === "require-review") {
        try { hookLog("opencode-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Review is required for this protected/high-risk context.");
      } else if (decision.action === "modify") {
        try { hookLog("opencode-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Safer command/payload modification is recommended before continuing.");
      } else {
        try { hookLog("opencode-adapter", "WARN", hit.name); } catch { /* non-fatal */ }
        console.error("[Agent Runtime Guard] Proceeding in warn mode. Set ECC_ENFORCE=1 to tighten behavior.");
      }
    } catch {
      // Malformed input — non-blocking by design.
    }

    process.stdout.write(raw);
  })
  .catch(() => process.exit(0));
