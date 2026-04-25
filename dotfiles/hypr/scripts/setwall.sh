#!/usr/bin/env bash
set -euo pipefail
WALLPAPER="${1:-}"
[[ -z "$WALLPAPER" ]] && WALLPAPER="$(find "$HOME/wallpaper" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -n 1)"
[[ -f "$WALLPAPER" ]] || { notify-send "Wallpaper" "No wallpaper found in ~/wallpaper"; exit 1; }
mkdir -p "$HOME/.cache/wal"
awww init >/dev/null 2>&1 || true
sleep 0.2
awww img "$WALLPAPER"
wal -q -i "$WALLPAPER" || true
ln -sf "$WALLPAPER" "$HOME/.cache/current_wallpaper"
pkill waybar >/dev/null 2>&1 || true
nohup waybar >/dev/null 2>&1 &
pkill -SIGUSR1 kitty >/dev/null 2>&1 || true
notify-send "Wallpaper updated" "$(basename "$WALLPAPER")"
