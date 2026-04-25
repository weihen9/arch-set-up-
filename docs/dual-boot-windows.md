# Windows + Arch dual boot notes

This setup uses **GRUB** as the recommended dual-boot bootloader.

Reasoning:

- **GRUB** is not the prettiest or fastest option, but it is common, well-documented, and easy to repair from an Arch ISO.
- **systemd-boot** is simpler and fast, but it has a plainer menu and may need more manual work depending on how your Windows EFI partition is laid out.
- **rEFInd** is prettier and auto-detects operating systems well, but it adds another layer to learn and fix.

For this repo, reliability and repairability take priority over appearance.

## Before installing Arch beside Windows

1. Back up important Windows files.
2. Disable Windows Fast Startup.
3. Check that Windows is installed in UEFI mode.
4. Boot the Arch ISO in UEFI mode too.
5. Prefer installing Windows first, then Arch.
6. If both systems are on the same drive, do not delete the Windows EFI System Partition.
7. If both systems are on separate drives, keep each OS on its own drive if possible. This is easier to recover.

## Recommended archinstall choices

- Bootloader: GRUB
- Profile: Minimal / no desktop
- Audio: PipeWire
- Network: NetworkManager
- Kernel: `linux`
- Filesystem: ext4 for simple recovery, or Btrfs if you want snapshots later

## After first boot

Install the bootloader package group:

```bash
./install.sh bootloader
```

Then configure GRUB for dual boot:

```bash
./scripts/setup-grub-dualboot.sh /boot
```

If your EFI System Partition is mounted at `/efi` instead:

```bash
./scripts/setup-grub-dualboot.sh /efi
```

Check your mount points with:

```bash
findmnt /boot /efi
```

## Custom boot menu appearance

GRUB can be themed later by editing `/etc/default/grub` and adding a theme path, for example:

```bash
GRUB_THEME="/boot/grub/themes/my-theme/theme.txt"
```

Then regenerate the config:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

I am not including a GRUB theme by default because visual themes can break or hide useful boot/debug text. Start plain first, confirm Windows + Arch boot reliably, then theme it.
