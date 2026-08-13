#!/bin/bash
# =============================================================================
# Phase 5 — Pre-Reboot Tests
# Runs before the final reboot. Checks GPU driver, configs, services.
# Vendor-aware — works on NVIDIA or AMD. Targets systemd-boot only.
# All checks must pass before you reboot.
# =============================================================================
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../scripts/helpers.sh"

PASS=0
FAIL=0

check_pass() { echo -e "  ${GREEN}✓${RESET} $*"; ((PASS++)); }
check_fail() { echo -e "  ${RED}✗${RESET} $*"; ((FAIL++)); }
check_warn() { echo -e "  ${YELLOW}!${RESET} $*"; }

echo -e "\n${BOLD}═══════════════════════════════════${RESET}"
echo -e "${BOLD} Pre-Reboot Checks${RESET}"
echo -e "${BOLD}═══════════════════════════════════${RESET}\n"

GPU_VENDOR="unknown"
lspci | grep -qi nvidia && GPU_VENDOR="nvidia"
lspci | grep -qiE 'amd|ati|radeon' && GPU_VENDOR="amd"

# ── GPU ───────────────────────────────────────────────────────────────────────
echo -e "${BOLD}GPU (${GPU_VENDOR})${RESET}"

if [[ "$GPU_VENDOR" == "nvidia" ]]; then
    nvidia-smi &>/dev/null \
        && check_pass "nvidia-smi responds" \
        || check_fail "nvidia-smi failed — driver not loaded"

    lsmod | grep -q "^nvidia " \
        && check_pass "nvidia kernel module loaded" \
        || check_fail "nvidia kernel module NOT loaded"

    lsmod | grep -q "nvidia_drm" \
        && check_pass "nvidia_drm module loaded" \
        || check_fail "nvidia_drm NOT loaded — Wayland will fail"

    [[ -f /etc/pacman.d/hooks/nvidia.hook ]] \
        && check_pass "nvidia.hook installed" \
        || check_fail "nvidia.hook missing from /etc/pacman.d/hooks/"

    [[ -f /etc/modprobe.d/blacklist-nouveau.conf ]] \
        && check_pass "nouveau blacklisted" \
        || check_warn "nouveau not explicitly blacklisted (usually fine with nvidia-open)"

elif [[ "$GPU_VENDOR" == "amd" ]]; then
    pacman -Q mesa &>/dev/null \
        && check_pass "mesa installed" \
        || check_fail "mesa NOT installed"

    pacman -Q vulkan-radeon &>/dev/null \
        && check_pass "vulkan-radeon installed" \
        || check_fail "vulkan-radeon NOT installed"

    lsmod | grep -q "^amdgpu " \
        && check_pass "amdgpu kernel module loaded" \
        || check_warn "amdgpu not loaded yet — expected before first reboot on a fresh install"
else
    check_warn "Could not determine GPU vendor via lspci — skipping GPU-specific checks"
fi

# ── Kernel params / microcode (systemd-boot only) ─────────────────────────────
echo -e "\n${BOLD}Bootloader / kernel params${RESET}"

if command -v bootctl &>/dev/null && bootctl is-installed &>/dev/null; then
    check_pass "systemd-boot is installed"
elif [[ -n "$(ls /boot/loader/entries/*.conf 2>/dev/null)" ]]; then
    check_pass "systemd-boot entries present"
else
    check_fail "systemd-boot not detected — run: sudo bootctl install"
fi

if [[ "$GPU_VENDOR" == "nvidia" ]]; then
    grep -q "nvidia-drm.modeset=1" /boot/loader/entries/*.conf 2>/dev/null \
        && check_pass "nvidia-drm.modeset=1 present in boot entry" \
        || check_fail "nvidia-drm.modeset=1 missing from systemd-boot entry"
fi

UCODE=$(detect_microcode_pkg)
if [[ -n "$UCODE" ]]; then
    pacman -Q "$UCODE" &>/dev/null \
        && check_pass "$UCODE installed" \
        || check_fail "$UCODE NOT installed"
else
    check_warn "Could not detect CPU vendor for microcode check"
fi

# ── Packages ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Key packages${RESET}"

for pkg in hyprland waybar kitty yazi rofi firefox dunst swaync pipewire wireplumber networkmanager bluez; do
    pacman -Q "$pkg" &>/dev/null \
        && check_pass "$pkg installed" \
        || check_fail "$pkg NOT installed"
done

# Check rofi-wayland specifically
if pacman -Q rofi-wayland &>/dev/null; then
    check_pass "rofi-wayland (correct Wayland build) installed"
elif pacman -Q rofi &>/dev/null; then
    check_warn "X11 'rofi' detected — may have rendering issues. Replace with rofi-wayland."
fi

# Redundancy checks — flag if old apps somehow crept back in
pacman -Q thunar &>/dev/null && check_warn "thunar installed — redundant with Yazi, consider removing"
pacman -Q swaylock &>/dev/null && check_warn "swaylock installed — redundant with Hyprlock, consider removing"
pacman -Q hyprpaper &>/dev/null && check_warn "hyprpaper installed — redundant with awww, consider removing"

# ── Services ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Services${RESET}"

systemctl is-enabled NetworkManager &>/dev/null \
    && check_pass "NetworkManager enabled" \
    || check_fail "NetworkManager NOT enabled"

systemctl is-enabled bluetooth &>/dev/null \
    && check_pass "bluetooth enabled" \
    || check_fail "bluetooth NOT enabled"

# ── Config files ──────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Config files${RESET}"

[[ -f "$HOME/.config/hypr/hyprland.conf" ]] \
    && check_pass "Hyprland config exists" \
    || check_fail "Hyprland config missing at ~/.config/hypr/hyprland.conf"

[[ -d "$HOME/.config/waybar" ]] \
    && check_pass "Waybar config dir exists" \
    || check_fail "Waybar config dir missing at ~/.config/waybar/"

[[ -f "$HOME/.config/kitty/kitty.conf" ]] \
    && check_pass "Kitty config exists" \
    || check_fail "Kitty config missing at ~/.config/kitty/kitty.conf"

[[ -f "$HOME/.config/rofi/config.rasi" ]] \
    && check_pass "Rofi config exists" \
    || check_fail "Rofi config missing at ~/.config/rofi/config.rasi"

[[ -f "$HOME/.config/swaync/style.css" ]] \
    && check_pass "swaync config exists" \
    || check_warn "swaync config missing at ~/.config/swaync/style.css"

[[ -f "$HOME/.config/wal/templates/rofi-pywal-theme.rasi" ]] \
    && check_pass "pywal rofi template exists" \
    || check_warn "pywal rofi template missing at ~/.config/wal/templates/"

[[ -x "$HOME/.config/hypr/scripts/wallpaper.sh" ]] \
    && check_pass "wallpaper.sh exists and executable" \
    || check_warn "wallpaper.sh missing or not executable at ~/.config/hypr/scripts/"

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}═══════════════════════════════════${RESET}"
echo -e "  ${GREEN}Passed: $PASS${RESET}   ${RED}Failed: $FAIL${RESET}"
echo -e "${BOLD}═══════════════════════════════════${RESET}\n"

if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}${BOLD}Fix all failures before rebooting.${RESET}"
    echo -e "Check the Troubleshooting section in README.md"
    exit 1
else
    echo -e "${GREEN}${BOLD}All checks passed. Safe to reboot.${RESET}"
    echo -e "After reboot, run: ${BOLD}phase5-tests/post-reboot.sh${RESET}"
fi
