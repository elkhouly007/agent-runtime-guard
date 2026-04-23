# Skill: capability-audit

---
name: capability-audit
description: Audit the full set of agents, rules, and skills available in this ARG installation to identify gaps, redundancies, and coverage holes
---

# Capability Audit

Map what ARG can do, find gaps, and prioritize what to add next.

## When to Use


## Run the Audit

```bash
# Count all capability surfaces
echo "=== Agents ==="
ls agents/*.md | grep -v README | grep -v ROUTING | wc -l

echo "=== Rules ==="
find rules -name "*.md" | grep -v README | wc -l

echo "=== Skills ==="
ls skills/*.md | grep -v README | wc -l

echo "=== Hooks ==="
ls claude/hooks/*.js | wc -l
```

## Coverage Matrix

Check each domain has the necessary agent types:

| Domain | Reviewer | Build Resolver | Patterns | Security |
|--------|----------|----------------|----------|----------|
| Python | ? | ? | ? | ? |
| TypeScript | ? | ? | ? | ? |
| Go | ? | ? | ? | ? |
| Rust | ? | ? | ? | ? |
| Java | ? | ? | ? | ? |
| C++ | ? | ? | ? | ? |
| Kotlin | ? | ? | ? | ? |
| C# | ? | ? | ? | ? |
| Dart/Flutter | ? | ? | ? | ? |
| Swift | ? | ? | ? | ? |

Verify each row with:
```bash
for lang in python typescript go rust java cpp kotlin csharp dart flutter swift; do
  agent=$(ls agents/ | grep -i "$lang" | head -5 | tr '\n' ' ')
  echo "$lang: $agent"
done
```

## Gap Analysis

For each missing capability:
1. Is there an existing agent that partially covers it?
2. Can it be added to an existing agent?
3. Does it need a new standalone agent?

## Quality Check

For any agent, run a quick quality audit:

```bash
node -e "
  const fs = require('fs');
  const agents = fs.readdirSync('agents').filter(f => f.endsWith('.md') && !['README.md','ROUTING.md'].includes(f));
  const issues = [];
  agents.forEach(f => {
    const content = fs.readFileSync('agents/' + f, 'utf8');
    if (!content.includes('## Mission')) issues.push(f + ': missing Mission section');
    if (!content.includes('## Protocol')) issues.push(f + ': missing Protocol section');
    if (!content.includes('## Done When')) issues.push(f + ': missing Done When section');
  });
  issues.length ? issues.forEach(i => console.log(i)) : console.log('All agents have required sections');
"
```
