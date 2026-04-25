#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$HOME/.config" "$HOME/wallpaper" "$HOME/.cache/wal"
for d in hypr waybar rofi kitty alacritty wal yazi; do
  mkdir -p "$HOME/.config/$d"
  cp -a "$ROOT_DIR/dotfiles/$d/." "$HOME/.config/$d/"
done
if [[ -d "$ROOT_DIR/dotfiles/dunst" ]]; then
  mkdir -p "$HOME/.config/dunst"
  cp -a "$ROOT_DIR/dotfiles/dunst/." "$HOME/.config/dunst/"
fi
[[ -f "$HOME/.config/waybar/themes/pywal.css" ]] && cp "$HOME/.config/waybar/themes/pywal.css" "$HOME/.config/waybar/style.css"
[[ -f "$HOME/.config/rofi/themes/pywal.rasi" ]] && cp "$HOME/.config/rofi/themes/pywal.rasi" "$HOME/.config/rofi/theme.rasi"
chmod +x "$HOME/.config/hypr/scripts/"*.sh
[[ -d "$HOME/.config/waybar/scripts" ]] && chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
echo "Dotfiles restored. Add wallpapers to ~/wallpaper, then press SUPER+W. File manager is SUPER+E -> kitty -e yazi."
