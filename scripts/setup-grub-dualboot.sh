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
 echo "or: ./scripts/setup-grub-dualboot.sh /efi"
 echo "Check your ESP mount with: findmnt /boot /efi"
 exit 1
fi

# Install required packages
sudo pacman -S --needed grub efibootmgr os-prober mtools

# Backup existing grub config
if [[ -f /etc/default/grub ]]; then
 sudo cp /etc/default/grub "/etc/default/grub.bak.$(date +%Y%m%d-%H%M%S)"
fi

# Enable os-prober (critical for Windows detection)
if grep -q '^#\?GRUB_DISABLE_OS_PROBER=' /etc/default/grub; then
 sudo sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
else
 echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub >/dev/null
fi

# Recommended for NVIDIA Wayland/Hyprland
if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
 if ! grep -q 'nvidia_drm.modeset=1' /etc/default/grub; then
  sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub
 fi
fi

# Mount Windows EFI partition temporarily so os-prober can find it
# Common Windows EFI partition is on the same drive or /dev/sda1, /dev/nvme0n1p1, etc.
echo "Scanning for Windows Boot Manager..."

# Try to auto-detect and mount Windows EFI if not already mounted
WINDOWS_EFI_FOUND=0
for part in $(lsblk -lnpo NAME,PARTTYPE | grep -i "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | awk '{print $1}'); do
    if [[ "$part" != "$(findmnt -no SOURCE $ESP_MOUNT 2>/dev/null || true)" ]]; then
        echo "Found additional EFI partition: $part"
        sudo mkdir -p /tmp/win-efi
        if sudo mount "$part" /tmp/win-efi 2>/dev/null; then
            if [[ -d /tmp/win-efi/EFI/Microsoft ]]; then
                echo "Windows EFI found at $part"
                WINDOWS_EFI_FOUND=1
            fi
            sudo umount /tmp/win-efi 2>/dev/null || true
        fi
    fi
done

# Also ensure the main ESP is mounted (it should be, but double-check)
if ! findmnt "$ESP_MOUNT" >/dev/null 2>&1; then
    echo "WARNING: $ESP_MOUNT is not mounted. Attempting to mount..."
    # Try to find and mount the ESP
    ESP_PART=$(lsblk -lnpo NAME,PARTTYPE,MOUNTPOINT | grep "c12a7328-f81f-11d2-ba4b-00a0c93ec93b" | grep -v " /boot\| /efi" | head -1 | awk '{print $1}')
    if [[ -n "$ESP_PART" ]]; then
        sudo mount "$ESP_PART" "$ESP_MOUNT"
    fi
fi

# Run os-prober manually to see what it detects
echo ""
echo "os-prober output:"
sudo os-prober || echo "(os-prober found no additional OSes or is still scanning)"
echo ""

# Install GRUB
sudo grub-install --target=x86_64-efi --efi-directory="$ESP_MOUNT" --bootloader-id=GRUB --recheck

# Generate config (this runs os-prober internally)
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Verify Windows was detected
if grep -qi "windows" /boot/grub/grub.cfg; then
    echo ""
    echo "✓ Windows Boot Manager detected in GRUB config."
else
    echo ""
    echo "⚠ WARNING: Windows Boot Manager NOT found in GRUB config."
    echo "  Possible fixes:"
    echo "  1. Ensure Windows drive is connected and has EFI partition"
    echo "  2. Run: sudo os-prober"
    echo "  3. Check: lsblk -f"
    echo "  4. Manually mount Windows EFI and rerun this script"
fi

echo ""
echo "GRUB dual-boot setup complete. Reboot and check boot menu."
