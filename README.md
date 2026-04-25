# Arch + Hyprland Setup SOP

This SOP is for installing Arch Linux on an empty drive, then applying this Hyprland setup repo.

Target setup:

```text
CPU: AMD
GPU: NVIDIA
Desktop: Hyprland
Bar: Waybar
Launcher: rofi
Wallpaper: awww
File manager: Yazi
Browsers: Firefox + LibreWolf
Bootloader: GRUB
Package manager: pacman + AUR helper
```

---

# 1. Prepare the USB

## Option A: Ventoy

Put these files on the Ventoy USB:

```text
Ventoy USB
├── archlinux-x86_64.iso
└── this setup repo zip
```

## Option B: Normal Arch USB

Flash the official Arch ISO using Rufus, Balena Etcher, or another ISO flashing tool.

Then clone this repo later from GitHub during the Arch live environment.

---

# 2. Boot into the Arch USB

Restart the PC and enter BIOS/UEFI.

Select the USB boot option that starts with:

```text
UEFI:
```

Avoid legacy/non-UEFI boot options.

---

# 3. Check UEFI mode

Inside the Arch ISO, run:

```bash
ls /sys/firmware/efi/efivars
```

If files appear, you are in UEFI mode.

---

# 4. Connect to the internet

Check internet:

```bash
ping archlinux.org
```

If using Wi-Fi:

```bash
iwctl
```

Then inside `iwctl`:

```text
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect YOUR_WIFI_NAME
exit
```

Test again:

```bash
ping archlinux.org
```

---

# 5. Get this repo inside the Arch live environment

## Option A: Clone from GitHub

```bash
pacman -Sy --needed git
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git ~/arch-setup
cd ~/arch-setup
```

## Option B: Unzip from USB

Find the USB:

```bash
lsblk
```

Mount it:

```bash
mkdir -p /mnt/usb
mount /dev/sdX1 /mnt/usb
```

Replace `sdX1` with the correct USB partition.

Then unzip:

```bash
pacman -Sy --needed unzip
cd /mnt/usb
unzip YOUR_SETUP_ZIP_NAME.zip
cd jason-arch-hyprland-setup
```

---

# 6. Run preflight check

From inside the repo folder:

```bash
chmod +x scripts/live/*.sh
./scripts/live/00-preflight.sh
```

This checks:

```text
UEFI mode
Internet connection
Available drives
Current mount layout
```

---

# 7. Start Arch install

Run:

```bash
./scripts/live/01-run-archinstall-guided.sh
```

This launches:

```bash
archinstall
```

---

# 8. Archinstall choices for an empty drive

Use these choices:

| Setting | Choice |
|---|---|
| Boot mode | UEFI |
| Disk setup | Use entire empty drive |
| Filesystem | ext4 or btrfs |
| Bootloader | GRUB |
| Kernel | linux |
| CPU microcode | AMD |
| Audio | PipeWire |
| Network | NetworkManager |
| Profile | Minimal / no desktop |
| User account | Create normal user with sudo |
| Swap | zram or swapfile |

For an empty drive, it is okay to use:

```text
Wipe selected drive
```

Only select the drive you actually want to install Arch on.

---

# 9. If installing on a partitioned drive instead

Only follow this section if the drive already has Windows, data, or other partitions.

Do **not** choose:

```text
Wipe entire disk
```

Instead:

1. Use free/unallocated space.
2. Do not format Windows/data partitions.
3. Reuse the existing EFI partition if appropriate.
4. Do not delete the Windows Boot Manager.
5. Check the disk layout carefully with:

```bash
lsblk -f
```

Look for:

```text
EFI System Partition
Windows NTFS partition
Free/unallocated space for Arch
```

If unsure, stop at the partitioning screen and verify before continuing.

---

# 10. Copy repo into the new Arch install

After `archinstall` finishes, but before rebooting:

```bash
./scripts/live/02-copy-repo-to-new-arch.sh YOUR_USERNAME
```

Example:

```bash
./scripts/live/02-copy-repo-to-new-arch.sh jason
```

Then reboot:

```bash
reboot
```

Remove the USB when the system restarts.

---

# 11. First boot into Arch

Log into your new Arch system.

Go to the setup repo:

```bash
cd ~/arch-setup
chmod +x install.sh scripts/*.sh scripts/live/*.sh dotfiles/hypr/scripts/*.sh dotfiles/waybar/scripts/*.sh
```

---

# 12. Enable multilib

Edit pacman config:

```bash
sudo nano /etc/pacman.conf
```

Uncomment:

```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Update:

```bash
sudo pacman -Syu
```

---

# 13. Run post-install setup

Most systems use `/boot` for EFI.

Run:

```bash
./scripts/one-shot-postinstall.sh --efi /boot --tty-autostart
```

If your EFI partition is mounted at `/efi`, run:

```bash
./scripts/one-shot-postinstall.sh --efi /efi --tty-autostart
```

This installs and configures:

```text
Hyprland
Waybar
rofi
awww
Yazi
Firefox
LibreWolf
NVIDIA drivers
Steam/gaming tools
PipeWire audio
Bluetooth
NetworkManager
GRUB
dotfiles
services
```

---

# 14. Reboot

After the script finishes:

```bash
reboot
```

---

# 15. Check the system

After rebooting, check NVIDIA:

```bash
nvidia-smi
```

Check internet:

```bash
ping archlinux.org
```

Check Bluetooth:

```bash
systemctl status bluetooth
```

Check NetworkManager:

```bash
systemctl status NetworkManager
```

Check Docker, if installed:

```bash
systemctl status docker
```

---

# 16. Main keybinds

| Keybind | Action |
|---|---|
| `SUPER + SPACE` | Open rofi |
| `SUPER + W` | Open wallpaper menu |
| `SUPER + SHIFT + W` | Random wallpaper |
| `SUPER + ENTER` | Open terminal |
| `SUPER + E` | Open Yazi |
| `SUPER + Q` | Close window |
| `SUPER + 1-9` | Switch workspace |
| `SUPER + SHIFT + 1-9` | Move window to workspace |

`SUPER` means the Windows key.

---

# 17. Updating later

Update official packages:

```bash
sudo pacman -Syu
```

Update AUR packages:

```bash
paru -Syu
```

or:

```bash
yay -Syu
```

---

# 18. Saving future config changes

After changing configs, copy them back into the repo:

```bash
cp -r ~/.config/hypr dotfiles/
cp -r ~/.config/waybar dotfiles/
cp -r ~/.config/rofi dotfiles/
cp -r ~/.config/kitty dotfiles/
cp -r ~/.config/alacritty dotfiles/
cp -r ~/.config/yazi dotfiles/
```

Commit changes:

```bash
git add .
git commit -m "Update Arch Hyprland setup"
git push
```

---

# 19. Short install flow

```text
1. Boot Arch ISO USB in UEFI mode
2. Connect to internet
3. Clone or unzip this repo
4. Run 00-preflight.sh
5. Run 01-run-archinstall-guided.sh
6. Install Arch using archinstall
7. Copy repo into new Arch install
8. Reboot into Arch
9. Enable multilib
10. Run one-shot-postinstall.sh
11. Reboot
12. Use Hyprland
```
