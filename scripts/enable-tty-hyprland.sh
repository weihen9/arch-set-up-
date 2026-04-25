#!/usr/bin/env bash
set -euo pipefail

AUTOSTART_BLOCK='# Auto-start Hyprland on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec Hyprland
fi'

# Detect shell and modify correct profile
if [[ "$SHELL" == */zsh ]]; then
    PROFILE="$HOME/.zprofile"
elif [[ "$SHELL" == */bash ]]; then
    PROFILE="$HOME/.bash_profile"
else
    PROFILE="$HOME/.profile"
fi

if ! grep -q "exec Hyprland" "$PROFILE" 2>/dev/null; then
    echo "$AUTOSTART_BLOCK" >> "$PROFILE"
    echo "Hyprland autostart enabled in $PROFILE"
else
    echo "Hyprland autostart already configured in $PROFILE"
fi
