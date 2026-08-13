#!/bin/bash
# =============================================================================
# Phase 1 — NVIDIA Drivers
# Installs nvidia-open, sets kernel params via systemd-boot,
# mkinitcpio modules, and the pacman hook. Verifies with nvidia-smi.
# Run via detect.sh, not directly — detect.sh confirms this is the right script
# for the GPU in this machine.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/helpers.sh"
source "$SCRIPT_DIR/common.sh"

# ── Guard ─────────────────────────────────────────────────────────────────────
phase_check 0 "Bootstrap"

if phase_already_done 1; then
    log_warn "Phase 1 already completed. Skipping."
    exit 0
fi

log_step "Phase 1: NVIDIA Drivers"
confirm "Ready to begin?" || exit 0

# ── 1. Install kernel headers and driver packages ────────────────────────────
log_step "Installing linux-headers and NVIDIA packages"
pacman_install \
    linux-headers \
    nvidia-open \
    nvidia-utils \
    lib32-nvidia-utils \
    nvidia-settings \
    opencl-nvidia \
    libvdpau \
    libxnvctrl

# ── 2. Blacklist nouveau ───────────────────────────────────────────────────────
log_step "Blacklisting nouveau driver"
sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
log_ok "nouveau blacklisted."

# ── 3. mkinitcpio modules + microcode ─────────────────────────────────────────
add_mkinitcpio_modules "nvidia nvidia_modeset nvidia_uvm nvidia_drm"
install_microcode
regen_initramfs

# ── 4. Kernel params (systemd-boot only) ──────────────────────────────────────
log_step "Setting kernel parameters for NVIDIA + Wayland"
add_kernel_param "nvidia-drm.modeset=1 nvidia-drm.fbdev=1"

# ── 5. Install pacman hook ────────────────────────────────────────────────────
log_step "Installing NVIDIA pacman hook (auto-regenerates initramfs on updates)"
sudo mkdir -p /etc/pacman.d/hooks
sudo cp "$SCRIPT_DIR/hooks/nvidia.hook" /etc/pacman.d/hooks/nvidia.hook
log_ok "nvidia.hook installed."

# ── 6. nvidia-persistenced ────────────────────────────────────────────────────
log_step "Ensuring nvidia-persistenced is enabled"
sudo systemctl enable nvidia-persistenced.service 2>/dev/null || true

# ── 7. Verify ──────────────────────────────────────────────────────────────────
log_step "Verification: loading NVIDIA modules"
sudo modprobe nvidia || log_warn "Could not load nvidia module yet — needs reboot. This is OK."

log_step "Verification: running nvidia-smi (may fail before reboot — see below)"
if nvidia-smi &>/dev/null; then
    log_ok "nvidia-smi passed — driver is live."
    nvidia-smi
else
    log_warn "nvidia-smi failed — this is EXPECTED before a reboot."
    echo -e "${YELLOW}You MUST reboot before proceeding to Phase 2.${RESET}"
    echo -e "${YELLOW}After reboot, run:${RESET} nvidia-smi"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
phase_done 1
echo -e "\n${GREEN}${BOLD}Phase 1 complete.${RESET}"
echo -e "${CYAN}→ REBOOT now.${RESET}"
echo -e "After reboot, verify with: ${BOLD}nvidia-smi${RESET}"
echo -e "If nvidia-smi shows your GPU, continue with: ${BOLD}phase2-packages/packages.sh${RESET}"
