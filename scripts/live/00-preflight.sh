#!/usr/bin/env bash
set -euo pipefail

echo "== Arch ISO preflight =="

if [[ -d /sys/firmware/efi/efivars ]]; then
  echo "[OK] Boot mode: UEFI"
else
  echo "[WARN] Boot mode does not look like UEFI. For Windows dual boot, reboot and choose the UEFI USB entry."
fi

echo
printf "Checking internet... "
if ping -c 2 archlinux.org >/dev/null 2>&1; then
  echo "OK"
else
  echo "FAILED"
  echo "Use iwctl, nmtui, or ethernet before continuing."
  echo "Examples:"
  echo "  iwctl"
  echo "  station wlan0 scan"
  echo "  station wlan0 get-networks"
  echo "  station wlan0 connect <SSID>"
fi

echo
if command -v timedatectl >/dev/null 2>&1; then
  timedatectl set-ntp true || true
  echo "[OK] NTP/time sync requested."
fi

echo
if command -v lsblk >/dev/null 2>&1; then
  echo "== Disks / partitions =="
  lsblk -f
fi

echo
if command -v efibootmgr >/dev/null 2>&1; then
  echo "== UEFI boot entries =="
  efibootmgr -v || true
fi

echo
cat <<'MSG'
Preflight done.

Before installing Arch beside Windows:
- Shrink Windows from inside Windows first.
- Leave unallocated space for Arch.
- Do not format the Windows EFI System Partition.
- Do not choose a full-disk wipe unless you want Windows gone.
- If BitLocker is enabled, suspend/backup recovery key before changing boot setup.
MSG
