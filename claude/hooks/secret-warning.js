#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const { readStdin, collectText, hookLog, rateLimitCheck } = require("./hook-utils");

// Load patterns from secret-patterns.json (same directory as this script).
// Falls back to the original 5 patterns if the file is missing or unreadable.
function loadPatterns() {
  const jsonPath = path.join(__dirname, "secret-patterns.json");
  try {
    const raw = fs.readFileSync(jsonPath, "utf8");
    const data = JSON.parse(raw);
    if (Array.isArray(data.patterns) && data.patterns.length > 0) {
      return data.patterns.map(({ name, pattern }) => ({
        name,
        pattern: new RegExp(pattern, "i"),
      }));
    }
  } catch {
    // File missing or malformed — use built-in fallback patterns below.
  }
  return [
    { name: "OpenAI-style API key", pattern: /\bsk-[A-Za-z0-9_-]{20,}\b/i },
    { name: "GitHub token",         pattern: /\bgh[pousr]_[A-Za-z0-9_]{20,}\b/i },
    { name: "AWS access key",       pattern: /\bAKIA[A-Z0-9]{16}\b/ },
    { name: "Slack token",          pattern: /\bxox[baprs]-[A-Za-z0-9-]{20,}\b/i },
    { name: "private key",          pattern: /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/ },
  ];
}

const secretPatterns = loadPatterns();

const { ENFORCE } = require("./hook-utils");

readStdin()
  .then((raw) => {
    if (!rateLimitCheck("secret-warning")) {
      process.stdout.write(raw);
      return;
    }
    try {
      const input = JSON.parse(raw || "{}");
      const text = collectText(input);
      const hit = secretPatterns.find(({ pattern }) => pattern.test(text));

      if (hit) {
        console.error(`[ECC Safe-Plus] Possible ${hit.name} detected in prompt input.`);
        console.error("[ECC Safe-Plus] Remove secrets before submitting. Prefer local env files that are not shared.");

        if (ENFORCE) {
          console.error("[ECC Safe-Plus] BLOCKED — ECC_ENFORCE=1 is active. Tool call aborted.");
          try { hookLog("secret-warning", "BLOCK", hit.name); } catch { /* log I/O is non-fatal */ }
          process.exit(2);
        }

        try { hookLog("secret-warning", "WARN", hit.name); } catch { /* log I/O is non-fatal */ }
      }
    } catch {
      // Keep hook behavior non-blocking for malformed input.
    }

    // Warn mode (default): echo stdin unchanged so the tool call proceeds.
    process.stdout.write(raw);
  })
  .catch(() => process.exit(0));
