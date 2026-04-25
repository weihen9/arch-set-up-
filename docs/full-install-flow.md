# Full install flow

This repo covers the whole process around a fresh Arch + Hyprland setup, but it intentionally does not blindly partition your drive.

## Stage 0 — Prepare Windows

Do this before booting the Arch ISO:

1. Back up important files.
2. In Windows Disk Management, shrink the Windows partition.
3. Leave the new space unallocated for Arch.
4. Disable Windows Fast Startup.
5. If BitLocker is enabled, save the recovery key and suspend protection before changing bootloader settings.

## Stage 1 — Prepare USB

Recommended: use Ventoy.

Put both the official Arch ISO and this setup zip on the Ventoy USB.

```text
/archlinux-x86_64.iso
/jason-arch-hyprland-setup-v4.zip
```

## Stage 2 — Live Arch ISO

Boot the UEFI Arch ISO and run:

```bash
./scripts/live/00-preflight.sh
./scripts/live/01-run-archinstall-guided.sh
```

Inside archinstall, choose:

| Setting | Choice |
|---|---|
| Profile | Minimal / no desktop |
| Bootloader | GRUB |
| Audio | PipeWire |
| Network | NetworkManager |
| Kernel | linux |
| CPU microcode | AMD |
| Disk | Use Windows-free/unallocated space only |
| EFI partition | Reuse existing EFI partition, do not format |

## Stage 3 — Copy repo into new install

After archinstall completes and while still in the live ISO:

```bash
./scripts/live/02-copy-repo-to-new-arch.sh <your-username>
```

## Stage 4 — First boot into Arch

After rebooting into Arch:

```bash
cd ~/arch-setup
./scripts/one-shot-postinstall.sh --efi /boot --tty-autostart
```

If your EFI mount point is `/efi`:

```bash
./scripts/one-shot-postinstall.sh --efi /efi --tty-autostart
```

## Stage 5 — Reboot into finished setup

You should get:

- GRUB with Arch and Windows Boot Manager
- NVIDIA driver stack
- Hyprland
- Waybar / rofi / awww
- Firefox + LibreWolf
- Steam / GameMode / MangoHud / Gamescope
- Yazi as the file manager
- Basic coding tools without ML/AI bloat
