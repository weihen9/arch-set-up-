# archinstall checklist for this setup

Use this checklist while going through `archinstall`.

## Must choose

- Profile: minimal / no desktop
- Bootloader: GRUB
- Network: NetworkManager
- Audio: PipeWire
- CPU microcode: AMD
- Kernel: linux
- User: create normal user with sudo/admin privileges

## Disk / dual boot warning

Choose the existing Windows-free/unallocated space for Arch.

Do not format:

- Windows partition
- Windows Recovery partition
- Existing EFI System Partition

The EFI System Partition can be reused, but should not be formatted.

## Extra packages during archinstall

Optional but useful:

```text
git base-devel networkmanager sudo nano vim
```

Most other packages are installed later by this repo.
