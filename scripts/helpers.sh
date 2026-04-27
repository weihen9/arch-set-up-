#!/bin/bash
# =============================================================================
# helpers.sh — shared functions sourced by all phase scripts
# =============================================================================

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Logging ───────────────────────────────────────────────────────────────────
log_info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
log_ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
log_step()    { echo -e "\n${BOLD}▶ $*${RESET}"; }

# ── Exit on error ─────────────────────────────────────────────────────────────
die() {
    log_error "$*"
    exit 1
}

# ── Confirm prompt ────────────────────────────────────────────────────────────
confirm() {
    local msg="${1:-Continue?}"
    read -rp "$(echo -e "${YELLOW}[?]${RESET} ${msg} [y/N] ")" ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ── Run command and die on failure ────────────────────────────────────────────
run() {
    "$@" || die "Command failed: $*"
}

# ── Phase completion flags ────────────────────────────────────────────────────
PHASE_DIR="$HOME/.arch-setup-phases"
mkdir -p "$PHASE_DIR"

phase_done() {
    local phase="$1"
    touch "$PHASE_DIR/phase${phase}.done"
    log_ok "Phase ${phase} marked complete."
}

phase_check() {
    local phase="$1"
    local name="$2"
    if [[ ! -f "$PHASE_DIR/phase${phase}.done" ]]; then
        die "Phase ${phase} (${name}) has not been completed. Run it first."
    fi
}

phase_already_done() {
    local phase="$1"
    [[ -f "$PHASE_DIR/phase${phase}.done" ]]
}

# ── Package helpers ───────────────────────────────────────────────────────────
pacman_install() {
    sudo pacman -S --needed --noconfirm "$@" || die "pacman failed to install: $*"
}

paru_install() {
    paru -S --needed --noconfirm "$@" || die "paru failed to install: $*"
}

# ── Check if a command exists ─────────────────────────────────────────────────
need_cmd() {
    command -v "$1" &>/dev/null || die "Required command not found: $1. Is Phase 0 complete?"
}
