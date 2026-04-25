#!/usr/bin/env bash
set -euo pipefail

CONF="$HOME/.config/hypr/hyprland.conf"

if [[ ! -f "$CONF" ]]; then
    echo "hyprland.conf not found at $CONF"
    exit 1
fi

if grep -q "windowrulev2" "$CONF" 2>/dev/null; then
    sed -i 's/windowrulev2/windowrule/g' "$CONF"
    echo "Fixed deprecated windowrulev2 -> windowrule in $CONF"
    echo "Run 'hyprctl reload' to apply."
else
    echo "No deprecated windowrulev2 found."
fi
