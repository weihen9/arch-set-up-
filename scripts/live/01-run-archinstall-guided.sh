#!/usr/bin/env bash
set -euo pipefail

cat <<'MSG'
== Recommended archinstall choices for this repo ==

Goal: minimal Arch base, Windows dual boot, AMD CPU, NVIDIA GPU, Hyprland installed later by this repo.

Use these choices inside archinstall:

- Archinstall mode/profile: Minimal / no desktop
- Boot mode: UEFI
- Bootloader: GRUB
- Audio: PipeWire
- Network: NetworkManager
- Kernel: linux
- CPU microcode: AMD
- Disk layout: install into Windows-free/unallocated space only
- EFI System Partition: reuse existing Windows EFI partition, but DO NOT format it
- User account: create your normal user and allow sudo/admin access
- Extra packages, if prompted:
  git base-devel networkmanager sudo nano vim

Do NOT choose:
- Wipe whole disk
- KDE/GNOME/Xfce desktop profile
- Legacy BIOS boot

After archinstall finishes, you can run:
  ./scripts/live/02-copy-repo-to-new-arch.sh <your-username>

Then reboot into Arch and run:
  cd ~/arch-setup
  ./scripts/one-shot-postinstall.sh --efi /boot --tty-autostart

MSG

read -r -p "Press Enter to launch archinstall, or Ctrl+C to cancel. " _
exec archinstall
