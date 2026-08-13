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

yay_install() {
    yay -S --needed --noconfirm "$@" || die "yay failed to install: $*"
}

# ── Check if a command exists ─────────────────────────────────────────────────
need_cmd() {
    command -v "$1" &>/dev/null || die "Required command not found: $1. Is Phase 0 complete?"
}

# ── CPU vendor / microcode ────────────────────────────────────────────────────
# Returns "amd-ucode" or "intel-ucode" based on the actual running CPU,
# instead of assuming one vendor for every machine this repo runs on.
detect_microcode_pkg() {
    local vendor
    vendor=$(grep -m1 '^vendor_id' /proc/cpuinfo | awk '{print $3}')
    case "$vendor" in
        AuthenticAMD) echo "amd-ucode" ;;
        GenuineIntel) echo "intel-ucode" ;;
        *) echo "" ;;  # unknown vendor — caller should handle gracefully
    esac
}

# ── Bootloader check ───────────────────────────────────────────────────────────
# This repo targets systemd-boot only. It still *checks* rather than assuming,
# because "systemd-boot is installed" and "systemd-boot is what pacman thinks
# is installed" aren't the same claim — but there's no GRUB branch anymore.
require_systemd_boot() {
    if command -v bootctl &>/dev/null && bootctl is-installed &>/dev/null; then
        return 0
    fi
    if [[ -d /boot/loader/entries ]] && ls /boot/loader/entries/*.conf &>/dev/null; then
        return 0
    fi
    die "systemd-boot not detected. This repo assumes systemd-boot — install it first:
  sudo bootctl install
Then re-run this phase."
}

# ── Add a kernel cmdline param to the systemd-boot entry ─────────────────────
# Usage: add_kernel_param "nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
add_kernel_param() {
    local param="$1"
    require_systemd_boot

    local entry_found=0
    for entry in /boot/loader/entries/*.conf; do
        [[ -e "$entry" ]] || continue
        # Skip fallback/rescue entries — only patch the main entry
        [[ "$entry" == *fallback* || "$entry" == *rescue* ]] && continue
        if grep -q "$param" "$entry"; then
            log_info "Kernel param already set in $(basename "$entry")."
        else
            sudo cp "$entry" "${entry}.bak"
            sudo sed -i "/^options/ s/\$/ $param/" "$entry"
            log_ok "Added kernel param to $(basename "$entry")."
        fi
        entry_found=1
    done
    [[ "$entry_found" -eq 0 ]] && die "No systemd-boot entries found in /boot/loader/entries/."
}

# ── Ensure a ucode image is loaded before the main initramfs ────────────────
# systemd-boot does NOT auto-detect microcode — each boot entry needs an
# explicit `initrd /amd-ucode.img` (or intel-ucode.img) line ABOVE the main
# initramfs line, or it never gets loaded.
ensure_ucode_initrd() {
    local ucode_pkg="$1"   # e.g. amd-ucode or intel-ucode
    local ucode_img="/${ucode_pkg}.img"
    require_systemd_boot

    for entry in /boot/loader/entries/*.conf; do
        [[ -e "$entry" ]] || continue
        [[ "$entry" == *fallback* || "$entry" == *rescue* ]] && continue
        if grep -q "$ucode_img" "$entry"; then
            log_info "$(basename "$entry") already references $ucode_img."
            continue
        fi
        sudo cp "$entry" "${entry}.bak"
        # Insert the ucode initrd line immediately before the first existing initrd line
        sudo sed -i "0,/^initrd/{s|^initrd|initrd  ${ucode_img}\ninitrd|}" "$entry"
        log_ok "Added ${ucode_img} to $(basename "$entry")."
    done
}
