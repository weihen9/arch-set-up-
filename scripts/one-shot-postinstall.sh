#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EFI_MOUNT="/boot"
TTY_AUTOSTART=0
SKIP_AUR=0
SKIP_GRUB=0
AUTO_YES=0

usage(){
  cat <<'EOT'
Usage: ./scripts/one-shot-postinstall.sh [options]

Recommended:
  ./scripts/one-shot-postinstall.sh --efi /boot --tty-autostart

Options:
  --efi PATH          EFI mount point used by GRUB, usually /boot or /efi. Default: /boot
  --tty-autostart    Enable Hyprland auto-start after TTY login
  --skip-aur         Skip AUR package installation
  --skip-grub        Skip GRUB dual-boot setup
  --yes              Pass AUTO_YES=1 to install.sh for non-interactive pacman installs
  -h, --help         Show this help

This script assumes you already completed minimal Arch installation with archinstall and booted into the new Arch system.
EOT
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --efi) EFI_MOUNT="${2:-}"; shift 2 ;;
    --tty-autostart) TTY_AUTOSTART=1; shift ;;
    --skip-aur) SKIP_AUR=1; shift ;;
    --skip-grub) SKIP_GRUB=1; shift ;;
    --yes) AUTO_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

cd "$ROOT_DIR"
chmod +x install.sh scripts/*.sh scripts/live/*.sh dotfiles/hypr/scripts/*.sh dotfiles/waybar/scripts/*.sh 2>/dev/null || true

if [[ "$AUTO_YES" -eq 1 ]]; then
  AUTO_YES=1 ./install.sh full
else
  ./install.sh full
fi

./scripts/restore-dotfiles.sh

if [[ "$SKIP_AUR" -eq 0 ]]; then
  ./scripts/install-aur.sh
fi

./scripts/sync-elifouts-waybar.sh || true
./scripts/sync-elifouts-wallpapers.sh || true
./scripts/enable-services.sh

if [[ "$SKIP_GRUB" -eq 0 ]]; then
  ./scripts/setup-grub-dualboot.sh "$EFI_MOUNT"
fi

if [[ "$TTY_AUTOSTART" -eq 1 ]]; then
  ./scripts/enable-tty-hyprland.sh
fi

cat <<EOT

Post-install complete.

Next steps:
1. Reboot.
2. Choose Arch Linux from GRUB.
3. Log in.
4. If TTY autostart was enabled, Hyprland should launch after login.

If GRUB does not show Windows, boot Arch and run:
  sudo os-prober
  sudo grub-mkconfig -o /boot/grub/grub.cfg

EOT
