# Decisions

## D1: Safe-Power Is The Default

The toolkit should preserve useful capability, including reviewed external tools and trusted agents, while removing silent trust expansion.

## D2: High-Risk Approval Is Narrow And Explicit

The user only needs to approve truly high-risk actions: deletion, destructive overwrite, personal or confidential data leaving the machine, elevated privileges, and major permanent global configuration changes.

## D3: External Use Requires Payload Review, Not Blanket Blocking

Trusted external prompts, agents, MCP, and browser tools are allowed when the exact outbound payload is reviewed first and does not include personal or confidential data.

## D4: OpenCode Starts Minimal But May Grow Behind Policy

`opencode/opencode.safe.jsonc` stays compact for now, but MCP, plugins, shell, and helper roles can be added later when each module is documented and classified against the approval policy.

## D5: Hooks Warn First

The safe hooks print reminders and warnings. They echo input unchanged and do not enforce policy. This avoids surprising workflow breaks while still surfacing risk.

## D6: Installer Copies, It Does Not Configure

`install-local.sh` creates a local target directory and copies files. It does not install packages, modify shell profiles, edit global harness settings, or write to home unless the user explicitly passes such a path.

## D7: Prompt-Injection Resistance Is Part Of The Operating Model

The agent must reject instructions that try to override safety rules, conceal payloads, or smuggle destructive or exfiltration behavior behind unrelated tasks.

## D8: Source References Remain Separate

The `source-*` files are retained as references. They are not installed by the safe-plus installer.

## D9: Bounded Autonomy Is The Next Runtime Goal

The next cycle should push the project toward autonomous operation only inside bounded trust zones. Low-risk repetitive work should become automatic after one-time setup or repeated local approval, while high-risk actions remain explicitly human-gated.

## D10: Runtime Learning Must Stay Local-First

Decision journals, learned allows, and policy suggestions should be stored and derived locally by default. The system should improve from observed behavior without requiring hidden external telemetry.

## D11: Learned Allows Are Bounded To Low/Medium Risk

A learned allow may relax repeated low-risk or medium-risk actions in a known local context, but it must never override critical or high-risk decisions. High-risk outcomes still escalate, and critical outcomes still block.

## D12: Session Risk Can Tighten Decisions

Repeated risky actions inside a short local session should raise caution for the next decision. Session awareness is allowed to tighten routing or escalation behavior, but should stay lightweight and explainable.

## D13: Repeated Approval Should Produce A Visible Suggestion

When the same low/medium-risk pattern is approved repeatedly, the runtime should surface a visible local suggestion that can be accepted or dismissed. Promotion to a learned allow should be inspectable, not silent.

## D14: Runtime Decisions Should Be Explainable

Decision output should include a compact explanation with action, risk, source, and relevant reason codes. Local operators should be able to inspect why a command routed, escalated, blocked, or matched a learned allow.

## D15: Runtime Policy Should Be Project-Aware

Local learned policy is useful, but final runtime behavior should also honor per-project configuration. Trust posture, protected branch names, and sensitive path patterns belong in `ecc.config.json` so different repositories can operate under different safety assumptions without forking the runtime.

## D16: Context Discovery Should Be Automatic Where Safe

The runtime should auto-discover project root and current git branch from local context whenever possible. Operators may still override fields explicitly, but the default path should reduce manual wiring.

## D17: Runtime Actions May Include Bounded Workflow Requirements

The decision layer is allowed to emit workflow-shaped actions such as `require-review`, `require-tests`, or `modify` when that is more helpful than a generic route/escalate result. These are bounded orchestration signals, not silent execution rights.

## D18: Workflow Actions Should Carry Usable Next Steps

A workflow-shaped action is more useful when it includes a compact action plan. If the runtime asks for tests, review, or safer modification, it should also surface suggested commands, review type, or narrowing hints instead of emitting a bare label only.

## D19: Action Plans May Adapt To Safe Repetition

When the same bounded workflow keeps repeating safely, the runtime may strengthen its action-plan guidance using local approval and suggestion history. This can recommend promoting a repeated verification or narrowed workflow into a reviewed local default, without silently expanding trust.

## D20: Promotion Guidance Should Be Explicit And Lifecycle-Aware

Every runtime decision should carry structured promotion guidance that tells the operator exactly where a pattern stands in the learned-allow lifecycle: new, approaching, eligible, promoted, dismissed, or ineligible. The guidance should include remaining approval counts, concrete CLI commands for the next step, and a clear reason when promotion is not possible. This surfaces in hook output, CLI explain, and runtime state so operators always know how to act on repeated safe patterns.

## D21: Lifecycle History Should Stay Auditable And Compact

Promotion lifecycle data is useful only if operators can inspect it quickly. The runtime should therefore preserve raw timestamps for creation, eligibility, acceptance, dismissal, and latest approval, while also emitting a compact lifecycle summary on each explained decision. This keeps audits readable without throwing away the underlying evidence.

## D22: ARG Is An Operating Layer, Not Just A Guard

ECC — the upfront-contract model — is the foundation, not the whole destination. The project's longer-term direction is an intelligent, safety-bounded operating layer that decides which agent capabilities should run, when, and how; learns reviewed local defaults from operator-approved patterns; routes intent to the right skill, agent, rule, or check; and improves over time. Security floors remain non-negotiable and engine-baked. The framing shift matters because it shapes which capabilities get built: operational intelligence, context-aware routing, and amplification of what agents can do well are first-class goals alongside enforcement.
