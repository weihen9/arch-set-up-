# USB workflow for this repo

This zip is not bootable by itself. Use it together with an official Arch ISO.

## Recommended USB layout using Ventoy

1. Install Ventoy onto a thumbdrive.
2. Copy these files to the root of the Ventoy drive:

```text
/archlinux-x86_64.iso
/jason-arch-hyprland-setup-v4.zip
```

3. Boot your PC and choose the UEFI Ventoy USB entry.
4. Select the Arch ISO in Ventoy.
5. Once inside the Arch ISO, connect to internet.
6. Mount the Ventoy data partition if needed:

```bash
lsblk -f
mkdir -p /mnt/usb
mount /dev/disk/by-label/Ventoy /mnt/usb
```

If the label is different, mount the correct USB data partition shown by `lsblk -f`.

7. Unzip the setup repo:

```bash
cd /mnt/usb
unzip jason-arch-hyprland-setup-v4.zip
cd jason-arch-hyprland-setup
chmod +x install.sh scripts/*.sh scripts/live/*.sh dotfiles/hypr/scripts/*.sh dotfiles/waybar/scripts/*.sh
```

8. Run live preflight:

```bash
./scripts/live/00-preflight.sh
```

9. Launch the guided archinstall flow:

```bash
./scripts/live/01-run-archinstall-guided.sh
```

10. After archinstall completes and before rebooting, copy this repo into the new Arch install:

```bash
./scripts/live/02-copy-repo-to-new-arch.sh <your-username>
```

11. Reboot into Arch, then run:

```bash
cd ~/arch-setup
./scripts/one-shot-postinstall.sh --efi /boot --tty-autostart
```

Use `/efi` instead of `/boot` if that is where your EFI System Partition is mounted.

## Why this is not fully automatic

Full automatic partitioning is risky for Windows dual boot. This repo keeps the dangerous disk-selection step inside `archinstall`, where you can manually confirm that Windows is not being wiped.
