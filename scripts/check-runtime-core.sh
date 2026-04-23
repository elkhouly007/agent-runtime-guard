#!/usr/bin/env bash
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"

pass() { printf '  ok      %s\n' "$1"; }
fail() { printf '  ERROR   %s\n' "$1" >&2; exit 1; }

printf '[check-runtime-core]\n'

[ -f "$root/runtime/decision-engine.js" ] || fail 'runtime decision engine missing'
[ -f "$root/runtime/risk-score.js" ] || fail 'runtime risk score missing'
[ -f "$root/runtime/decision-journal.js" ] || fail 'runtime decision journal missing'
[ -f "$root/runtime/policy-store.js" ] || fail 'runtime policy store missing'
[ -f "$root/runtime/session-context.js" ] || fail 'runtime session context missing'
[ -f "$root/runtime/project-policy.js" ] || fail 'runtime project policy missing'
[ -f "$root/runtime/context-discovery.js" ] || fail 'runtime context discovery missing'
[ -f "$root/runtime/action-planner.js" ] || fail 'runtime action planner missing'
[ -f "$root/runtime/promotion-guidance.js" ] || fail 'runtime promotion guidance missing'
[ -f "$root/runtime/workflow-router.js" ] || fail 'runtime workflow router missing'
pass 'runtime core files present'

tmp_home="$(mktemp -d)"
cleanup() { rm -rf "$tmp_home"; }
trap cleanup EXIT

HOME="$tmp_home" ECC_STATE_DIR="$tmp_home" node - <<'NODE' "$root" || exit 1
const path = require('path');
const root = process.argv[2];
const fs = require('fs');
const { execFileSync } = require('child_process');
const { score } = require(path.join(root, 'runtime/risk-score.js'));
const { decide } = require(path.join(root, 'runtime/decision-engine.js'));
const { discover } = require(path.join(root, 'runtime/context-discovery.js'));
const { recordApproval, setLearnedAllow, listSuggestions, acceptSuggestion, summarizePolicy, decisionKey, getSuggestion, grantAutoAllowOnce, hasAutoAllowOnce } = require(path.join(root, 'runtime/policy-store.js'));
const { getSessionRisk, saveState } = require(path.join(root, 'runtime/session-context.js'));

const low = score({ command: 'npm test', targetPath: 'src/app.ts' });
if (low.level !== 'low') throw new Error(`expected low, got ${low.level}`);

const forcedPush = ['git', 'push', '--force', 'origin', 'main'].join(' ');
const high = score({ command: forcedPush, targetPath: 'prod/config.yml', protectedBranch: true });
if (!(high.score >= 8)) throw new Error(`expected high score >=8, got ${high.score}`);

const destructive = ['rm', '-rf', '/'].join(' ');
const blocked = decide({ command: destructive, targetPath: '/', tool: 'Bash', branch: 'main', notes: 'runtime-core-check' });
if (blocked.action !== 'block') throw new Error(`expected block, got ${blocked.action}`);
if (blocked.riskLevel !== 'critical') throw new Error(`expected critical, got ${blocked.riskLevel}`);

const mediumInput = { command: ['sudo', 'systemctl', 'restart', 'app'].join(' '), targetPath: 'ops/service', tool: 'Bash', sessionRisk: 0 };
const routed = decide(mediumInput);
if (routed.action !== 'route') throw new Error(`expected route, got ${routed.action}`);

recordApproval(mediumInput);
recordApproval(mediumInput);
recordApproval(mediumInput);
const suggestions = listSuggestions();
if (suggestions.length < 1) throw new Error('expected at least one pending suggestion');
if (!acceptSuggestion(suggestions[0].key)) throw new Error('expected suggestion acceptance to succeed');
setLearnedAllow(mediumInput, true);
const learned = decide(mediumInput);
if (learned.action !== 'allow') throw new Error(`expected allow from learned policy, got ${learned.action}`);
if (learned.decisionSource !== 'learned-allow') throw new Error(`expected learned-allow source, got ${learned.decisionSource}`);
const summary = summarizePolicy();
if (summary.learnedAllowCount < 1) throw new Error('expected learned allow count >= 1');

const destructive2 = decide({ command: ['rm', '-rf', '/tmp/cache'].join(' '), targetPath: '/tmp/cache', tool: 'Bash' });
const destructive3 = decide({ command: ['rm', '-rf', '/tmp/build'].join(' '), targetPath: '/tmp/build', tool: 'Bash' });
if (!['require-tests', 'escalate', 'block', 'allow'].includes(destructive2.action)) throw new Error(`unexpected action ${destructive2.action}`);
if (!['require-tests', 'escalate', 'block', 'allow'].includes(destructive3.action)) throw new Error(`unexpected action ${destructive3.action}`);
if (getSessionRisk() < 1) throw new Error('expected session risk to increase after repeated risky actions');

const repo = path.resolve(process.env.HOME, 'sample-repo');
fs.mkdirSync(repo, { recursive: true });
execFileSync('git', ['init'], { cwd: repo, stdio: 'ignore' });
execFileSync('git', ['checkout', '-b', 'release'], { cwd: repo, stdio: 'ignore' });
fs.writeFileSync(path.join(repo, 'ecc.config.json'), JSON.stringify({ runtime: { protected_branches: ['release'], trust_posture: 'balanced' } }, null, 2));
const discovered = discover({ targetPath: path.join(repo, 'src') });
if (path.normalize(discovered.projectRoot) !== path.normalize(repo)) throw new Error(`expected projectRoot ${repo}, got ${discovered.projectRoot}`);
if (discovered.branch !== 'release') throw new Error(`expected discovered branch release, got ${discovered.branch}`);
const protectedDecision = decide({ command: ['sudo', 'systemctl', 'restart', 'api'].join(' '), targetPath: path.join(repo, 'src'), tool: 'Bash', projectRoot: repo, sessionRisk: 0 });
if (protectedDecision.action !== 'require-review') throw new Error(`expected require-review, got ${protectedDecision.action}`);
if (protectedDecision.enforcementAction !== 'block') throw new Error(`expected enforcement block, got ${protectedDecision.enforcementAction}`);
if (protectedDecision.actionPlan.reviewType !== 'protected-branch-review') throw new Error(`expected protected-branch-review, got ${protectedDecision.actionPlan.reviewType}`);
if (!protectedDecision.explanation.includes('trust=balanced')) throw new Error('expected balanced trust explanation');

const testsDecision = decide({ command: ['rm', '-rf', '/tmp/cache'].join(' '), targetPath: '/tmp/cache', tool: 'Bash', sessionRisk: 0, repeatedApprovals: 0 });
if (testsDecision.action !== 'require-tests') throw new Error(`expected require-tests, got ${testsDecision.action}`);
if (!Array.isArray(testsDecision.actionPlan.commands) || testsDecision.actionPlan.commands.length < 1) throw new Error('expected test commands in action plan');

const testsShapeRepo = path.resolve(process.env.HOME, 'tests-shape-repo');
fs.mkdirSync(testsShapeRepo, { recursive: true });
execFileSync('git', ['init'], { cwd: testsShapeRepo, stdio: 'ignore' });
execFileSync('git', ['checkout', '-b', 'feature/tests'], { cwd: testsShapeRepo, stdio: 'ignore' });
fs.writeFileSync(path.join(testsShapeRepo, 'package.json'), '{"name":"tests-shape-repo"}\n');
const stackAwareTestsDecision = decide({ command: ['rm', '-rf', '/tmp/cache'].join(' '), targetPath: path.join(testsShapeRepo, 'build'), tool: 'Bash', sessionRisk: 0, repeatedApprovals: 0, projectRoot: testsShapeRepo });
if (stackAwareTestsDecision.action !== 'require-tests') throw new Error(`expected stack-aware require-tests, got ${stackAwareTestsDecision.action}`);
if (stackAwareTestsDecision.actionPlan.commands.join(' | ') !== 'npm test | npm run lint') throw new Error(`expected stack-aware test commands, got ${stackAwareTestsDecision.actionPlan.commands.join(' | ')}`);

recordApproval({ command: ['rm', '-rf', '/tmp/cache'].join(' '), targetPath: '/tmp/cache', tool: 'Bash' });
recordApproval({ command: ['rm', '-rf', '/tmp/cache'].join(' '), targetPath: '/tmp/cache', tool: 'Bash' });
recordApproval({ command: ['rm', '-rf', '/tmp/cache'].join(' '), targetPath: '/tmp/cache', tool: 'Bash' });
const adaptiveTestsDecision = decide({ command: ['rm', '-rf', '/tmp/cache'].join(' '), targetPath: '/tmp/cache', tool: 'Bash', sessionRisk: 0 });
if (!adaptiveTestsDecision.actionPlan.summary.includes('consider')) throw new Error('expected adaptive require-tests summary');
if (adaptiveTestsDecision.workflowRoute?.lane !== 'verification') throw new Error(`expected verification lane, got ${adaptiveTestsDecision.workflowRoute?.lane}`);
if (adaptiveTestsDecision.workflowRoute?.suggestedTarget !== 'ecc-cli.check') throw new Error(`expected verification target ecc-cli.check, got ${adaptiveTestsDecision.workflowRoute?.suggestedTarget}`);

const lowRoute = decide({ command: 'npm test', targetPath: 'web/app.ts', tool: 'Bash', sessionRisk: 0 });
if (lowRoute.workflowRoute?.lane !== 'checks') throw new Error(`expected checks lane, got ${lowRoute.workflowRoute?.lane}`);
if (lowRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.check') throw new Error(`expected checks target ecc-cli.check, got ${lowRoute.workflowRoute?.suggestedTarget}`);

const sourceRoute = decide({ command: 'update module', targetPath: 'src/runtime/app.ts', tool: 'Bash', sessionRisk: 0 });
if (sourceRoute.workflowRoute?.lane !== 'checks') throw new Error(`expected source route checks lane, got ${sourceRoute.workflowRoute?.lane}`);
if (sourceRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.check') throw new Error(`expected source route target ecc-cli.check, got ${sourceRoute.workflowRoute?.suggestedTarget}`);

const sourceShapeRepo = path.resolve(process.env.HOME, 'source-shape-repo');
fs.mkdirSync(path.join(sourceShapeRepo, 'src'), { recursive: true });
execFileSync('git', ['init'], { cwd: sourceShapeRepo, stdio: 'ignore' });
execFileSync('git', ['checkout', '-b', 'feature/runtime'], { cwd: sourceShapeRepo, stdio: 'ignore' });
fs.writeFileSync(path.join(sourceShapeRepo, 'package.json'), '{"name":"source-shape-repo"}\n');
const sourceShapeRoute = decide({ command: 'update module', targetPath: path.join(sourceShapeRepo, 'src/app.ts'), tool: 'Bash', sessionRisk: 0, projectRoot: sourceShapeRepo });
if (sourceShapeRoute.workflowRoute?.lane !== 'checks') throw new Error(`expected source-shape route checks lane, got ${sourceShapeRoute.workflowRoute?.lane}`);
if (!String(sourceShapeRoute.workflowRoute?.reason || '').includes('node project')) throw new Error('expected stack-aware source route reason');
if (sourceShapeRoute.workflowRoute?.suggestedCommand !== 'ecc-cli.sh check && npm test') throw new Error(`expected stack-aware source route command, got ${sourceShapeRoute.workflowRoute?.suggestedCommand}`);

const sourceEditRoute = decide({ command: 'edit module', targetPath: 'src/runtime/app.ts', tool: 'Edit', sessionRisk: 0 });
if (sourceEditRoute.workflowRoute?.lane !== 'checks') throw new Error(`expected source edit checks lane, got ${sourceEditRoute.workflowRoute?.lane}`);
if (!String(sourceEditRoute.workflowRoute?.reason || '').includes('direct edits')) throw new Error('expected tool-aware source edit reason');

const strictSourceRoute = decide({ command: 'update module', targetPath: 'src/runtime/app.ts', tool: 'Bash', sessionRisk: 0, trustPosture: 'strict' });
if (strictSourceRoute.workflowRoute?.lane !== 'review') throw new Error(`expected strict source route review lane, got ${strictSourceRoute.workflowRoute?.lane}`);
if (strictSourceRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.review') throw new Error(`expected strict source route target ecc-cli.review, got ${strictSourceRoute.workflowRoute?.suggestedTarget}`);

const protectedSourceRoute = decide({ command: 'update module', targetPath: 'src/runtime/app.ts', tool: 'Bash', sessionRisk: 0, branch: 'release', protectedBranches: ['release'] });
if (protectedSourceRoute.workflowRoute?.lane !== 'review') throw new Error(`expected protected source route review lane, got ${protectedSourceRoute.workflowRoute?.lane}`);
if (!String(protectedSourceRoute.workflowRoute?.reason || '').includes('protected branch release')) throw new Error('expected protected branch source reason');

const strictSourceEditRoute = decide({ command: 'edit module', targetPath: 'src/runtime/app.ts', tool: 'Edit', sessionRisk: 0, trustPosture: 'strict' });
if (strictSourceEditRoute.workflowRoute?.lane !== 'review') throw new Error(`expected strict source edit review lane, got ${strictSourceEditRoute.workflowRoute?.lane}`);
if (!String(strictSourceEditRoute.workflowRoute?.reason || '').includes('direct code edits')) throw new Error('expected tool-aware strict source edit reason');

const protectedSourceEditRoute = decide({ command: 'edit module', targetPath: 'src/runtime/app.ts', tool: 'Edit', sessionRisk: 0, branch: 'release', protectedBranches: ['release'] });
if (protectedSourceEditRoute.workflowRoute?.lane !== 'review') throw new Error(`expected protected source edit review lane, got ${protectedSourceEditRoute.workflowRoute?.lane}`);
if (!String(protectedSourceEditRoute.workflowRoute?.reason || '').includes('direct edits should route through review first')) throw new Error('expected protected branch source edit reason');

const docsRoute = decide({ command: 'update docs', targetPath: 'docs/runtime-notes.md', tool: 'Bash', sessionRisk: 0 });
if (docsRoute.workflowRoute?.lane !== 'direct') throw new Error(`expected docs route direct lane, got ${docsRoute.workflowRoute?.lane}`);

const setupRoute = decide({ command: 'setup profile full', targetPath: 'ecc.config.json', tool: 'Bash', sessionRisk: 0 });
if (setupRoute.workflowRoute?.lane !== 'setup') throw new Error(`expected setup lane, got ${setupRoute.workflowRoute?.lane}`);
if (setupRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.setup') throw new Error(`expected setup target ecc-cli.setup, got ${setupRoute.workflowRoute?.suggestedTarget}`);

const shapeRepo = path.resolve(process.env.HOME, 'shape-repo');
fs.mkdirSync(shapeRepo, { recursive: true });
execFileSync('git', ['init'], { cwd: shapeRepo, stdio: 'ignore' });
execFileSync('git', ['checkout', '-b', 'feature/setup'], { cwd: shapeRepo, stdio: 'ignore' });
fs.writeFileSync(path.join(shapeRepo, 'package.json'), '{"name":"shape-repo"}\n');
const setupShapeRoute = decide({ command: 'setup project', targetPath: shapeRepo, tool: 'Bash', sessionRisk: 0, projectRoot: shapeRepo });
if (setupShapeRoute.workflowRoute?.lane !== 'setup') throw new Error(`expected setup shape lane, got ${setupShapeRoute.workflowRoute?.lane}`);
if (setupShapeRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.generate-config') throw new Error(`expected setup shape target ecc-cli.generate-config, got ${setupShapeRoute.workflowRoute?.suggestedTarget}`);
if (!String(setupShapeRoute.workflowRoute?.reason || '').includes('looks like node')) throw new Error('expected project-shape setup reason');
if (!String(setupShapeRoute.workflowRoute?.suggestedCommand || '').includes('generate-config.sh')) throw new Error('expected generate-config setup command');
if (!String(setupShapeRoute.explanation || '').includes('stack=node')) throw new Error('expected project-shape stack in explanation');
if (!String(setupShapeRoute.explanation || '').includes('config=missing')) throw new Error('expected missing-config explanation flag');

const wiringEditRoute = decide({ command: '', targetPath: '.claude/settings.json', tool: 'Edit', sessionRisk: 0, branch: 'feature/hooks' });
if (wiringEditRoute.workflowRoute?.lane !== 'wiring') throw new Error(`expected wiring edit lane, got ${wiringEditRoute.workflowRoute?.lane}`);
if (wiringEditRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.wire') throw new Error(`expected wiring edit target ecc-cli.wire, got ${wiringEditRoute.workflowRoute?.suggestedTarget}`);
if (!String(wiringEditRoute.workflowRoute?.reason || '').includes('direct hook or settings editing')) throw new Error('expected tool-aware wiring reason');

const strictWiringEditRoute = decide({ command: 'edit settings', targetPath: '.claude/settings.json', tool: 'Edit', sessionRisk: 0, trustPosture: 'strict' });
if (strictWiringEditRoute.workflowRoute?.lane !== 'review') throw new Error(`expected strict wiring edit review lane, got ${strictWiringEditRoute.workflowRoute?.lane}`);
if (strictWiringEditRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.review') throw new Error(`expected strict wiring edit target ecc-cli.review, got ${strictWiringEditRoute.workflowRoute?.suggestedTarget}`);

const protectedWiringEditRoute = decide({ command: 'edit settings', targetPath: '.claude/settings.json', tool: 'Edit', sessionRisk: 0, branch: 'release', protectedBranches: ['release'] });
if (protectedWiringEditRoute.workflowRoute?.lane !== 'review') throw new Error(`expected protected wiring edit review lane, got ${protectedWiringEditRoute.workflowRoute?.lane}`);
if (!String(protectedWiringEditRoute.workflowRoute?.reason || '').includes('protected branch release')) throw new Error('expected protected wiring review reason');

const payloadRoute = decide({ command: 'redact payload.json', targetPath: 'payload.json', tool: 'Bash', sessionRisk: 0 });
if (payloadRoute.workflowRoute?.lane !== 'payload') throw new Error(`expected payload lane, got ${payloadRoute.workflowRoute?.lane}`);
if (payloadRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.redact') throw new Error(`expected payload target ecc-cli.redact, got ${payloadRoute.workflowRoute?.suggestedTarget}`);

const classBRoute = decide({ command: 'open customer export', targetPath: 'exports/customer.csv', tool: 'Bash', sessionRisk: 0, payloadClass: 'B' });
if (classBRoute.workflowRoute?.lane !== 'payload') throw new Error(`expected class B payload lane, got ${classBRoute.workflowRoute?.lane}`);
if (classBRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.review') throw new Error(`expected class B payload target ecc-cli.review, got ${classBRoute.workflowRoute?.suggestedTarget}`);

const classCRoute = decide({ command: 'inspect incident bundle', targetPath: 'bundle.zip', tool: 'Bash', sessionRisk: 0, payloadClass: 'C', branch: 'feature/incidents' });
if (classCRoute.workflowRoute?.lane !== 'review') throw new Error(`expected class C review lane, got ${classCRoute.workflowRoute?.lane}`);
if (classCRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.review') throw new Error(`expected class C review target ecc-cli.review, got ${classCRoute.workflowRoute?.suggestedTarget}`);

const classifyRoute = decide({ command: 'classify inbound.txt', targetPath: 'payload.txt', tool: 'Bash', sessionRisk: 0 });
if (classifyRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.classify') throw new Error(`expected classify target ecc-cli.classify, got ${classifyRoute.workflowRoute?.suggestedTarget}`);

const payloadReviewRoute = decide({ command: 'review payload.json', targetPath: 'payload.json', tool: 'Bash', sessionRisk: 0 });
if (payloadReviewRoute.workflowRoute?.lane !== 'payload') throw new Error(`expected payload review lane, got ${payloadReviewRoute.workflowRoute?.lane}`);
if (payloadReviewRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.review') throw new Error(`expected payload review target ecc-cli.review, got ${payloadReviewRoute.workflowRoute?.suggestedTarget}`);
if (payloadReviewRoute.workflowRoute?.suggestedCommand !== 'ecc-cli.sh review <file>') throw new Error(`expected payload review command, got ${payloadReviewRoute.workflowRoute?.suggestedCommand}`);

const reviewRoute = decide({ command: 'security review auth diff', targetPath: 'changes.patch', tool: 'Bash', sessionRisk: 0 });
if (reviewRoute.workflowRoute?.lane !== 'review') throw new Error(`expected review lane, got ${reviewRoute.workflowRoute?.lane}`);
if (reviewRoute.workflowRoute?.suggestedTarget !== 'ecc-cli.review') throw new Error(`expected review target ecc-cli.review, got ${reviewRoute.workflowRoute?.suggestedTarget}`);
if (reviewRoute.workflowRoute?.suggestedCommand !== 'ecc-cli.sh review') throw new Error(`expected review command, got ${reviewRoute.workflowRoute?.suggestedCommand}`);

const modifyDecision = decide({ command: ['cat', 'prod/config'].join(' '), targetPath: path.join(repo, 'prod/service'), tool: 'Bash', branch: 'feature/payments', sessionRisk: 0 });
if (modifyDecision.action !== 'modify') throw new Error(`expected modify, got ${modifyDecision.action}`);
if (!Array.isArray(modifyDecision.actionPlan.modificationHints) || modifyDecision.actionPlan.modificationHints.length < 1) throw new Error('expected modification hints');

// --- promotion guidance checks ---
const { evaluate } = require(path.join(root, 'runtime/promotion-guidance.js'));

// critical risk is ineligible
const critPromo = evaluate({ key: 'x', approvalCount: 5, learnedAllow: false }, { level: 'critical', reasons: [] });
if (critPromo.stage !== 'ineligible') throw new Error(`expected ineligible, got ${critPromo.stage}`);

// new pattern with zero approvals
const newPromo = evaluate({ key: 'y', approvalCount: 0, learnedAllow: false }, { level: 'medium', reasons: [] });
if (newPromo.stage !== 'new') throw new Error(`expected new, got ${newPromo.stage}`);
if (newPromo.remaining !== 3) throw new Error(`expected remaining=3, got ${newPromo.remaining}`);

// approaching with 2 approvals
const approachPromo = evaluate({ key: 'z', approvalCount: 2, learnedAllow: false }, { level: 'medium', reasons: [] });
if (approachPromo.stage !== 'approaching') throw new Error(`expected approaching, got ${approachPromo.stage}`);
if (approachPromo.remaining !== 1) throw new Error(`expected remaining=1, got ${approachPromo.remaining}`);

// eligible with pending suggestion
const eligiblePromo = evaluate({ key: 'w', approvalCount: 3, learnedAllow: false, pendingSuggestion: { status: 'pending' } }, { level: 'medium', reasons: [] });
if (eligiblePromo.stage !== 'eligible') throw new Error(`expected eligible, got ${eligiblePromo.stage}`);
if (!eligiblePromo.cliHint || !eligiblePromo.cliHint.includes('promote')) throw new Error('expected promote CLI hint');

// promoted learned allow
const promotedPromo = evaluate({ key: 'v', approvalCount: 5, learnedAllow: true }, { level: 'medium', reasons: [] });
if (promotedPromo.stage !== 'promoted') throw new Error(`expected promoted, got ${promotedPromo.stage}`);

// decision engine includes promotionGuidance
const blockedPromo = decide({ command: destructive, targetPath: '/', tool: 'Bash', branch: 'main', notes: 'promo-check', sessionRisk: 0 });
if (!blockedPromo.promotionGuidance) throw new Error('expected promotionGuidance in decision');
if (blockedPromo.promotionGuidance.stage !== 'ineligible') throw new Error(`expected ineligible in critical decision, got ${blockedPromo.promotionGuidance.stage}`);

// adaptive action plan includes promotionHint
if (adaptiveTestsDecision.actionPlan.promotionHint == null) throw new Error('expected promotionHint in adaptive action plan');

// --- W2: escalate lane, payloadClass routing, sessionRisk routing ---

// force-push without protectedBranch → high risk, non-protected-branch, non-destructive → escalate
const escalateDecision = decide({ command: 'git push --force origin main', targetPath: 'src/app.ts', tool: 'Bash', sessionRisk: 0 });
if (escalateDecision.action !== 'escalate') throw new Error(`expected escalate, got ${escalateDecision.action}`);
if (escalateDecision.workflowRoute?.lane !== 'escalation') throw new Error(`expected escalation lane, got ${escalateDecision.workflowRoute?.lane}`);
if (escalateDecision.workflowRoute?.suggestedSurface !== 'security-reviewer') throw new Error(`expected security-reviewer surface, got ${escalateDecision.workflowRoute?.suggestedSurface}`);
if (escalateDecision.workflowRoute?.suggestedTarget !== 'human-gate') throw new Error(`expected human-gate target, got ${escalateDecision.workflowRoute?.suggestedTarget}`);
if (escalateDecision.enforcementAction !== 'block') throw new Error(`expected block enforcement for escalate, got ${escalateDecision.enforcementAction}`);

// classifyCommandPayload: C-class payload flag should trigger review lane even for low-risk commands
const classifyCDecision = decide({ command: 'cat incident-report.pdf', targetPath: 'reports/', tool: 'Bash', sessionRisk: 0, payloadClass: 'C', branch: 'feature/hooks' });
if (classifyCDecision.workflowRoute?.lane !== 'review') throw new Error(`expected class C → review lane, got ${classifyCDecision.workflowRoute?.lane}`);

// sessionRisk bump: elevated sessionRisk should add score and affect route for borderline commands
const sessionRiskDecision = decide({ command: 'sudo systemctl restart app', targetPath: 'ops/service', tool: 'Bash', sessionRisk: 3 });
if (!['route', 'escalate', 'require-review'].includes(sessionRiskDecision.action)) throw new Error(`expected non-allow action with session risk, got ${sessionRiskDecision.action}`);
if (!sessionRiskDecision.explanation.includes('session-risk')) throw new Error('expected session-risk in explanation');

// hook-utils classifyCommandPayload function (in-process)
const { classifyCommandPayload } = require(path.join(root, 'claude/hooks/hook-utils.js'));
if (classifyCommandPayload('echo api_key=abc123') !== 'C') throw new Error('expected C for api_key= command');
if (classifyCommandPayload('cat internal-only/report.md') !== 'B') throw new Error('expected B for internal-only command');
if (classifyCommandPayload('npm test') !== 'A') throw new Error('expected A for safe command');

// B.1 auto-allow-once: grant for eligible (pending) policy, consume on decide, expire after single use
const autoInput = { command: 'npx -y tsx scripts/migrate.ts', tool: 'Bash', targetPath: 'scripts/', payloadClass: 'A', branch: 'feature/docs', sessionRisk: 0 };
for (let i = 0; i < 3; i++) recordApproval(autoInput);
const autoKey = decisionKey(autoInput);
const autoSuggestion = getSuggestion(autoKey);
if (!autoSuggestion || autoSuggestion.status !== 'pending') throw new Error('expected pending suggestion for auto-allow-once test');
if (!grantAutoAllowOnce(autoKey)) throw new Error('grantAutoAllowOnce should succeed for eligible pending policy');
if (!hasAutoAllowOnce(autoKey)) throw new Error('hasAutoAllowOnce should return true after grant');
if (grantAutoAllowOnce('bash|generic|default-target|A')) throw new Error('grantAutoAllowOnce should fail for non-eligible key');
const autoDecision = decide({ ...autoInput });
if (autoDecision.action !== 'allow') throw new Error(`expected allow from auto-allow-once, got ${autoDecision.action}`);
if (autoDecision.decisionSource !== 'auto-allow-once') throw new Error(`expected auto-allow-once source, got ${autoDecision.decisionSource}`);
if (!autoDecision.explanation.includes('auto-allow-once=consumed')) throw new Error('expected auto-allow-once=consumed in explanation');
if (hasAutoAllowOnce(autoKey)) throw new Error('auto-allow-once token should be consumed after single use');
console.log('auto-allow-once-lifecycle: ok');

// B.2 trajectory nudge: 3 recent escalations should nudge allow → route
const now = Date.now();
saveState({
  recent: [
    { ts: new Date(now - 5*60*1000).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
    { ts: new Date(now - 4*60*1000).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
    { ts: new Date(now - 3*60*1000).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
  ],
  updatedAt: new Date().toISOString(),
});
const trajDecision = decide({ command: 'ls -la', tool: 'Bash', targetPath: '.', branch: 'feature/test', sessionRisk: 0, repeatedApprovals: 0 });
if (trajDecision.action !== 'route') throw new Error(`expected route from trajectory nudge, got ${trajDecision.action}`);
if (trajDecision.decisionSource !== 'trajectory-nudge') throw new Error(`expected trajectory-nudge source, got ${trajDecision.decisionSource}`);
if (!trajDecision.explanation.includes('trajectory-nudge')) throw new Error('expected trajectory-nudge in explanation');
if (!trajDecision.trajectoryNudge) throw new Error('expected trajectoryNudge field in result');
console.log('trajectory-nudge: ok');

// Trajectory-nudge NEGATIVE tests: learned-allow and auto-allow-once are exempt
// Case A: learned-allow must NOT be nudged despite 3+ escalations
const negTs = Date.now();
saveState({
  recent: [
    { ts: new Date(negTs - 1000 * 60).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
    { ts: new Date(negTs - 1000 * 90).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
    { ts: new Date(negTs - 1000 * 120).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
  ],
  updatedAt: new Date().toISOString(),
});
// setLearnedAllow takes an input object (decisionKey is computed internally)
setLearnedAllow({ command: 'npm test', tool: 'Bash', targetPath: '.', branch: 'main' });
const learnedDecision = decide({ command: 'npm test', tool: 'Bash', targetPath: '.', branch: 'main', sessionRisk: 0, repeatedApprovals: 0 });
if (learnedDecision.decisionSource !== 'learned-allow') throw new Error(`expected learned-allow source, got ${learnedDecision.decisionSource}`);
if (learnedDecision.trajectoryNudge) throw new Error('trajectory nudge must NOT fire when source is learned-allow');
console.log('trajectory-nudge exempt for learned-allow: ok');

// Case B: auto-allow-once must NOT be nudged either
// Re-use the eligible suggestion left by the B.1 lifecycle test above (npx -y)
// That test consumed the token but left the suggestion as pending; re-grant it.
const aaoInput = { command: 'npx -y tsx scripts/migrate.ts', tool: 'Bash', targetPath: 'scripts/', payloadClass: 'A', branch: 'feature/docs', sessionRisk: 0 };
const aaoKey = decisionKey(aaoInput);
const aaoSugg = getSuggestion(aaoKey);
if (!aaoSugg || aaoSugg.status !== 'pending') throw new Error('expected pending suggestion for auto-allow-once negative test (re-grant)');
// Seed 3 escalations using the correct session-context format
const nowMs = Date.now();
saveState({
  recent: [
    { ts: new Date(nowMs - 1000 * 60).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
    { ts: new Date(nowMs - 1000 * 90).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
    { ts: new Date(nowMs - 1000 * 120).toISOString(), action: 'escalate', riskLevel: 'high', reasonCodes: [] },
  ],
  updatedAt: new Date().toISOString(),
});
grantAutoAllowOnce(aaoKey);
if (!hasAutoAllowOnce(aaoKey)) throw new Error('auto-allow-once token should exist before consume');
const aaoDecision = decide({ ...aaoInput });
if (aaoDecision.decisionSource !== 'auto-allow-once') throw new Error(`expected auto-allow-once source, got ${aaoDecision.decisionSource}`);
if (aaoDecision.trajectoryNudge) throw new Error('trajectory nudge must NOT fire when source is auto-allow-once');
console.log('trajectory-nudge exempt for auto-allow-once: ok');

// C.3 kill switch: ECC_KILL_SWITCH=1 should block all decisions regardless of risk
const origKS = process.env.ECC_KILL_SWITCH;
process.env.ECC_KILL_SWITCH = '1';
const ksDecision = decide({ command: 'npm test', tool: 'Bash', targetPath: '.', branch: 'feature/test', sessionRisk: 0 });
if (ksDecision.action !== 'block') throw new Error(`expected block from kill switch, got ${ksDecision.action}`);
if (ksDecision.decisionSource !== 'kill-switch') throw new Error(`expected kill-switch source, got ${ksDecision.decisionSource}`);
if (!ksDecision.explanation.includes('kill-switch engaged')) throw new Error('expected kill-switch engaged in explanation');
if (origKS !== undefined) process.env.ECC_KILL_SWITCH = origKS;
else delete process.env.ECC_KILL_SWITCH;
console.log('kill-switch: ok');

console.log('runtime-core-node-check: ok');
NODE
pass 'runtime scoring, learned policy, suggestions, and session behavior'

# classifyPathSensitivity unit tests
HOME="$tmp_home" ECC_STATE_DIR="$tmp_home" node - <<'NODE2' "$root" || exit 1
const path = require('path');
const root = process.argv[2];
const { classifyPathSensitivity } = require(path.join(root, 'claude/hooks/hook-utils.js'));

const highCases = [
  ['~/.ssh/id_rsa',                   'high'],
  ['~/.aws/credentials',              'high'],
  ['/home/user/.gnupg/secring.gpg',   'high'],
  ['~/.config/gcloud/credentials.db', 'high'],
  ['/home/user/.docker/config/config.json', 'high'],
];
const medCases = [
  ['./.env',         'medium'],
  ['./.env.local',   'medium'],
  ['project/.env.prod',    'medium'],
  ['config/.env.staging', 'medium'],
];
const lowCases = [
  ['./README.md',    'low'],
  ['./src/index.ts', 'low'],
  ['/tmp/build.log', 'low'],
];
for (const [p, expected] of [...highCases, ...medCases, ...lowCases]) {
  const actual = classifyPathSensitivity(p);
  if (actual !== expected) throw new Error(`classifyPathSensitivity('${p}'): expected '${expected}', got '${actual}'`);
}
console.log('classifyPathSensitivity: ok');
NODE2
pass 'classifyPathSensitivity low/medium/high classification'

printf '\nRuntime core checks passed.\n'
