#!/bin/bash
# =============================================================================
# Phase 3 — Desktop Environment
# Installs Hyprland (compositor), Waybar, Rofi, Kitty, Yazi,
# Firefox, and LibreWolf. Order matters — compositor first.
# "awww" = Hyprland in this setup. If you meant a different compositor,
# swap hyprland for it here and in phase4 configs.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/helpers.sh"

# ── Guards ────────────────────────────────────────────────────────────────────
phase_check 0 "Bootstrap"
phase_check 1 "NVIDIA Drivers"
phase_check 2 "Core Packages"

if phase_already_done 3; then
    log_warn "Phase 3 already completed. Skipping."
    exit 0
fi

need_cmd paru

log_step "Phase 3: Desktop Environment"
log_info "Installing: Hyprland, Waybar, Rofi (Wayland), Kitty, Yazi, Firefox, LibreWolf"
confirm "Ready?" || exit 0

# ── 1. Hyprland (compositor / 'awww') ────────────────────────────────────────
log_step "Installing Hyprland"
pacman_install hyprland hyprpaper hypridle hyprlock hyprutils

# ── 2. Waybar ─────────────────────────────────────────────────────────────────
log_step "Installing Waybar"
# Kill any existing waybar instances to prevent duplicates
pkill waybar 2>/dev/null || true
pacman_install waybar

# ── 3. Rofi (Wayland build) ───────────────────────────────────────────────────
log_step "Installing Rofi (Wayland)"
# rofi-wayland from AUR — NOT the official 'rofi' package which is X11 only
# This is critical: using the wrong rofi causes theming and rendering issues
if pacman -Q rofi &>/dev/null; then
    log_warn "X11 rofi is installed. Removing it and replacing with rofi-wayland..."
    sudo pacman -Rns rofi --noconfirm || true
fi
paru_install rofi-wayland

# ── 4. Kitty terminal ─────────────────────────────────────────────────────────
log_step "Installing Kitty"
pacman_install kitty

# ── 5. Yazi file manager ──────────────────────────────────────────────────────
log_step "Installing Yazi"
pacman_install yazi
# Yazi optional deps for full functionality
pacman_install \
    ffmpegthumbnailer \
    unar \
    jq \
    poppler \
    fd \
    ripgrep \
    fzf \
    zoxide \
    imagemagick

# ── 6. Browsers ───────────────────────────────────────────────────────────────
log_step "Installing Firefox"
pacman_install firefox

log_step "Installing LibreWolf (AUR)"
paru_install librewolf-bin

# ── 7. Notification daemon ────────────────────────────────────────────────────
log_step "Installing Dunst (notification daemon)"
pacman_install dunst

# ── 8. App launcher extras ────────────────────────────────────────────────────
log_step "Installing Rofi themes and emoji picker"
paru_install rofi-emoji || log_warn "rofi-emoji optional — skipping if failed"

# ── Done ──────────────────────────────────────────────────────────────────────
phase_done 3
echo -e "\n${GREEN}${BOLD}Phase 3 complete.${RESET}"
echo -e "Next: ${BOLD}phase4-dotfiles/dots.sh${RESET}"
