#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$ROOT_DIR/pkg"

install_pkg_file(){
  local file="$1"
  mapfile -t pkgs < <(grep -Ev '^\s*(#|$)' "$file")
  echo "Installing ${file#$ROOT_DIR/}"
  if [[ "${AUTO_YES:-0}" == "1" ]]; then
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
  else
    sudo pacman -S --needed "${pkgs[@]}"
  fi
}

usage(){
  cat <<'EOT'
Usage: ./install.sh core|bootloader|desktop|nvidia|nvidia-dkms|gaming|dev|full

Set AUTO_YES=1 for non-interactive pacman installs, e.g. AUTO_YES=1 ./install.sh full

Groups:
  core          Base Arch additions for this setup
  bootloader    GRUB + os-prober tools for Windows/Arch dual boot
  desktop       Audio, Bluetooth, Hyprland, Waybar, rofi, awww, Yazi, file tools, utilities
  nvidia        NVIDIA driver stack for standard Arch linux kernel
  nvidia-dkms   NVIDIA DKMS stack for custom kernels
  gaming        Steam/GameMode/MangoHud/Gamescope/Discord
  dev           Coding basics only; no ML/CUDA/PyTorch/Jupyter stack
  full          Current preferred AMD CPU + NVIDIA GPU + Hyprland + gaming + dev basics
EOT
}

[[ $# -ge 1 ]] || { usage; exit 1; }

case "$1" in
  core)
    install_pkg_file "$PKG_DIR/core.txt"
    ;;
  bootloader)
    install_pkg_file "$PKG_DIR/bootloader-grub.txt"
    ;;
  desktop)
    install_pkg_file "$PKG_DIR/audio-bluetooth.txt"
    install_pkg_file "$PKG_DIR/hyprland.txt"
    install_pkg_file "$PKG_DIR/desktop-shell.txt"
    install_pkg_file "$PKG_DIR/filesystem.txt"
    install_pkg_file "$PKG_DIR/utilities.txt"
    ;;
  nvidia)
    install_pkg_file "$PKG_DIR/gpu-nvidia.txt"
    ;;
  nvidia-dkms)
    install_pkg_file "$PKG_DIR/gpu-nvidia-dkms.txt"
    ;;
  gaming)
    install_pkg_file "$PKG_DIR/gaming.txt"
    ;;
  dev)
    install_pkg_file "$PKG_DIR/dev-basic.txt"
    ;;
  full)
    install_pkg_file "$PKG_DIR/core.txt"
    install_pkg_file "$PKG_DIR/bootloader-grub.txt"
    install_pkg_file "$PKG_DIR/audio-bluetooth.txt"
    install_pkg_file "$PKG_DIR/hyprland.txt"
    install_pkg_file "$PKG_DIR/desktop-shell.txt"
    install_pkg_file "$PKG_DIR/filesystem.txt"
    install_pkg_file "$PKG_DIR/utilities.txt"
    install_pkg_file "$PKG_DIR/gpu-nvidia.txt"
    install_pkg_file "$PKG_DIR/gaming.txt"
    install_pkg_file "$PKG_DIR/dev-basic.txt"
    ;;
  *)
    usage
    exit 1
    ;;
esac
