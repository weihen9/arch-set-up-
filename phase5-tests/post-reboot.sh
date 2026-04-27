#!/bin/bash
# =============================================================================
# Phase 5 — Post-Reboot Tests
# Run after the final reboot. Verifies the full desktop is working.
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
echo -e "${BOLD} Post-Reboot Checks${RESET}"
echo -e "${BOLD}═══════════════════════════════════${RESET}\n"

# ── NVIDIA ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}NVIDIA${RESET}"

nvidia-smi &>/dev/null \
    && check_pass "nvidia-smi OK" \
    || check_fail "nvidia-smi failed — see NVIDIA Troubleshooting in README"

lsmod | grep -q "^nvidia_drm " \
    && check_pass "nvidia_drm module active" \
    || check_fail "nvidia_drm not active after reboot"

# Check DRM modeset is active
if cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null | grep -q "Y"; then
    check_pass "nvidia_drm modeset=Y (confirmed active)"
else
    check_warn "nvidia_drm modeset might not be active — check kernel params"
fi

# ── Display / Wayland ─────────────────────────────────────────────────────────
echo -e "\n${BOLD}Wayland / Display${RESET}"

[[ -n "${WAYLAND_DISPLAY:-}" ]] \
    && check_pass "WAYLAND_DISPLAY set: $WAYLAND_DISPLAY" \
    || check_warn "WAYLAND_DISPLAY not set — are you in a Hyprland session?"

[[ -n "${XDG_SESSION_TYPE:-}" ]] && [[ "$XDG_SESSION_TYPE" == "wayland" ]] \
    && check_pass "XDG_SESSION_TYPE=wayland" \
    || check_warn "XDG_SESSION_TYPE is '${XDG_SESSION_TYPE:-unset}' — expected 'wayland'"

# ── Running processes ─────────────────────────────────────────────────────────
echo -e "\n${BOLD}Running processes${RESET}"

pgrep -x waybar &>/dev/null \
    && check_pass "waybar is running" \
    || check_warn "waybar not running (start it with: waybar &)"

# Check for double waybar (the bug you had)
WAYBAR_COUNT=$(pgrep -c waybar 2>/dev/null || echo 0)
if [[ "$WAYBAR_COUNT" -gt 1 ]]; then
    check_fail "Multiple waybar instances detected ($WAYBAR_COUNT) — run: pkill waybar && waybar &"
elif [[ "$WAYBAR_COUNT" -eq 1 ]]; then
    check_pass "Exactly one waybar instance (no duplicates)"
fi

pgrep -x dunst &>/dev/null \
    && check_pass "dunst notification daemon running" \
    || check_warn "dunst not running"

# ── Network ───────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Network${RESET}"

systemctl is-active NetworkManager &>/dev/null \
    && check_pass "NetworkManager active" \
    || check_fail "NetworkManager not running — run: sudo systemctl start NetworkManager"

ping -c 1 -W 3 archlinux.org &>/dev/null \
    && check_pass "Internet reachable" \
    || check_warn "Cannot reach archlinux.org — check network connection"

# ── Audio ─────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Audio${RESET}"

systemctl --user is-active pipewire &>/dev/null \
    && check_pass "pipewire running" \
    || check_warn "pipewire not running — run: systemctl --user start pipewire"

systemctl --user is-active wireplumber &>/dev/null \
    && check_pass "wireplumber running" \
    || check_warn "wireplumber not running — run: systemctl --user start wireplumber"

# ── Bluetooth ─────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Bluetooth${RESET}"

systemctl is-active bluetooth &>/dev/null \
    && check_pass "bluetooth service active" \
    || check_warn "bluetooth not running — run: sudo systemctl start bluetooth"

# ── Apps ──────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Applications${RESET}"

for cmd in kitty yazi rofi firefox hyprland waybar; do
    command -v "$cmd" &>/dev/null \
        && check_pass "$cmd in PATH" \
        || check_fail "$cmd not found"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}═══════════════════════════════════${RESET}"
echo -e "  ${GREEN}Passed: $PASS${RESET}   ${RED}Failed: $FAIL${RESET}"
echo -e "${BOLD}═══════════════════════════════════${RESET}\n"

if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}${BOLD}Some checks failed. See README Troubleshooting section.${RESET}"
    exit 1
else
    echo -e "${GREEN}${BOLD}All checks passed. Setup complete!${RESET}"
fi
