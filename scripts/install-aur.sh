#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if ! command -v paru >/dev/null 2>&1; then
  sudo pacman -S --needed base-devel git
  tmpdir="$(mktemp -d)"
  git clone https://aur.archlinux.org/paru-bin.git "$tmpdir/paru-bin"
  cd "$tmpdir/paru-bin"
  makepkg -si
  cd - >/dev/null
  rm -rf "$tmpdir"
fi
mapfile -t aur_pkgs < <(grep -Ev '^\s*(#|$)' "$ROOT_DIR/pkg/aur.txt")
paru -S --needed "${aur_pkgs[@]}"
