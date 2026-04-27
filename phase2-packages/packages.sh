#!/bin/bash
# =============================================================================
# Phase 2 — Core Packages
# Installs all system-level packages from pkglist.txt.
# Requires Phase 1 (NVIDIA) to be done and nvidia-smi to be working.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/helpers.sh"

# ── Guards ────────────────────────────────────────────────────────────────────
phase_check 0 "Bootstrap"
phase_check 1 "NVIDIA Drivers"

if phase_already_done 2; then
    log_warn "Phase 2 already completed. Skipping."
    exit 0
fi

# ── Verify nvidia-smi before continuing ───────────────────────────────────────
log_step "Verifying NVIDIA driver is working"
if ! nvidia-smi &>/dev/null; then
    die "nvidia-smi failed. You must reboot after Phase 1 and verify the driver works before running Phase 2."
fi
log_ok "nvidia-smi OK — driver is live."

log_step "Phase 2: Core Packages"
confirm "This will install all packages from pkglist.txt. Continue?" || exit 0

# ── Parse pkglist.txt (strip comments and blank lines) ────────────────────────
PKGLIST="$SCRIPT_DIR/pkglist.txt"
[[ -f "$PKGLIST" ]] || die "pkglist.txt not found at $PKGLIST"

mapfile -t PACKAGES < <(grep -v '^\s*#' "$PKGLIST" | grep -v '^\s*$' | awk '{print $1}')
log_info "Installing ${#PACKAGES[@]} packages..."

# ── Install via pacman ────────────────────────────────────────────────────────
log_step "Running pacman install"
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}" || {
    log_warn "Some packages may have failed. Attempting individual installs for diagnosis..."
    for pkg in "${PACKAGES[@]}"; do
        sudo pacman -S --needed --noconfirm "$pkg" || log_warn "FAILED: $pkg (skipping)"
    done
}

# ── Enable essential services ─────────────────────────────────────────────────
log_step "Enabling system services"
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
log_ok "NetworkManager and bluetooth enabled."

# ── Start services now ────────────────────────────────────────────────────────
sudo systemctl start NetworkManager
sudo systemctl start bluetooth

# ── Done ──────────────────────────────────────────────────────────────────────
phase_done 2
echo -e "\n${GREEN}${BOLD}Phase 2 complete.${RESET}"
echo -e "Next: ${BOLD}phase3-desktop/desktop.sh${RESET}"
