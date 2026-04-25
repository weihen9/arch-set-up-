#!/usr/bin/env bash
/usr/lib/polkit-kde-authentication-agent-1 >/dev/null 2>&1 &
nm-applet --indicator >/dev/null 2>&1 &
blueman-applet >/dev/null 2>&1 &
udiskie -t >/dev/null 2>&1 &
swaync >/dev/null 2>&1 &
wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
wl-paste --type image --watch cliphist store >/dev/null 2>&1 &
if [[ -L "$HOME/.cache/current_wallpaper" || -f "$HOME/.cache/current_wallpaper" ]]; then
  "$HOME/.config/hypr/scripts/setwall.sh" "$(readlink -f "$HOME/.cache/current_wallpaper")" >/dev/null 2>&1 &
else
  first="$(find "$HOME/wallpaper" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -n 1)"
  [[ -n "$first" ]] && "$HOME/.config/hypr/scripts/setwall.sh" "$first" >/dev/null 2>&1 &
fi
pkill waybar >/dev/null 2>&1 || true
waybar >/dev/null 2>&1 &
