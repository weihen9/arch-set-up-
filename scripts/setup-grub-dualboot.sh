#!/usr/bin/env bash
set -euo pipefail

ESP_MOUNT="${1:-/boot}"

if [[ ! -d /sys/firmware/efi/efivars ]]; then
  echo "This system does not appear to be booted in UEFI mode. Stop."
  exit 1
fi

if [[ ! -d "$ESP_MOUNT/EFI" ]]; then
  echo "Expected EFI directory not found at $ESP_MOUNT/EFI."
  echo "Usage: ./scripts/setup-grub-dualboot.sh /boot"
  echo "or:    ./scripts/setup-grub-dualboot.sh /efi"
  echo "Check your ESP mount with: findmnt /boot /efi"
  exit 1
fi

sudo pacman -S --needed grub efibootmgr os-prober mtools

if [[ -f /etc/default/grub ]]; then
  sudo cp /etc/default/grub "/etc/default/grub.bak.$(date +%Y%m%d-%H%M%S)"
fi

if grep -q '^#\?GRUB_DISABLE_OS_PROBER=' /etc/default/grub; then
  sudo sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
else
  echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub >/dev/null
fi

# Recommended for NVIDIA Wayland/Hyprland.
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
  if ! grep -q 'nvidia_drm.modeset=1' /etc/default/grub; then
    sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub
  fi
fi

sudo grub-install --target=x86_64-efi --efi-directory="$ESP_MOUNT" --bootloader-id=GRUB --recheck
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "GRUB dual-boot setup complete. Reboot and check that Windows Boot Manager appears."
