#!/usr/bin/env bash
set -euo pipefail
SRC_REPO="https://github.com/elifouts/Dotfiles.git"
TMP_DIR="$(mktemp -d)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "Cloning elifouts/Dotfiles for Waybar assets/themes/configs..."
git clone --depth 1 "$SRC_REPO" "$TMP_DIR/Dotfiles"
SRC="$TMP_DIR/Dotfiles/.config/waybar"
DEST="$HOME/.config/waybar"
mkdir -p "$DEST"

# Copy everything that affects Waybar appearance/function: config, style, scripts, themes, assets.
cp -a "$SRC/." "$DEST/"

# Keep user workflow: rofi remains launcher/menu; awww remains wallpaper daemon.
# The imported Waybar uses Pywal colors and SwayNC; both are installed by this repo.
[[ -d "$DEST/scripts" ]] && chmod +x "$DEST/scripts/"*.sh 2>/dev/null || true

if [[ -f "$DEST/style.css" ]]; then
  cp "$DEST/style.css" "$DEST/style.elifouts.css"
fi

# The repo style imports ~/.cache/wal/colors-waybar.css. Generate a default pywal cache if needed.
if [[ ! -f "$HOME/.cache/wal/colors-waybar.css" ]]; then
  first="$(find "$HOME/wallpaper" "$TMP_DIR/Dotfiles/wallpapers" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort | head -n 1 || true)"
  if [[ -n "$first" ]]; then
    mkdir -p "$HOME/wallpaper"
    cp -n "$first" "$HOME/wallpaper/" 2>/dev/null || true
    wal -q -i "$first" || true
  fi
fi

pkill waybar >/dev/null 2>&1 || true
nohup waybar >/dev/null 2>&1 &
echo "Elifouts Waybar synced into ~/.config/waybar. Original imported style saved as style.elifouts.css."
