#!/bin/bash
# =============================================================================
# Phase 5 — Pre-Reboot Tests
# Runs before the final reboot. Checks NVIDIA, configs, services.
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

# ── NVIDIA ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}NVIDIA${RESET}"

nvidia-smi &>/dev/null \
    && check_pass "nvidia-smi responds" \
    || check_fail "nvidia-smi failed — driver not loaded"

lsmod | grep -q "^nvidia " \
    && check_pass "nvidia kernel module loaded" \
    || check_fail "nvidia kernel module NOT loaded"

lsmod | grep -q "nvidia_drm" \
    && check_pass "nvidia_drm module loaded" \
    || check_fail "nvidia_drm NOT loaded — Wayland will fail"

grep -q "nvidia-drm.modeset=1" /etc/default/grub \
    && check_pass "nvidia-drm.modeset=1 in GRUB" \
    || check_fail "nvidia-drm.modeset=1 missing from /etc/default/grub"

[[ -f /etc/pacman.d/hooks/nvidia.hook ]] \
    && check_pass "nvidia.hook installed" \
    || check_fail "nvidia.hook missing from /etc/pacman.d/hooks/"

# ── Packages ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Key packages${RESET}"

for pkg in hyprland waybar kitty yazi rofi firefox dunst pipewire wireplumber networkmanager bluez; do
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

# ── GRUB ──────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Bootloader${RESET}"

[[ -f /boot/grub/grub.cfg ]] \
    && check_pass "grub.cfg exists" \
    || check_fail "grub.cfg missing — run: sudo grub-mkconfig -o /boot/grub/grub.cfg"

[[ -f /etc/modprobe.d/blacklist-nouveau.conf ]] \
    && check_pass "nouveau blacklisted" \
    || check_warn "nouveau not explicitly blacklisted (usually fine with nvidia-open)"

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
