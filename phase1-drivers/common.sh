#!/bin/bash
# =============================================================================
# common.sh — shared logic for phase1 GPU driver scripts (nvidia.sh / amd.sh)
# Handles the parts that don't depend on GPU vendor: microcode, headers,
# initramfs regen, bootloader-aware kernel param injection.
# =============================================================================

# ── Install CPU microcode dynamically (not hardcoded to one vendor) ─────────
install_microcode() {
    local ucode
    ucode=$(detect_microcode_pkg)
    if [[ -z "$ucode" ]]; then
        log_warn "Could not detect CPU vendor for microcode. Skipping ucode install."
        return 0
    fi
    log_step "Installing microcode: $ucode"
    pacman_install "$ucode"
    ensure_ucode_initrd "$ucode"
    log_ok "$ucode installed and wired into boot entries."
}

# ── Regenerate initramfs ──────────────────────────────────────────────────────
regen_initramfs() {
    log_step "Regenerating initramfs"
    sudo mkinitcpio -P
    log_ok "initramfs regenerated."
}

# ── Add MODULES to mkinitcpio.conf if not already present ───────────────────
# Usage: add_mkinitcpio_modules "nvidia nvidia_modeset nvidia_uvm nvidia_drm"
add_mkinitcpio_modules() {
    local modules="$1"
    local first_mod="${modules%% *}"
    local MKINIT_CONF="/etc/mkinitcpio.conf"
    if ! grep -q "$first_mod" "$MKINIT_CONF"; then
        sudo sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 ${modules})/" "$MKINIT_CONF"
        sudo sed -i 's/MODULES=( /MODULES=(/' "$MKINIT_CONF"
        log_ok "Modules added to mkinitcpio: $modules"
    else
        log_info "mkinitcpio modules already present."
    fi
}
