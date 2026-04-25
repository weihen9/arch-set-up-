#!/usr/bin/env bash
set -euo pipefail
SRC_REPO="https://github.com/elifouts/Dotfiles.git"
TMP_DIR="$(mktemp -d)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT

git clone --depth 1 "$SRC_REPO" "$TMP_DIR/Dotfiles"
mkdir -p "$HOME/wallpaper"
if [[ -d "$TMP_DIR/Dotfiles/wallpapers" ]]; then
  find "$TMP_DIR/Dotfiles/wallpapers" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -exec cp -n {} "$HOME/wallpaper/" \;
fi
echo "Wallpaper folder seeded from elifouts/Dotfiles where image files were present."
