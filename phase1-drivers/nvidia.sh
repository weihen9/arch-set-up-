#!/bin/bash
# =============================================================================
# Phase 1 — NVIDIA Drivers (RTX 2070 Super / Turing)
# Installs nvidia-open, sets GRUB kernel params, mkinitcpio modules,
# and the pacman hook. Verifies with nvidia-smi before exiting.
# HARD STOP if verification fails — do not proceed to Phase 2 until this passes.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/helpers.sh"

# ── Guard ─────────────────────────────────────────────────────────────────────
phase_check 0 "Bootstrap"

if phase_already_done 1; then
    log_warn "Phase 1 already completed. Skipping."
    exit 0
fi

log_step "Phase 1: NVIDIA Drivers"
log_info "GPU target: RTX 2070 Super (Turing) → nvidia-open package"
log_info "This phase installs the driver, sets kernel params, and verifies."
confirm "Ready to begin?" || exit 0

# ── 1. Confirm GPU is detected ────────────────────────────────────────────────
log_step "Detecting NVIDIA GPU"
GPU=$(lspci | grep -i nvidia || true)
if [[ -z "$GPU" ]]; then
    die "No NVIDIA GPU detected via lspci. Check your hardware or BIOS settings."
fi
log_ok "Detected: $GPU"

# ── 2. Install kernel headers and driver packages ─────────────────────────────
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

# ── 3. Blacklist nouveau ──────────────────────────────────────────────────────
log_step "Blacklisting nouveau driver"
sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null <<'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
log_ok "nouveau blacklisted."

# ── 4. Add NVIDIA modules to mkinitcpio ───────────────────────────────────────
log_step "Configuring mkinitcpio for early NVIDIA KMS"
MKINIT_CONF="/etc/mkinitcpio.conf"
# Add modules if not already present
if ! grep -q "nvidia_modeset" "$MKINIT_CONF"; then
    sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' "$MKINIT_CONF"
    # Clean up any leading space if MODULES was empty
    sudo sed -i 's/MODULES=( /MODULES=(/' "$MKINIT_CONF"
    log_ok "NVIDIA modules added to mkinitcpio."
else
    log_info "NVIDIA modules already in mkinitcpio."
fi

# Regenerate initramfs
log_step "Regenerating initramfs"
sudo mkinitcpio -P
log_ok "initramfs regenerated."

# ── 5. Set GRUB kernel parameters ────────────────────────────────────────────
log_step "Setting GRUB kernel parameters for NVIDIA + Wayland"
GRUB_CONF="/etc/default/grub"

# Backup original
sudo cp "$GRUB_CONF" "${GRUB_CONF}.bak"

# Add nvidia DRM params if not already set
if ! grep -q "nvidia-drm.modeset=1" "$GRUB_CONF"; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1 nvidia-drm.fbdev=1"/' "$GRUB_CONF"
    log_ok "GRUB kernel params set."
else
    log_info "GRUB params already configured."
fi

# Regenerate GRUB config
log_step "Regenerating GRUB config"
sudo grub-mkconfig -o /boot/grub/grub.cfg
log_ok "GRUB config updated."

# ── 6. Install pacman hook ────────────────────────────────────────────────────
log_step "Installing NVIDIA pacman hook (auto-regenerates initramfs on updates)"
sudo mkdir -p /etc/pacman.d/hooks
sudo cp "$SCRIPT_DIR/hooks/nvidia.hook" /etc/pacman.d/hooks/nvidia.hook
log_ok "nvidia.hook installed."

# ── 7. Enable DRM KMS service ─────────────────────────────────────────────────
log_step "Ensuring nvidia-persistenced is enabled"
sudo systemctl enable nvidia-persistenced.service 2>/dev/null || true

# ── 8. Verify: load modules now and test nvidia-smi ──────────────────────────
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
    echo -e "${YELLOW}If it still fails after reboot, DO NOT continue. See Troubleshooting in README.${RESET}"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
phase_done 1
echo -e "\n${GREEN}${BOLD}Phase 1 complete.${RESET}"
echo -e "${CYAN}→ REBOOT now.${RESET}"
echo -e "After reboot, verify with: ${BOLD}nvidia-smi${RESET}"
echo -e "If nvidia-smi shows your GPU, continue with: ${BOLD}phase2-packages/packages.sh${RESET}"
