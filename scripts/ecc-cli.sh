#!/usr/bin/env bash
# ecc-cli.sh — Unified command-line interface for Agent Runtime Guard.
#
# Consolidates 14 individual scripts into one entry point.
#
# Usage:
#   ./scripts/ecc-cli.sh <subcommand> [args...]
#   ecc <subcommand> [args...]          (if symlinked to PATH)
#
# Subcommands:
#   install     Install Agent Runtime Guard into a target project directory (one command).
#   upgrade     Upgrade an existing installation in-place, preserving ecc.config.json.
#   setup       Run the interactive onboarding wizard.
#   audit       Audit scripts and hook files for unsafe patterns.
#   check       Run registry, integration, skill, installation, config/settings, runtime core, runtime CLI, hook edge cases, apply-status, executable, setup, wiring-doc, superiority-evidence, status-doc, fixture-count, and harness-support checks.
#   fixtures    Run all fixture-based tests.
#   integrity   Verify hook file SHA-256 integrity baseline.
#   status      Show counts of agents, rules, skills, hooks, scripts.
#   review      Review a payload file for security classification.
#   classify    Classify a payload file (A/B/C tier).
#   redact      Redact a payload file (print sanitised version).
#   wire        Generate a settings.json snippet for hook wiring.
#   log         Show or clear the hook event log (ECC_HOOK_LOG=1).
#   version     Print Agent Runtime Guard version.
#   runtime     Show runtime roadmap, state, approvals, promotions, and decision explanations.
#   help        Show this help, or help for a specific subcommand.
#
# Examples:
#   ecc-cli.sh install ./my-project --profile rules --auto
#   ecc-cli.sh setup --non-interactive --target ./my-project --profile full
#   ecc-cli.sh audit
#   ecc-cli.sh check
#   ecc-cli.sh redact payload.json --diff
#   ecc-cli.sh log --tail 20
#   ecc-cli.sh log --clear
#   ecc-cli.sh runtime state
#   ecc-cli.sh runtime accept 'bash|sudo|default-target|A'
#   ecc-cli.sh runtime record-approval --tool Bash --command 'sudo systemctl restart app' --target ops/service
#   ecc-cli.sh runtime promote 'bash|sudo|default-target|A'
#   ecc-cli.sh runtime explain --tool Bash --command 'sudo systemctl restart app' --target ops/service

set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
scripts="${root}/scripts"

# ── colour helpers ────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  BOLD="$(tput bold 2>/dev/null || printf '')"
  CYAN="$(tput setaf 6 2>/dev/null || printf '')"
  GREEN="$(tput setaf 2 2>/dev/null || printf '')"
  YELLOW="$(tput setaf 3 2>/dev/null || printf '')"
  RED="$(tput setaf 1 2>/dev/null || printf '')"
  RESET="$(tput sgr0 2>/dev/null || printf '')"
else
  BOLD="" CYAN="" GREEN="" YELLOW="" RED="" RESET=""
fi

usage() {
  sed -n '3,22p' "$0" | sed 's/^# //' | grep -v '^#'
}

die() { printf '%sError: %s%s\n' "$RED" "$*" "$RESET" >&2; exit 1; }

# ── subcommand dispatch ───────────────────────────────────────────────────────

cmd="${1:-help}"
shift || true

case "$cmd" in

  # ── install ──────────────────────────────────────────────────────────────
  install)
    exec bash "${scripts}/install.sh" "$@"
    ;;

  # ── upgrade ──────────────────────────────────────────────────────────────
  upgrade)
    exec bash "${scripts}/upgrade.sh" "$@"
    ;;

  # ── setup ────────────────────────────────────────────────────────────────
  setup)
    exec bash "${scripts}/setup-wizard.sh" "$@"
    ;;

  # ── audit ─────────────────────────────────────────────────────────────────
  audit)
    section() { printf '\n%s━━━ %s ━━━%s\n' "$CYAN" "$1" "$RESET"; }
    failed=0

    section "Audit local (scripts + hooks)"
    bash "${scripts}/audit-local.sh" || failed=1

    section "Audit examples (prose + GOOD blocks)"
    bash "${scripts}/audit-examples.sh" || failed=1

    section "Hook integrity"
    bash "${scripts}/verify-hooks-integrity.sh" || failed=1

    [ "$failed" -eq 0 ] && printf '\n%sAll audits passed.%s\n' "$GREEN" "$RESET" && exit 0
    printf '\n%sOne or more audits failed.%s\n' "$RED" "$RESET" >&2
    exit 1
    ;;

  # ── check ─────────────────────────────────────────────────────────────────
  check)
    section() { printf '\n%s━━━ %s ━━━%s\n' "$CYAN" "$1" "$RESET"; }
    failed=0

    # Node.js is required by several checks. Fail fast with a helpful message.
    if ! command -v node >/dev/null 2>&1; then
      printf '\n%sError: node not found on PATH.%s\n' "$RED" "$RESET" >&2
      printf 'Several checks (runtime-core, runtime-cli, hook-edge-cases, config-integration, installation) require Node.js.\n' >&2
      printf 'On this machine, Node.js is available at:\n' >&2
      printf '  /c/Users/Khouly/.lmstudio/.internal/utils/node.exe\n' >&2
      printf 'Run:  export PATH="/c/Users/Khouly/.lmstudio/.internal/utils:$PATH"\n' >&2
      printf 'then re-run:  %s check\n' "$0" >&2
      exit 2
    fi

    section "Registries"
    bash "${scripts}/check-registries.sh" || failed=1

    section "Integration smoke"
    bash "${scripts}/check-integration-smoke.sh" || failed=1

    section "Skills"
    bash "${scripts}/check-skills.sh" --errors-only || failed=1

    section "Installation"
    bash "${scripts}/check-installation.sh" || failed=1

    section "Config integration"
    bash "${scripts}/check-config-integration.sh" || failed=1

    section "Runtime core"
    bash "${scripts}/check-runtime-core.sh" || failed=1

    section "Runtime CLI"
    bash "${scripts}/check-runtime-cli.sh" || failed=1

    section "Hook edge cases"
    bash "${scripts}/check-hook-edge-cases.sh" || failed=1

    section "Apply status"
    bash "${scripts}/check-apply-status.sh" || failed=1

    section "Executables"
    bash "${scripts}/check-executables.sh" || failed=1

    section "Setup wizard"
    bash "${scripts}/check-setup-wizard.sh" || failed=1

    section "Wiring docs"
    bash "${scripts}/check-wiring-docs.sh" || failed=1

    section "Superiority evidence"
    bash "${scripts}/check-superiority-evidence.sh" || failed=1

    section "Status docs"
    bash "${scripts}/check-status-docs.sh" || failed=1

    section "Fixture count"
    bash "${scripts}/check-fixture-count.sh" || failed=1

    section "Harness support"
    bash "${scripts}/check-harness-support.sh" || failed=1

    section "OWASP coverage"
    bash "${scripts}/check-owasp-coverage.sh" || failed=1

    section "Status artifact"
    bash "${scripts}/check-status-artifact.sh" || failed=1

    section "Scenarios"
    bash "${scripts}/check-scenarios.sh" || failed=1

    section "Runtime bench"
    bash "${scripts}/bench-runtime-decision.sh" || failed=1

    [ "$failed" -eq 0 ] && printf '\n%sAll checks passed.%s\n' "$GREEN" "$RESET" && exit 0
    printf '\n%sOne or more checks failed.%s\n' "$RED" "$RESET" >&2
    exit 1
    ;;

  # ── fixtures ──────────────────────────────────────────────────────────────
  fixtures)
    exec bash "${scripts}/run-fixtures.sh" "$@"
    ;;

  # ── integrity ─────────────────────────────────────────────────────────────
  integrity)
    exec bash "${scripts}/verify-hooks-integrity.sh" "$@"
    ;;

  # ── status ────────────────────────────────────────────────────────────────
  status)
    exec bash "${scripts}/status-summary.sh" "$@"
    ;;

  # ── review ────────────────────────────────────────────────────────────────
  review)
    exec bash "${scripts}/review-payload.sh" "$@"
    ;;

  # ── classify ──────────────────────────────────────────────────────────────
  classify)
    exec bash "${scripts}/classify-payload.sh" "$@"
    ;;

  # ── redact ────────────────────────────────────────────────────────────────
  redact)
    exec bash "${scripts}/redact-payload.sh" "$@"
    ;;

  # ── wire ──────────────────────────────────────────────────────────────────
  wire)
    exec bash "${scripts}/wire-hooks.sh" "$@"
    ;;

  # ── log ───────────────────────────────────────────────────────────────────
  log)
    log_file="${HOME}/.openclaw/ecc-safe-plus/hook-events.log"

    # Parse sub-flags
    tail_n=""
    clear_log=0
    since_ts=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --tail)   shift; tail_n="${1:-50}" ;;
        --tail=*) tail_n="${1#--tail=}" ;;
        --clear)  clear_log=1 ;;
        --since)  shift; since_ts="${1:-}" ;;
        --since=*) since_ts="${1#--since=}" ;;
        *) die "Unknown flag: $1" ;;
      esac
      shift
    done

    if [ "$clear_log" -eq 1 ]; then
      if [ -f "$log_file" ]; then
        : > "$log_file"
        printf 'Log cleared: %s\n' "$log_file"
      else
        printf 'No log file found at %s\n' "$log_file"
      fi
      exit 0
    fi

    if [ ! -f "$log_file" ]; then
      printf 'No log file found at %s\n' "$log_file"
      printf 'Set ECC_HOOK_LOG=1 to enable event logging.\n'
      exit 0
    fi

    if [ -n "$since_ts" ]; then
      printf '%sHook event log since %s (%s):%s\n\n' "$CYAN" "$since_ts" "$log_file" "$RESET"
      node -e "
const fs = require('fs');
const lines = fs.readFileSync(process.argv[1], 'utf8').trim().split('\n').filter(Boolean);
const since = new Date(process.argv[2]).getTime();
for (const line of lines) {
  try {
    const r = JSON.parse(line);
    if (new Date(r.ts).getTime() >= since) console.log(line);
  } catch { /* skip non-JSON legacy lines */ }
}
" "$log_file" "$since_ts"
    elif [ -n "$tail_n" ]; then
      printf '%sLast %s entries from %s:%s\n\n' "$CYAN" "$tail_n" "$log_file" "$RESET"
      tail -n "$tail_n" "$log_file"
    else
      printf '%sHook event log: %s%s\n\n' "$CYAN" "$log_file" "$RESET"
      cat "$log_file"
    fi
    ;;

  # ── version ───────────────────────────────────────────────────────────────
  version)
    ver_file="${root}/VERSION"
    if [ -f "$ver_file" ]; then
      printf 'Agent Runtime Guard %s\n' "$(cat "$ver_file")"
    else
      printf 'Agent Runtime Guard (VERSION file not found)\n'
    fi
    ;;

  # ── runtime ───────────────────────────────────────────────────────────────
  runtime)
    sub="${1:-roadmap}"
    shift || true
    case "$sub" in
      roadmap)
        printf 'Runtime roadmap: %s\n' "${root}/references/runtime-autonomy-roadmap.md"
        ;;
      state)
        exec node "${scripts}/runtime-state.js" show "$@"
        ;;
      accept)
        exec node "${scripts}/runtime-state.js" accept "$@"
        ;;
      dismiss)
        exec node "${scripts}/runtime-state.js" dismiss "$@"
        ;;
      promote)
        exec node "${scripts}/runtime-state.js" promote "$@"
        ;;
      record-approval)
        exec node "${scripts}/runtime-state.js" record-approval "$@"
        ;;
      auto-allow-once)
        exec node "${scripts}/runtime-state.js" auto-allow-once "$@"
        ;;
      explain)
        exec node "${scripts}/runtime-state.js" explain "$@"
        ;;
      *)
        die "Unknown runtime subcommand: $sub"
        ;;
    esac
    ;;

  # ── help ──────────────────────────────────────────────────────────────────
  help|-h|--help)
    if [ $# -gt 0 ]; then
      sub="$1"
      # Delegate to sub-script --help where possible
      case "$sub" in
        install)  bash "${scripts}/install.sh" --help ;;
        upgrade)  bash "${scripts}/upgrade.sh" --help 2>/dev/null || printf 'Usage: upgrade.sh [INSTALLED_DIR]\n' ;;
        setup)    bash "${scripts}/setup-wizard.sh" --help ;;
        redact)   bash "${scripts}/redact-payload.sh" --help ;;
        review)   bash "${scripts}/review-payload.sh" --help 2>/dev/null || printf 'No detailed help for: review\n' ;;
        classify) bash "${scripts}/classify-payload.sh" --help 2>/dev/null || printf 'No detailed help for: classify\n' ;;
        *)
          printf '%sNo detailed help for: %s%s\n' "$YELLOW" "$sub" "$RESET"
          usage
          ;;
      esac
    else
      printf '%s%sAgent Runtime Guard CLI%s\n\n' "$BOLD" "$CYAN" "$RESET"
      usage
    fi
    ;;

  # ── unknown ───────────────────────────────────────────────────────────────
  *)
    printf '%sUnknown subcommand: %s%s\n\n' "$RED" "$cmd" "$RESET" >&2
    usage >&2
    exit 2
    ;;

esac
