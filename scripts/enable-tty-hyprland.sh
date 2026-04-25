#!/usr/bin/env bash
set -euo pipefail
Z="$HOME/.zprofile"
grep -q 'exec Hyprland' "$Z" 2>/dev/null && { echo "Already configured"; exit 0; }
cat >> "$Z" <<'EOT'

# Auto-start Hyprland on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec Hyprland
fi
EOT
