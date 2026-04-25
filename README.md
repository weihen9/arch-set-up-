# Arch + Hyprland Setup SOP

Repo URL:

```text
https://github.com/weihen9/arch-set-up-.git
```

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

# 1. Download the Arch ISO

Go to the official Arch Linux download page:

```text
https://archlinux.org/download/
```

Download the latest installer ISO file named:

```text
archlinux-x86_64.iso
```

Use the **HTTP Direct Downloads** section.

Steps:

1. Scroll to **HTTP Direct Downloads**.
2. Choose a nearby mirror.
3. Download `archlinux-x86_64.iso`.

Do **not** download these as your installer:

```text
archlinux-bootstrap-x86_64.tar.zst
archlinux-x86_64.iso.sig
sha256sums.txt
b2sums.txt
```

The `.sig` and checksum files are only for verification. The file needed for the installer USB is:

```text
archlinux-x86_64.iso
```

---

# 2. Prepare the USB

## Option A: Ventoy

Put these files on the Ventoy USB:

```text
Ventoy USB
├── archlinux-x86_64.iso
└── this setup repo zip
```

## Option B: Normal Arch USB

Flash `archlinux-x86_64.iso` using Rufus, Balena Etcher, or another ISO flashing tool.

If using this method, clone this GitHub repo later from inside the Arch live environment.

---

# 3. Boot into the Arch USB

Restart the PC and enter BIOS/UEFI.

Select the USB boot option that starts with:

```text
UEFI:
```

Avoid legacy/non-UEFI boot options.

---

# 4. Check UEFI mode

Inside the Arch ISO, run:

```bash
ls /sys/firmware/efi/efivars
```

If files appear, you are in UEFI mode.

---

# 5. Connect to the internet

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

# 6. Clone this setup repo

Inside the Arch live environment:

```bash
pacman -Sy --needed git
git clone https://github.com/weihen9/arch-set-up-.git ~/arch-setup
cd ~/arch-setup
```

---

# 7. Run preflight check

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

# 8. Start Arch install

Run:

```bash
./scripts/live/01-run-archinstall-guided.sh
```

This launches:

```bash
archinstall
```

---

# 9. Archinstall choices for an empty drive

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

# 10. If installing on a partitioned drive instead

Only follow this section if the drive already has Windows, data, or other partitions.

Do **not** choose:

```text
Wipe entire disk
```

Instead:

1. Use free/unallocated space.
2. Do not format Windows/data partitions.
3. Reuse the existing EFI partition if appropriate.
4. Do not delete Windows Boot Manager.
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

# 11. Copy repo into the new Arch install

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

# 12. First boot into Arch

Log into your new Arch system.

Go to the setup repo:

```bash
cd ~/arch-setup
chmod +x install.sh scripts/*.sh scripts/live/*.sh dotfiles/hypr/scripts/*.sh dotfiles/waybar/scripts/*.sh
```

---

# 13. Enable multilib

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

# 14. Run post-install setup

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

# 15. Reboot

After the script finishes:

```bash
reboot
```

---

# 16. Check the system

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

# 17. Main keybinds

| Keybind | Action |
|---|---|
| `SUPER + SPACE` | Open rofi |
| `SUPER + W` | Open wallpaper menu |
| `SUPER + SHIFT + W` | Open theme menu |
| `SUPER + Q` | Open terminal |
| `SUPER + C` | Close active window |
| `SUPER + E` | Open Yazi |
| `SUPER + M` | Exit Hyprland |
| `SUPER + 1-9` | Switch workspace |
| `SUPER + SHIFT + 1-9` | Move active window to workspace |

`SUPER` means the Windows key.

There is no random wallpaper keybind in this setup.

---

# 18. Hyprland keybind config reference

Make sure the actual Hyprland config matches the README.

Use these binds:

```ini
bind = SUPER, SPACE, exec, rofi -show drun
bind = SUPER, W, exec, ~/.config/hypr/scripts/wallpaper-menu.sh
bind = SUPER SHIFT, W, exec, ~/.config/hypr/scripts/theme-menu.sh
bind = SUPER, Q, exec, kitty
bind = SUPER, C, killactive
bind = SUPER, E, exec, kitty -e yazi
bind = SUPER, M, exit
```

Remove or comment out these binds if they exist:

```ini
bind = SUPER SHIFT, W, exec, ~/.config/hypr/scripts/random-wallpaper.sh
bind = SUPER, RETURN, exec, kitty
bind = SUPER, ENTER, exec, kitty
bind = SUPER, Q, killactive
```

Workspace binds should remain:

```ini
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9

bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9
```

---

# 19. Wallpaper and theme flow

Put wallpapers in:

```bash
~/wallpaper
```

Use:

```text
SUPER + W
```

to open the wallpaper menu.

Use:

```text
SUPER + SHIFT + W
```

to open the theme menu.

The wallpaper script:

1. Opens rofi.
2. Sets the selected wallpaper with `awww`.
3. Generates colors with `pywal`.
4. Reloads Waybar.
5. Saves the selected wallpaper as the current wallpaper.

---

# 20. External Waybar source

Confirmed Waybar source:

```text
https://github.com/elifouts/Dotfiles
```

Relevant folder:

```text
https://github.com/elifouts/Dotfiles/tree/main/.config/waybar
```

Sync Waybar assets/themes/scripts with:

```bash
./scripts/sync-elifouts-waybar.sh
```

Sync wallpapers with:

```bash
./scripts/sync-elifouts-wallpapers.sh
```

---

# 21. Updating later

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

# 22. Saving future config changes

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

# 23. Short install flow

```text
1. Download archlinux-x86_64.iso from https://archlinux.org/download/
2. Put the ISO on a USB using Ventoy, Rufus, or Balena Etcher
3. Boot the USB in UEFI mode
4. Connect to internet
5. Clone this repo:
   git clone https://github.com/weihen9/arch-set-up-.git ~/arch-setup
6. Run 00-preflight.sh
7. Run 01-run-archinstall-guided.sh
8. Install Arch using archinstall
9. Copy repo into new Arch install
10. Reboot into Arch
11. Enable multilib
12. Run one-shot-postinstall.sh
13. Reboot
14. Use Hyprland
```
