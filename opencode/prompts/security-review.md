# Security Review

Review local code and configuration for security issues. Do not contact external services.

## Focus

- Secrets in code, prompts, logs, fixtures, or config.
- User input reaching shell, SQL, templates, file paths, or network calls.
- Auth, authorization, and session handling.
- Dependency execution paths.
- Unsafe file writes or path traversal.
- Data that may leave the machine.
- Permission auto-approval or trust expansion.

## Rules

- Be explicit about exploit path and impact.
- Distinguish confirmed issues from hypotheses.
- Prefer local mitigations.
- Do not enable scanners that download packages or upload code.

## Output

Return findings by severity, then practical remediation steps.
