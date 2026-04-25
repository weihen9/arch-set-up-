#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <new-arch-username>"
  echo "Example: $0 jason"
  exit 1
fi

USER_NAME="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_ROOT="/mnt"
TARGET_HOME="$TARGET_ROOT/home/$USER_NAME"
TARGET_REPO="$TARGET_HOME/arch-setup"

if [[ ! -d "$TARGET_ROOT/etc" ]]; then
  echo "Could not find installed Arch root at /mnt."
  echo "If archinstall unmounted it, mount your new Arch root partition to /mnt first."
  echo "Example: mount /dev/nvme0n1pX /mnt"
  exit 1
fi

if [[ ! -d "$TARGET_HOME" ]]; then
  echo "Could not find $TARGET_HOME."
  echo "Check the username you created in archinstall."
  exit 1
fi

rm -rf "$TARGET_REPO"
mkdir -p "$TARGET_REPO"
rsync -a --exclude='.git' "$REPO_DIR/" "$TARGET_REPO/"
arch-chroot "$TARGET_ROOT" chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/arch-setup"
arch-chroot "$TARGET_ROOT" bash -lc "chmod +x /home/$USER_NAME/arch-setup/install.sh /home/$USER_NAME/arch-setup/scripts/*.sh /home/$USER_NAME/arch-setup/scripts/live/*.sh /home/$USER_NAME/arch-setup/dotfiles/hypr/scripts/*.sh /home/$USER_NAME/arch-setup/dotfiles/waybar/scripts/*.sh 2>/dev/null || true"

echo "Copied repo to /home/$USER_NAME/arch-setup inside the new Arch install."
echo "After rebooting into Arch:"
echo "  cd ~/arch-setup"
echo "  ./scripts/one-shot-postinstall.sh --efi /boot --tty-autostart"
