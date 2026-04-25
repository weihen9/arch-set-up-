# Arch + Hyprland Setup SOP

Repo URL:
```text
https://github.com/weihen9/arch-set-up-.git
```

This SOP is for installing Arch Linux with `archinstall`, then applying this Hyprland setup repo.

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

# Phase 1: Install Arch Linux (Live USB)

## 1. Download and prepare Arch ISO

Download `archlinux-x86_64.iso` from https://archlinux.org/download/

Flash to USB with Ventoy, Rufus, or Balena Etcher.

## 2. Boot USB in UEFI mode

Enter BIOS/UEFI and select the USB boot option starting with `UEFI:`.

Verify UEFI mode inside the live environment:
```bash
ls /sys/firmware/efi/efivars
```

## 3. Connect to internet

```bash
ping archlinux.org
```

For Wi-Fi:
```bash
iwctl
device list
station wlan0 scan
station wlan0 get-networks
station wlan0 connect YOUR_WIFI_NAME
exit
```

## 4. Run `archinstall`

```bash
archinstall
```

### Archinstall settings:

| Setting | Choice |
|---------|--------|
| Boot mode | UEFI |
| Disk | Select your target drive only |
| Disk setup | Wipe entire disk (empty drive) OR manual partitioning (dual-boot) |
| Filesystem | ext4 or btrfs |
| Bootloader | GRUB |
| Kernel | linux |
| CPU microcode | AMD |
| Audio | **None** (setup script installs PipeWire) |
| Bluetooth | **Skip** (setup script handles it) |
| Network | NetworkManager |
| Profile | **Minimal / no desktop** |
| Additional packages | `git nano` |
| User account | Create normal user with sudo |
| Swap | zram or swapfile |

### For dual-boot with Windows:

- **Do not** wipe the Windows drive
- Reuse the existing EFI System Partition (mount at `/boot`)
- Only format partitions for Arch
- Do not delete Windows Boot Manager

## 5. Reboot into new Arch system

```bash
reboot
```
Remove the USB.

---

# Phase 2: Post-Install Setup (Inside new Arch system)

> **IMPORTANT:** All remaining steps run inside your newly installed Arch system, NOT the live USB.

## 6. First boot — log in and connect

Log in as the user you created during `archinstall`.

Verify internet:
```bash
ping archlinux.org
```

If Wi-Fi isn't connected:
```bash
nmcli device wifi list
nmcli device wifi connect "YOUR_WIFI_NAME" password "YOUR_PASSWORD"
```

## 7. Clone this setup repo

```bash
git clone https://github.com/weihen9/arch-set-up-.git ~/arch-setup
cd ~/arch-setup
```

## 8. Make scripts executable

```bash
chmod +x install.sh scripts/*.sh dotfiles/hypr/scripts/*.sh dotfiles/waybar/scripts/*.sh
```

## 9. Enable multilib

```bash
sudo nano /etc/pacman.conf
```
Uncomment:
```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```
Save and update:
```bash
sudo pacman -Syu
```

## 10. Run post-install setup

Most systems use `/boot` for EFI.

```bash
./scripts/one-shot-postinstall.sh --efi /boot --tty-autostart
```

If your EFI partition is mounted at `/efi`:
```bash
./scripts/one-shot-postinstall.sh --efi /efi --tty-autostart
```

This installs and configures:
- Hyprland, Waybar, rofi, awww, Yazi
- Firefox, LibreWolf
- NVIDIA drivers (`nvidia` + `nvidia-utils`)
- Steam/gaming tools
- PipeWire audio, Bluetooth, NetworkManager
- GRUB dual-boot (with `os-prober`)
- Dotfiles and services

## 11. Reboot

```bash
sudo reboot
```

## 12. Verify everything works

After reboot, Hyprland should autostart on TTY1.

Check NVIDIA:
```bash
nvidia-smi
```

Check services:
```bash
systemctl status bluetooth
systemctl status NetworkManager
```

---

# Keybinds

| Keybind | Action |
|---------|--------|
| `SUPER + SPACE` | Open rofi |
| `SUPER + W` | Open wallpaper menu |
| `SUPER + SHIFT + W` | Open theme menu |
| `SUPER + Q` | Open terminal (kitty) |
| `SUPER + C` | Close active window |
| `SUPER + E` | Open Yazi file manager |
| `SUPER + M` | Exit Hyprland |
| `SUPER + 1-9` | Switch workspace |
| `SUPER + SHIFT + 1-9` | Move window to workspace |

---

# Troubleshooting

## Hyprland config errors (`windowrulev2` deprecated)

If you see red error text about `windowrulev2`, fix with:
```bash
sed -i 's/windowrulev2/windowrule/g' ~/.config/hypr/hyprland.conf
hyprctl reload
```

## Waybar shows CSS import error

If Waybar fails to load with `colors-waybar.css` missing:
```bash
# Ensure you have wallpapers
ls ~/wallpaper/
# If empty, add images then run:
wget -O ~/wallpaper/default.jpg "https://w.wallhaven.cc/full/85/wallhaven-8586my.png"
wal -i ~/wallpaper/default.jpg
```

## Rofi theme errors

If rofi shows missing color variables:
```bash
wal -i ~/wallpaper/$(ls ~/wallpaper/ | head -1)
```

## NVIDIA `nvidia-smi` not found after install

The `nvidia` package may not have installed correctly. Fix:
```bash
sudo pacman -S nvidia nvidia-utils
sudo reboot
```

## No Hyprland autostart

If you get dropped to TTY instead of Hyprland:
```bash
cd ~/arch-setup
./scripts/enable-tty-hyprland.sh
```

Or manually add to `~/.bash_profile`:
```bash
echo 'if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec Hyprland; fi' >> ~/.bash_profile
```

---

# Updating

Official packages:
```bash
sudo pacman -Syu
```

AUR packages:
```bash
paru -Syu
# or
yay -Syu
```

---

# Saving config changes

After modifying configs in `~/.config/`, copy back to the repo:
```bash
cd ~/arch-setup
cp -r ~/.config/hypr dotfiles/
cp -r ~/.config/waybar dotfiles/
cp -r ~/.config/rofi dotfiles/
cp -r ~/.config/kitty dotfiles/
cp -r ~/.config/yazi dotfiles/
git add .
git commit -m "Update configs"
git push
```
