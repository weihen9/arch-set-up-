#!/bin/bash
# =============================================================================
# Phase 1 — GPU Driver Dispatcher
# Detects the GPU vendor via lspci and runs the matching driver script.
# This is the script you actually run — not nvidia.sh or amd.sh directly.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/helpers.sh"

phase_check 0 "Bootstrap"

log_step "Phase 1: GPU Driver Detection"

GPU_LINE=$(lspci | grep -Ei 'vga|3d controller' || true)
[[ -z "$GPU_LINE" ]] && die "No GPU detected via lspci. Check your hardware."
log_info "Detected: $GPU_LINE"

if echo "$GPU_LINE" | grep -qi nvidia; then
    log_ok "NVIDIA GPU detected — running nvidia.sh"
    exec bash "$SCRIPT_DIR/nvidia.sh"
elif echo "$GPU_LINE" | grep -qiE 'amd|ati|radeon'; then
    log_ok "AMD GPU detected — running amd.sh"
    exec bash "$SCRIPT_DIR/amd.sh"
elif echo "$GPU_LINE" | grep -qi intel; then
    die "Intel GPU detected — no driver script for this yet. Intel graphics use the in-kernel 'i915' driver + 'mesa', which usually needs no extra setup beyond the mesa package already in pkglist.txt. Flag this if you want an intel.sh added."
else
    die "Unrecognised GPU vendor. Output was: $GPU_LINE"
fi
