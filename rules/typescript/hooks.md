# TypeScript + ARG Hooks

TypeScript-specific ARG hook considerations.

## Secret Scanning

ARG `secret-warning.js` scans all tool call inputs. TypeScript/JavaScript-specific risks:
- `process.env.API_KEY` in output piped to Bash will trigger the scanner
- `.env` file contents echoed to terminal will be caught
- `console.log(config)` where config contains API keys will trigger warnings

Best practice: access secrets only at runtime, never log them, and never embed them in source.

## Dangerous Command Patterns in TypeScript Projects

Common TypeScript project commands that may trigger ARG:
- `npx` with untrusted packages (network download + execution)
- `npm install --force` (bypasses integrity checks)
- Build scripts that invoke shell commands with dynamic strings
- `rimraf` or equivalent destructive file operations

## Node.js-Specific Safety

When running Node.js scripts via the Bash tool:
- Pass command-line arguments as an array where possible rather than constructing shell strings
- `child_process.execFile()` over `exec()` — execFile does not pass arguments through a shell
- Validate environment variables before using them in shell-adjacent operations

## Type Safety in Hook Configurations

If writing custom hooks or extensions in TypeScript:
- Type all hook event objects explicitly — do not use `any` for event data
- Validate all fields that come from tool call inputs before acting on them
- Use discriminated unions to handle different tool types safely
