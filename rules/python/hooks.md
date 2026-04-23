# Python + ARG Hooks

Python-specific ARG hook considerations.

## Subprocess Safety

ARG `dangerous-command-gate.js` intercepts Bash tool calls. Python code that uses `subprocess.run()` with dangerous patterns will not be caught by ARG hooks unless it is run via the Bash tool.

When writing Python scripts that will be executed via the Claude Code Bash tool:
- Avoid `shell=True` in subprocess calls — ARG cannot analyze the shell command string safely.
- Prefer passing commands as lists: `subprocess.run(["git", "push", "origin", "main"])`.
- Document why any `shell=True` usage is necessary in a comment adjacent to the call.

## Secret Detection

ARG `secret-warning.js` scans all tool call inputs. This means:
- Python environment setup commands that echo `OPENAI_API_KEY` will be intercepted.
- Python scripts that print secrets to stdout will be caught when run via Bash.
- Use environment variables or a secrets manager. Never hardcode secrets in Python source that will be visible in tool call inputs.

## Python-Specific Dangerous Patterns

Patterns that should trigger caution (and may trigger ARG warnings):
- `subprocess.run("rm -rf ..." , shell=True)` — file deletion
- `eval()` and `exec()` on user-provided strings — arbitrary code execution
- `os.system()` — shell command execution without argument escaping
- Writing to system directories or modifying system Python packages

## Virtual Environment Best Practices

Always activate a virtual environment before running Python in a session. This prevents:
- Accidentally modifying system Python packages
- ARG-irrelevant package conflicts surfacing as dangerous errors
- Dependency version surprises between projects
