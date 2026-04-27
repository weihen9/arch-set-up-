#!/bin/bash
# =============================================================================
# Phase 0 — Bootstrap
# Run this immediately after your first login to a fresh Arch install.
# Sets up sudo, git, base-devel, and the paru AUR helper.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/helpers.sh"

# ── Guard ─────────────────────────────────────────────────────────────────────
if phase_already_done 0; then
    log_warn "Phase 0 already completed. Skipping."
    exit 0
fi

log_step "Phase 0: Bootstrap"
log_info "This sets up sudo, git, base-devel, and the paru AUR helper."
confirm "Ready to begin?" || exit 0

# ── 1. Full system update ─────────────────────────────────────────────────────
log_step "Updating system"
sudo pacman -Syu --noconfirm

# ── 2. Core tools ─────────────────────────────────────────────────────────────
log_step "Installing core tools"
pacman_install \
    base-devel \
    git \
    nano \
    curl \
    wget \
    sudo \
    bash-completion \
    reflector \
    unzip \
    rsync

# ── 3. Fastest mirrors ────────────────────────────────────────────────────────
log_step "Updating mirrorlist (fastest Singapore/nearby mirrors)"
sudo reflector \
    --country Singapore,Japan,Australia \
    --age 12 \
    --protocol https \
    --sort rate \
    --save /etc/pacman.d/mirrorlist
log_ok "Mirrorlist updated."

# ── 4. Enable multilib (needed for 32-bit NVIDIA libs later) ─────────────────
log_step "Enabling multilib repo"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/,/^#Include/{s/^#//}' /etc/pacman.conf
    sudo pacman -Sy --noconfirm
    log_ok "multilib enabled."
else
    log_info "multilib already enabled."
fi

# ── 5. Install paru (AUR helper) ──────────────────────────────────────────────
log_step "Installing paru AUR helper"
if command -v paru &>/dev/null; then
    log_info "paru already installed."
else
    cd /tmp
    rm -rf paru
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ~
    log_ok "paru installed."
fi

# ── 6. Verify sudo works ──────────────────────────────────────────────────────
log_step "Verifying sudo"
sudo -v || die "sudo is not configured for your user. Add yourself to the wheel group."
log_ok "sudo OK."

# ── Done ──────────────────────────────────────────────────────────────────────
phase_done 0
echo -e "\n${GREEN}${BOLD}Phase 0 complete.${RESET}"
echo -e "Next: ${CYAN}REBOOT now${RESET}, then run ${BOLD}phase1-drivers/nvidia.sh${RESET}"
