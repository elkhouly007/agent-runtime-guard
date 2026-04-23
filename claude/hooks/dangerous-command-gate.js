#!/usr/bin/env node
// dangerous-command-gate.js — PreToolUse hook for the Bash tool.
//
// Scans the shell command about to be executed against a list of dangerous
// patterns. In warn mode (default) it prints a warning to stderr and lets
// the command proceed. In block mode (ECC_ENFORCE=1) it exits with code 2,
// causing Claude Code / OpenClaw to abort the tool call.
//
// Patterns are loaded from dangerous-patterns.json in the same directory.
// Add project-specific entries there without editing this file.
//
// To enable block mode:  export ECC_ENFORCE=1

"use strict";

const fs   = require("fs");
const path = require("path");
const { readStdin, commandFrom, ENFORCE, hookLog, rateLimitCheck, runtimeDecision, runtimeContext, classifyCommandPayload, readSessionRisk, classifyPathSensitivity } = require("./hook-utils");

// ---------------------------------------------------------------------------
// Pattern loading
// ---------------------------------------------------------------------------

function loadPatterns() {
  const jsonPath = path.join(__dirname, "dangerous-patterns.json");
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

  // Minimal fallback set covering the most critical risks.
  return [
    {
      name:     "rm recursive force",
      severity: "critical",
      reason:   "Recursive forced deletion is irreversible.",
      regex:    /\brm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive)\b/,
    },
    {
      name:     "git push force",
      severity: "critical",
      reason:   "Force push can destroy shared history.",
      regex:    /\bgit\s+push\b.*(-f\b|--force\b|--force-with-lease\b)/,
    },
    {
      name:     "curl pipe to shell",
      severity: "critical",
      reason:   "Executes untrusted remote code — violates no-unreviewed-remote-execution policy.",
      regex:    /\bcurl\b.*\|\s*(ba)?sh\b|\bwget\b.*\|\s*(ba)?sh\b/,
    },
    {
      name:     "DROP DATABASE / DROP TABLE",
      severity: "critical",
      reason:   "Destroys database objects irreversibly.",
      regex:    /\b(DROP\s+(DATABASE|TABLE|SCHEMA)|TRUNCATE\s+TABLE)\b/i,
    },
    {
      name:     "npx -y auto-download",
      severity: "high",
      reason:   "Downloads and executes remote npm packages without review.",
      regex:    /\bnpx\s+(-y\b|--yes\b)/,
    },
    {
      name:     "sudo generic elevation",
      severity: "medium",
      reason:   "Elevated privilege execution — confirm this is intentional.",
      regex:    /^\s*sudo\s+/,
    },
  ];
}

const dangerousPatterns = loadPatterns();

// ---------------------------------------------------------------------------
// Severity label helpers
// ---------------------------------------------------------------------------

const SEVERITY_LABEL = {
  critical: "CRITICAL",
  high:     "HIGH",
  medium:   "WARN",
};

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

readStdin()
  .then((raw) => {
    // Rate limiting: skip pattern scan if invocation bucket is empty.
    // The command still proceeds — we just don't scan it this cycle.
    if (!rateLimitCheck("dangerous-command-gate")) {
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

      // Collect ALL matching patterns, then act on the highest severity.
      // Using .find() would stop at the first JSON-order match, which could
      // silently downgrade severity when a medium pattern appears before a
      // critical one in the list (e.g. "sudo" before "rm -rf").
      const SEVERITY_RANK = { critical: 3, high: 2, medium: 1 };
      const hits = dangerousPatterns.filter(({ regex }) => regex.test(command));
      if (hits.length === 0) {
        process.stdout.write(raw);
        return;
      }
      hits.sort((a, b) => (SEVERITY_RANK[b.severity] || 0) - (SEVERITY_RANK[a.severity] || 0));
      const hit = hits[0];

      if (hit) {
        const label = SEVERITY_LABEL[hit.severity] || "WARN";
        // Output the pattern warning before any I/O that could throw, so the user
        // is always notified even if the runtime decision engine is unavailable.
        console.error(`[Agent Runtime Guard] [${label}] Dangerous command pattern: "${hit.name}"`);
        if (hit.reason) {
          console.error(`[Agent Runtime Guard] Reason: ${hit.reason}`);
        }
        console.error(`[Agent Runtime Guard] Command: ${command.substring(0, 200)}${command.length > 200 ? "…" : ""}`);

        const targetPath = String(input.cwd || input.args?.cwd || input.tool_input?.cwd || "");
        const payloadClass = classifyCommandPayload(command);
        const sessionRisk = readSessionRisk();
        const pathSensitivity = classifyPathSensitivity(targetPath);

        // Runtime decision — isolated try/catch so a corrupted policy file or
        // unexpected runtime error never silently bypasses the gate.
        let decision;
        let discovered;
        try {
          discovered = runtimeContext({ targetPath });
          decision = runtimeDecision({
            tool: "Bash",
            command,
            targetPath,
            branch: discovered.branch,
            projectRoot: discovered.projectRoot,
            configPath: discovered.configPath,
            payloadClass,
            sessionRisk,
            pathSensitivity,
            notes: `dangerous-command-gate:${hit.name}`,
          });
        } catch (runtimeErr) {
          const errMsg = runtimeErr instanceof Error ? runtimeErr.message : String(runtimeErr);
          console.error(`[Agent Runtime Guard] WARNING: runtime decision engine unavailable (${errMsg}). Applying severity fallback.`);
          if (ENFORCE && (hit.severity === "critical" || hit.severity === "high")) {
            console.error("[Agent Runtime Guard] BLOCKED (severity fallback — runtime unavailable).");
            try { hookLog("dangerous-command-gate", "BLOCK", hit.name); } catch { /* log I/O is non-fatal */ }
            process.exit(2);
          }
          try { hookLog("dangerous-command-gate", "WARN", hit.name); } catch { /* log I/O is non-fatal */ }
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
          try { hookLog("dangerous-command-gate", "BLOCK", hit.name); } catch { /* log I/O is non-fatal */ }
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
          try { hookLog("dangerous-command-gate", "PASS", hit.name); } catch { /* log I/O is non-fatal */ }
          console.error("[Agent Runtime Guard] Learned allow matched, proceeding in bounded-autonomy mode.");
        } else if (decision.action === "route") {
          try { hookLog("dangerous-command-gate", "WARN", hit.name); } catch { /* log I/O is non-fatal */ }
          console.error("[Agent Runtime Guard] Route/escalation suggested, proceeding in warn mode.");
        } else if (decision.action === "require-tests") {
          try { hookLog("dangerous-command-gate", "WARN", hit.name); } catch { /* log I/O is non-fatal */ }
          console.error("[Agent Runtime Guard] Require-tests suggested before continuing.");
        } else if (decision.action === "require-review") {
          try { hookLog("dangerous-command-gate", "WARN", hit.name); } catch { /* log I/O is non-fatal */ }
          console.error("[Agent Runtime Guard] Review is required for this protected/high-risk context.");
        } else if (decision.action === "modify") {
          try { hookLog("dangerous-command-gate", "WARN", hit.name); } catch { /* log I/O is non-fatal */ }
          console.error("[Agent Runtime Guard] Safer command/payload modification is recommended before continuing.");
        } else {
          try { hookLog("dangerous-command-gate", "WARN", hit.name); } catch { /* log I/O is non-fatal */ }
          console.error("[Agent Runtime Guard] Proceeding in warn mode. Set ECC_ENFORCE=1 to tighten behavior.");
        }
      }
    } catch {
      // Malformed input — non-blocking by design.
    }

    process.stdout.write(raw);
  })
  .catch(() => process.exit(0));
