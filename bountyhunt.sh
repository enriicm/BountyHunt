#!/usr/bin/env bash
# ╔═══════════════════════════════════════════════════════════════════════╗
# ║  BountyHunt v2.0 — Professional Bug Bounty & Security Research       ║
# ║  Author  : bountyhunt                                                 ║
# ║  OS      : Linux · macOS · Termux (Android)                          ║
# ║  License : MIT                                                        ║
# ║  ⚠  LEGAL: Authorized targets only. See DISCLAIMER.md                ║
# ╚═══════════════════════════════════════════════════════════════════════╝

set -o pipefail
set -o nounset 2>/dev/null || true

# ── Resolve script directory ─────────────────────────────────────────────
_BH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Parse CLI flags before loading anything ──────────────────────────────
for _arg in "$@"; do
    case "$_arg" in
        --quiet|-q) export BH_QUIET=true ;;
        --auto)     export BH_AUTO=true  ;;
        --no-color) export BH_COLORS=never ;;
        --help|-h)
            cat <<'HELP'
Usage: bountyhunt.sh [--quiet] [--auto] [--no-color] [--help]

  --quiet      Suppress informational output (errors still shown)
  --auto       Non-interactive mode (for scripting / CI)
  --no-color   Disable ANSI colors
  --help       Show this message

Interactive menu is shown when no flags requiring non-interactive mode.
HELP
            exit 0 ;;
    esac
done

# ── Source core modules in dependency order ───────────────────────────────
_bh_source() {
    local file="${_BH_ROOT}/$1"
    if [[ ! -f "$file" ]]; then
        echo "[ERROR] Missing required file: $file" >&2
        exit 1
    fi
    # shellcheck source=/dev/null
    source "$file"
}

_bh_source "core/colors.sh"
_bh_source "core/config.sh"
_bh_source "core/logger.sh"
_bh_source "core/network.sh"
_bh_source "core/scope.sh"
_bh_source "core/signals.sh"
_bh_source "core/target.sh"
_bh_source "core/banner.sh"
_bh_source "core/scanner.sh"

# ── Source modules ────────────────────────────────────────────────────────
_bh_source "modules/xss.sh"
_bh_source "modules/sqli.sh"
_bh_source "modules/ssrf.sh"
_bh_source "modules/cors.sh"
_bh_source "modules/graphql.sh"
_bh_source "modules/websocket.sh"
_bh_source "modules/prototype.sh"
_bh_source "modules/mfa.sh"

# ── Source libraries ──────────────────────────────────────────────────────
_bh_source "lib/correlation.sh"
_bh_source "lib/report.sh"

# ── Ensure output directory exists ───────────────────────────────────────
mkdir -p "${BH_OUTPUT_DIR}" 2>/dev/null || {
    BH_OUTPUT_DIR="/tmp/bountyhunt_results"
    mkdir -p "$BH_OUTPUT_DIR"
}

# ── Dependency check ─────────────────────────────────────────────────────
_bh_check_deps() {
    local -a required=(curl)
    local -a optional=(bc python3 websocat)
    local missing_required=() missing_optional=()

    local dep
    for dep in "${required[@]}"; do
        command -v "$dep" &>/dev/null || missing_required+=("$dep")
    done
    for dep in "${optional[@]}"; do
        command -v "$dep" &>/dev/null || missing_optional+=("$dep")
    done

    if [[ ${#missing_required[@]} -gt 0 ]]; then
        bh_error "Missing required dependencies: ${missing_required[*]}"
        bh_error "Install with: ${BH_PKG_MGR} install ${missing_required[*]}"
        exit 1
    fi

    if [[ ${#missing_optional[@]} -gt 0 && "${BH_QUIET:-false}" != "true" ]]; then
        bh_warn "Optional tools not found: ${missing_optional[*]}"
        bh_warn "Some features may be limited."
    fi
}

_bh_check_deps

# ── Signal: save session on SIGINT/EXIT ───────────────────────────────────
trap '_bh_save_session; tput cnorm 2>/dev/null; exit 0' INT TERM EXIT

# ── Main loop ─────────────────────────────────────────────────────────────
_bh_main() {
    while true; do
        _bh_show_banner
        _bh_show_menu
        read -r option

        case "${option,,}" in
            # ── Configuration ─────────────────────────────────────────
            1)  set_target ;;
            2)  set_auth ;;
            3)  set_proxy ;;
            4)  bh_scope_menu ;;

            # ── Individual modules ────────────────────────────────────
            10) detect_xss;                  press_enter ;;
            11) detect_sqli;                 press_enter ;;
            12) detect_ssrf;                 press_enter ;;
            13) detect_cors;                 press_enter ;;
            14) detect_graphql;              press_enter ;;
            15) detect_websocket;            press_enter ;;
            16) detect_prototype_pollution;  press_enter ;;
            17) detect_mfa_bypass;           press_enter ;;

            # ── Full scans ────────────────────────────────────────────
            a)  full_scan_web ;;

            # ── Reports & utils ───────────────────────────────────────
            r)
                if [[ -z "${BH_TARGET:-}" ]]; then
                    bh_error "No target set."
                    press_enter
                else
                    generate_report
                    press_enter
                fi
                ;;
            s)  bh_show_global_summary; press_enter ;;
            h)  show_session_history ;;
            c)  bh_run_correlation; press_enter ;;

            # ── Exit ──────────────────────────────────────────────────
            0|q|quit|exit)
                _bh_save_session
                echo -e "\n  ${BGREEN}BountyHunt — Session saved. Stay legal.${RESET}\n"
                exit 0
                ;;
            *)
                bh_warn "Unknown option: '${option}'"
                sleep 0.8
                ;;
        esac
    done
}

_bh_main
