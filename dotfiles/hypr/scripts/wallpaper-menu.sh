#!/usr/bin/env bash
set -euo pipefail
WALL_DIR="$HOME/wallpaper"
mkdir -p "$WALL_DIR"
mapfile -t W < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
(( ${#W[@]} )) || { notify-send "Wallpaper" "No wallpapers found in ~/wallpaper"; exit 1; }
C="$(printf '%s\n' "${W[@]}" | sed "s#^$WALL_DIR/##" | rofi -dmenu -i -p 'Wallpaper' -theme ~/.config/rofi/theme.rasi)"
[[ -n "$C" ]] && "$HOME/.config/hypr/scripts/setwall.sh" "$WALL_DIR/$C"
