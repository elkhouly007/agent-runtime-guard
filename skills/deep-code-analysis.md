# Skill: deep-code-analysis

---
name: deep-code-analysis
description: Perform a structured deep analysis of a codebase or module — architecture, patterns, risks, debt, and improvement opportunities
---

# Deep Code Analysis

Extract maximum insight from a codebase using a systematic multi-layer analysis.

## When to Use


## Layer 1: Structure Map

```bash
# Directory layout
find . -type d | grep -v node_modules | grep -v .git | head -50

# Entry points
grep -r "export default\|module.exports\|func main()\|public static void main" \
  --include="*.{ts,js,go,java,py}" -l | head -20

# Largest files (likely highest complexity)
find . -name "*.ts" -o -name "*.js" -o -name "*.go" | \
  xargs wc -l 2>/dev/null | sort -rn | head -20
```

## Layer 2: Dependency Graph

```bash
# External dependencies
cat package.json | node -e "
  const p = JSON.parse(require('fs').readFileSync('/dev/stdin'));
  const deps = {...p.dependencies, ...p.devDependencies};
  Object.entries(deps).forEach(([k,v]) => console.log(k, v));
" 2>/dev/null || cat go.mod || cat requirements.txt || cat Cargo.toml
```

## Layer 3: Pattern Detection

Look for architectural patterns and anti-patterns:

```bash
# Circular dependency hints
grep -r "require\|import" --include="*.ts" -l | head -30

# God object candidates (files importing many things)
grep -c "^import\|^const.*require" $(find src -name "*.ts") 2>/dev/null | \
  sort -t: -k2 -rn | head -10

# TODO/FIXME debt
grep -rn "TODO\|FIXME\|HACK\|XXX" --include="*.{ts,js,go,py,java}" | wc -l
```

## Layer 4: Risk Surface

```bash
# Security-sensitive patterns
grep -rn "eval(\|exec(\|system(\|dangerouslySetInnerHTML\|innerHTML" \
  --include="*.{ts,js,py,php}" | head -20

# Hardcoded values that should be config
grep -rn '"http[s]*://\|password.*=.*"[^"]\|api_key.*=" \|secret.*="' \
  --include="*.{ts,js,py,go}" | grep -v test | grep -v spec | head -20
```

## Layer 5: Test Coverage Signal

```bash
# Test-to-source ratio
SRC=$(find src -name "*.ts" ! -name "*.test.ts" ! -name "*.spec.ts" | wc -l)
TST=$(find src -name "*.test.ts" -o -name "*.spec.ts" | wc -l)
echo "Source files: $SRC  Test files: $TST  Ratio: $(echo "scale=2; $TST/$SRC" | bc)"
```

## Output Format

Summarize findings as:
- **Architecture**: What pattern is used, how well is it executed
- **Strengths**: What is done well and should be preserved
- **Debt**: Specific files/patterns that need attention, ordered by impact
- **Risks**: Security or reliability concerns, ordered by severity
- **Next 3 actions**: Concrete, specific, highest-leverage improvements
