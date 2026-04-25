#!/usr/bin/env bash
set -euo pipefail
THEME_DIR="$HOME/.config/waybar/themes"
mapfile -t THEMES < <(
  {
    printf 'pywal\nmocha\nnord\ndefault\nexperimental\nline\nzen\n'
    find "$THEME_DIR" -maxdepth 1 -type f -name '*.css' -printf '%f\n' 2>/dev/null | sed 's/\.css$//'
  } | awk 'NF && !seen[$0]++'
)
T="$(printf '%s\n' "${THEMES[@]}" | rofi -dmenu -i -p 'Waybar theme' -theme ~/.config/rofi/theme.rasi)"
[[ -z "$T" ]] && exit 0
if [[ -f "$THEME_DIR/$T.css" ]]; then
  cp "$THEME_DIR/$T.css" "$HOME/.config/waybar/style.css"
elif [[ -f "$THEME_DIR/$T/style-$T.css" ]]; then
  cp "$THEME_DIR/$T/style-$T.css" "$HOME/.config/waybar/style.css"
elif [[ -f "$THEME_DIR/$T/style.css" ]]; then
  cp "$THEME_DIR/$T/style.css" "$HOME/.config/waybar/style.css"
fi
if [[ -f "$THEME_DIR/$T/config-$T" ]]; then
  cp "$THEME_DIR/$T/config-$T" "$HOME/.config/waybar/config"
elif [[ -f "$THEME_DIR/$T/config" ]]; then
  cp "$THEME_DIR/$T/config" "$HOME/.config/waybar/config"
fi
[[ -f "$HOME/.config/rofi/themes/$T.rasi" ]] && cp "$HOME/.config/rofi/themes/$T.rasi" "$HOME/.config/rofi/theme.rasi"
pkill waybar >/dev/null 2>&1 || true
nohup waybar >/dev/null 2>&1 &
notify-send "Theme switched" "$T"
