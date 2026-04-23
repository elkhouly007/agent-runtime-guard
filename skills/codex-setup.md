# Skill: Codex Setup

## Trigger

Use when setting up Agent Runtime Guard for use with OpenAI Codex CLI — generating the `codex.md` file, configuring Codex-compatible agent definitions, and wiring ECC skills to the Codex CLI workflow.

## What Codex CLI Uses

Codex CLI reads:
- `codex.md` — project-level instructions (analogous to CLAUDE.md)
- `.agents/` directory — agent definitions in Codex format
- `.agents/skills/` — skill definitions

## Generating codex.md

```bash
# In your project root
cat > codex.md << 'EOF'
# Codex CLI Project Instructions

## Role
You are an expert software engineer working on this project.

## Code Standards
- Follow existing code patterns and conventions
- Write tests for all new functionality
- Never introduce security vulnerabilities

## Workflow
1. Read the relevant files before making changes
2. Make minimal, focused changes
3. Run tests after each change
4. Explain what you changed and why

## Project-Specific Rules
[Add project-specific rules here]
EOF
```

Key differences from CLAUDE.md:
- Codex does not auto-load `CLAUDE.md` — use `codex.md`
- No hooks support — instructions must be inline
- Simpler agent routing — no subagent delegation chains

## Agent Definitions for Codex

```yaml
# .agents/openai.yaml — Codex reads this for agent role assignment
name: code-reviewer
description: Expert code reviewer for security, correctness, and quality
instructions: |
  You are a senior code reviewer. When reviewing code:
  1. Check for security vulnerabilities (SQL injection, XSS, command injection)
  2. Check for logical errors and edge cases
  3. Check for performance issues
  4. Provide specific, actionable feedback with line numbers
  5. Rank findings by severity: CRITICAL > HIGH > MEDIUM > LOW
tools:
  - read_file
  - list_directory
```

```yaml
# Multiple agents in separate files under .agents/
# .agents/architect.yaml
name: architect
description: System architecture and design specialist
instructions: |
  You are a senior software architect. When designing systems:
  1. Consider scalability and maintainability from the start
  2. Document architectural decisions and trade-offs
  3. Prefer proven patterns over novel approaches
  4. Define clear interfaces between components
```

## Skills for Codex

Codex skills live in `.agents/skills/` as markdown files:

```markdown
<!-- .agents/skills/code-review.md -->
# SKILL.md: Code Review

## Trigger
When asked to review code or a PR.

## Steps
1. Read all changed files
2. Check against security checklist
3. Report findings by severity
4. Suggest specific fixes

## Output
Ranked findings with file:line references and fix suggestions.
```

## Minimal ECC Codex Integration

To use Agent Runtime Guard with Codex, create a minimal wiring:

```bash
# In your project
mkdir -p .agents/skills

# Copy key ECC skills to Codex format
for skill in code-review security-review plan-feature refactor tdd; do
    cp tools/ecc-safe-plus/skills/${skill}.md .agents/skills/${skill}.md
done

# Generate codex.md from ECC rules
cat tools/ecc-safe-plus/rules/common/coding-style.md \
    tools/ecc-safe-plus/rules/common/security.md \
    > codex.md
```

## Limitations vs Claude Code

| Feature | Claude Code | Codex CLI |
|---|---|---|
| Subagent delegation | ✅ Full support | ❌ Not supported |
| Hooks | ✅ Full support | ❌ Not supported |
| MCP servers | ✅ Full support | ⚠️ Limited |
| Rule auto-loading | ✅ Via CLAUDE.md | ✅ Via codex.md |
| Skills | ✅ Via slash commands | ⚠️ Manual invocation |

For full ECC capability, use Claude Code. Codex integration provides a useful subset for teams already using Codex CLI.

## Constraints

- `codex.md` has a size limit — keep it focused and under 4,000 tokens.
- Do not copy ECC infrastructure files (scripts, tests, modules) to the Codex agent directory — only skills and agent definitions.
- Test Codex agent definitions by running `codex` locally before committing to `.agents/`.
