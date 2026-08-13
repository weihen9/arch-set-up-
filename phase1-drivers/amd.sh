#!/bin/bash
# =============================================================================
# Phase 1 — AMD Graphics
# AMD GPUs use the in-kernel amdgpu driver — no DKMS, no blacklisting needed.
# This installs the userspace Mesa/Vulkan stack and verifies the kernel is
# actually using amdgpu (not falling back to the generic 'vesa'/'fbdev' driver).
# Run via detect.sh, not directly.
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

log_step "Phase 1: AMD Graphics"
log_info "amdgpu is in-kernel — this phase installs the userspace driver stack only."
confirm "Ready to begin?" || exit 0

# ── 1. Install Mesa / Vulkan userspace stack ─────────────────────────────────
log_step "Installing Mesa + Vulkan (AMD)"
pacman_install \
    linux-headers \
    mesa \
    lib32-mesa \
    vulkan-radeon \
    lib32-vulkan-radeon \
    vulkan-icd-loader \
    lib32-vulkan-icd-loader \
    libva-mesa-driver \
    lib32-libva-mesa-driver \
    mesa-vdpau \
    lib32-mesa-vdpau \
    vulkan-tools

# ── 2. Microcode (CPU vendor detected dynamically — laptop CPU may not be AMD) ─
install_microcode
regen_initramfs

# ── 3. Verify amdgpu is actually the active kernel driver ────────────────────
log_step "Verifying amdgpu is bound to the GPU"
if lspci -k | grep -A3 -Ei 'vga|3d controller' | grep -qi amdgpu; then
    log_ok "amdgpu is active."
else
    log_warn "amdgpu not showing as the active kernel driver yet."
    echo -e "${YELLOW}This is usually fine before a reboot on a fresh install.${RESET}"
    echo -e "${YELLOW}After reboot, check with:${RESET} lspci -k | grep -A3 VGA"
fi

# ── 4. Optional sanity check if vulkan-tools is present ──────────────────────
if command -v vulkaninfo &>/dev/null; then
    log_step "Running vulkaninfo summary (best-effort)"
    vulkaninfo --summary 2>/dev/null | head -20 || log_warn "vulkaninfo failed — may need a reboot first."
fi

# ── Done ──────────────────────────────────────────────────────────────────────
phase_done 1
echo -e "\n${GREEN}${BOLD}Phase 1 complete.${RESET}"
echo -e "${CYAN}→ REBOOT now.${RESET}"
echo -e "After reboot, verify with: ${BOLD}lspci -k | grep -A3 VGA${RESET} (should show 'amdgpu')"
echo -e "Then continue with: ${BOLD}phase2-packages/packages.sh${RESET}"
