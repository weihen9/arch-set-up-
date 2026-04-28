# Arch Linux Setup — SOP

Personal Arch setup for AMD CPU + NVIDIA RTX 2070 Super.
Stack: Hyprland · Waybar · Rofi · Kitty · Yazi · Firefox · LibreWolf.

> **"awww" = Hyprland** in this repo. If you meant a different compositor, swap `hyprland` in phase3 and phase4 configs.

---

## Hardware Context

| Component | Spec | Notes |
|-----------|------|-------|
| CPU | AMD | `amd-ucode` + `vulkan-radeon` + `mesa` |
| GPU | NVIDIA RTX 2070 Super (Turing) | `nvidia-open` — no AUR fallback needed |
| Drive 1 | Arch SSD | Install target |
| Drive 2 | Windows SSD | Separate drive, no interference |

---

## Repo Structure

```
arch-setup/
├── README.md                        ← you are here (full SOP)
├── scripts/helpers.sh               ← shared functions for all phase scripts
├── phase0-base/bootstrap.sh
├── phase1-drivers/
│   ├── nvidia.sh
│   └── hooks/nvidia.hook
├── phase2-packages/
│   ├── packages.sh
│   └── pkglist.txt
├── phase3-desktop/desktop.sh
├── phase4-dotfiles/
│   ├── dots.sh
│   └── configs/                     ← your config files live here
│       ├── hyprland/
│       ├── waybar/                  ← populated from elifouts/Dotfiles by dots.sh
│       ├── rofi/
│       ├── kitty/
│       └── yazi/
└── phase5-tests/
    ├── pre-reboot.sh
    └── post-reboot.sh
```

---

## Quick Reference — Run Order

```
1.  Install Arch (see Pre-Install below)
2.  First login → pacman -Sy git base-devel --noconfirm
3.  git clone https://github.com/weihen9/arch-set-up-.git ~/arch-setup && cd ~/arch-setup
4.  bash phase0-base/bootstrap.sh
5.  REBOOT
6.  bash phase1-drivers/nvidia.sh
7.  REBOOT → verify: nvidia-smi
8.  bash phase2-packages/packages.sh
9.  bash phase3-desktop/desktop.sh
10. bash phase4-dotfiles/dots.sh
11. bash phase5-tests/pre-reboot.sh   ← all must pass
12. REBOOT
13. bash phase5-tests/post-reboot.sh  ← all must pass
```

---

## Pre-Install

### BIOS Settings (do this before booting the USB)

1. Enter BIOS (usually `DEL` or `F2` on boot)
2. **Disable Secure Boot** — NVIDIA open modules won't load with Secure Boot on
3. **Disable CSM / Legacy Boot** — use UEFI only
4. **Boot order**: set your Arch USB as first boot device
5. **Optional but recommended**: physically unplug the Windows SSD during Arch installation to eliminate any risk of accidentally overwriting it. Plug it back in after Arch is fully installed.
6. **XMP/EXPO**: enable if you want your RAM running at its rated speed (separate from Arch install, just good practice)

### Windows SSD Note

Since Windows is on a completely separate SSD, it won't interfere with Arch at all. After your Arch setup is complete:

1. Plug the Windows SSD back in (if you unplugged it)
2. Enter BIOS → set Arch SSD as primary boot device
3. Windows will still be bootable — select it in BIOS boot menu when needed
4. GRUB will not automatically detect Windows unless you install `os-prober` and re-run `grub-mkconfig` — that's optional

### Disk Setup

Use `archinstall`'s built-in disk management step — it handles wiping, partitioning, and formatting for you. When prompted:

- Select your **Arch SSD** as the target (double-check the drive label so you don't touch the Windows SSD)
- Choose **wipe and partition** for a clean install
- Use **ext4** (simple and solid) or **btrfs** (if you want snapshots)
- Let archinstall handle the EFI, swap, and root partition sizes automatically

---

## Phase 0 — Bootstrap

**What it does**: updates the system, installs core tools, enables multilib, sets up fastest mirrors, installs `paru` AUR helper.

**Run after**: first login to a fresh Arch install (no desktop yet, just a terminal).

### Step 1 — Install the minimum to get the repo (run manually)

A fresh Arch install only comes with `bash` and `pacman`. You need `git` and `base-devel` before you can clone anything or run any script. Run this one line first:

```bash
pacman -Sy git base-devel --noconfirm
```

> No `sudo` yet — you are root on a fresh install. If you already created a non-root user and see a permission error, prefix with `sudo`.

### Step 2 — Clone the repo and run bootstrap

```bash
git clone https://github.com/weihen9/arch-set-up-.git ~/arch-setup
cd ~/arch-setup
bash phase0-base/bootstrap.sh
```

**Then reboot.**

> The reboot ensures your new sudo session, multilib, and mirrorlist are all active before the next phase.

---

## Phase 1 — NVIDIA Drivers

**What it does**:
- Detects your GPU via `lspci`
- Installs `linux-headers`, `nvidia-open`, `nvidia-utils`, `lib32-nvidia-utils`
- Blacklists `nouveau`
- Adds NVIDIA modules to `mkinitcpio` for early KMS loading
- Sets `nvidia-drm.modeset=1 nvidia-drm.fbdev=1` in GRUB
- Regenerates `grub.cfg` and `initramfs`
- Installs the `nvidia.hook` pacman hook (auto-regenerates initramfs on every driver or kernel update)
- Verifies with `nvidia-smi`

**Why isolated**: If NVIDIA fails, nothing downstream works. Running this alone lets you debug it without touching anything else.

```bash
bash phase1-drivers/nvidia.sh
```

**Then reboot.**

After reboot, verify before continuing:
```bash
nvidia-smi
```

You should see your GPU listed with driver version. If not, **stop here and see NVIDIA Troubleshooting** below before running Phase 2.

### Why RTX 2070 Super Uses `nvidia-open`

The RTX 2070 Super is Turing architecture (RTX 20xx). As of driver version 590+, Arch Linux uses the open kernel module (`nvidia-open`) by default for all Turing and newer GPUs. This is NVIDIA's official open-source kernel module — not Nouveau. It's stable, Wayland-compatible, and auto-updates with `pacman -Syu`.

---

## Phase 2 — Core Packages

**What it does**: installs all system packages from `pkglist.txt` — network, Bluetooth, audio, fonts, utilities, Wayland deps, AMD/NVIDIA runtime libs.

**Requires**: Phase 1 complete + `nvidia-smi` passing after reboot.

```bash
bash phase2-packages/packages.sh
```

Notable packages and why they're included:

- `amd-ucode` — AMD microcode security updates (load at boot via GRUB)
- `pipewire` + `wireplumber` — modern audio stack, replaces PulseAudio
- `xdg-desktop-portal-hyprland` — enables screensharing, file pickers in Hyprland
- `wl-clipboard` — clipboard for Wayland (`wl-copy` / `wl-paste`)
- `grim` + `slurp` — screenshot tools for Wayland
- `awww` — animated wallpaper daemon (renamed from `swww` in Oct 2025, same developer, same syntax — installed via AUR in phase3)
- `brightnessctl` — screen brightness control (useful for laptops)
- `udiskie` — auto-mounts USB drives

To add or remove packages: edit `phase2-packages/pkglist.txt` before running the script.

---

## Phase 3 — Desktop Environment

**What it does**: installs Hyprland, Waybar, Rofi (Wayland), Kitty, Yazi, Firefox, LibreWolf, Dunst.

```bash
bash phase3-desktop/desktop.sh
```

### Key decisions

**Rofi**: installs `rofi-wayland` from AUR, NOT the official `rofi` package (which is X11-only). If you have `rofi` already installed, the script removes it first. Using the wrong rofi is the main cause of theming failures on Wayland.

**Waybar**: the script kills any running `waybar` process before install to prevent the double-instance bug. A second Waybar instance appears when it's launched both by Hyprland's `exec-once` and by the install script simultaneously.

**LibreWolf**: installed as `librewolf-bin` from AUR (prebuilt binary, faster than building from source).

---

## Phase 4 — Dotfiles

**What it does**:
1. Pulls Waybar configs from [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles) as a base
2. Symlinks all configs from `phase4-dotfiles/configs/` into `~/.config/`
3. Generates sensible defaults for anything not already in your configs dir
4. Validates Waybar JSON config

```bash
bash phase4-dotfiles/dots.sh
```

### Configs deployed

| App | Source | Target |
|-----|--------|--------|
| Hyprland | `configs/hyprland/` | `~/.config/hypr/` |
| Waybar | `configs/waybar/` (+ elifouts base) | `~/.config/waybar/` |
| Rofi | `configs/rofi/` | `~/.config/rofi/` |
| Kitty | `configs/kitty/` | `~/.config/kitty/` |
| Yazi | `configs/yazi/` | `~/.config/yazi/` |

All deployed as **symlinks** — so `git pull` in this repo instantly updates your live configs.

### Customising configs

Edit files in `phase4-dotfiles/configs/` — **not** in `~/.config/` directly (those are just symlinks). Commit your changes to this repo to preserve them.

To update Waybar from elifouts upstream:
```bash
# Re-run dots.sh — it re-clones elifouts and overlays your changes
bash phase4-dotfiles/dots.sh
```

### Fixing the double Waybar issue

The double Waybar (one working + one showing errors on top of it) is caused by Waybar being launched twice: once from `hyprland.conf` (`exec-once = waybar`) and once from somewhere else (a previous autostart, a leftover process, or the script itself). Fix:

```bash
pkill waybar          # kill all instances
# wait 2 seconds
waybar &              # start exactly one
```

Then check your `~/.config/hypr/hyprland.conf` — it should have `exec-once = waybar` exactly once. The phase4 script does `pkill waybar` before deploying to prevent this.

### NVIDIA-specific Hyprland env vars

The generated Hyprland config includes these — they're required for Wayland to work properly on NVIDIA:

```ini
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
```

Do not remove these. `WLR_NO_HARDWARE_CURSORS,1` specifically prevents the invisible cursor bug that affects most NVIDIA Wayland setups.

---

## Phase 5 — Tests

### Pre-reboot (run before final reboot)

```bash
bash phase5-tests/pre-reboot.sh
```

Checks: NVIDIA modules loaded, kernel params set, pacman hook installed, all key packages present, services enabled, config files exist.

**All checks must pass before rebooting.**

### Post-reboot (run after final reboot, inside Hyprland session)

```bash
bash phase5-tests/post-reboot.sh
```

Checks: `nvidia-smi`, Wayland session active, waybar running (exactly one instance), no duplicate processes, network up, audio running, all apps in PATH.

---

## BIOS Boot Order (after full install)

1. Enter BIOS
2. Set the **Arch SSD as the primary boot device**
3. GRUB will load — boots Arch by default
4. To boot Windows: enter BIOS boot menu at startup (usually `F12`) → select Windows SSD directly
5. Optional: add Windows to GRUB menu:
```bash
sudo pacman -S os-prober
sudo os-prober                                          # should detect Windows
sudo grub-mkconfig -o /boot/grub/grub.cfg               # regenerate with Windows entry
```

---

## Keybindings (default Hyprland config)

| Keys | Action |
|------|--------|
| `SUPER + Q` | Open Kitty terminal |
| `SUPER + R` | Open Rofi app launcher |
| `SUPER + E` | Open Yazi file manager |
| `SUPER + C` | Close active window |
| `SUPER + M` | Exit Hyprland |
| `SUPER + arrows` | Move focus |
| `SUPER + SHIFT + arrows` | Move window |
| `SUPER + 1–5` | Switch workspace |
| `SUPER + SHIFT + 1–5` | Move window to workspace |
| `Print Screen` | Screenshot region (copies to clipboard) |

---

## Troubleshooting

### NVIDIA: black screen after Phase 1 reboot

Boot from your Arch live USB. Chroot back in:
```bash
# Mount your partitions (adjust /dev/sdX to your actual drive)
mount /dev/sdXn /mnt          # root partition
mount /dev/sdXn /mnt/boot     # EFI partition
arch-chroot /mnt

# Check what went wrong
cat /etc/mkinitcpio.conf      # MODULES should contain nvidia nvidia_modeset nvidia_uvm nvidia_drm
cat /etc/default/grub         # GRUB_CMDLINE_LINUX_DEFAULT should contain nvidia-drm.modeset=1

# Regenerate if needed
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg
exit
reboot
```

### NVIDIA: `nvidia-smi` fails with "couldn't communicate with NVIDIA driver"

```bash
# Check if module is loaded
lsmod | grep nvidia

# Try loading manually
sudo modprobe nvidia

# If it fails, check dmesg for the reason
dmesg | grep -i nvidia | tail -20

# Most common fix: headers mismatch — reinstall headers matching your running kernel
uname -r                      # note your kernel version
sudo pacman -S linux-headers  # or linux-lts-headers if on lts kernel
sudo mkinitcpio -P
reboot
```

### NVIDIA: using DKMS (if standard nvidia-open fails)

If you have a custom or LTS kernel, use DKMS instead:
```bash
sudo pacman -Rns nvidia-open
sudo pacman -S nvidia-open-dkms linux-headers
sudo mkinitcpio -P
```

Update `phase1-drivers/hooks/nvidia.hook` — change `Target=nvidia-open` to `Target=nvidia-open-dkms`.

### Double Waybar instance

```bash
pkill waybar
sleep 1
waybar &
```

Check `~/.config/hypr/hyprland.conf` for duplicate `exec-once = waybar` lines — keep exactly one.

### Waybar showing errors / not loading theme

```bash
# Test config manually
waybar --config ~/.config/waybar/config --log-level debug

# Common issue: JSON syntax error in config
# Use a linter
cat ~/.config/waybar/config | jq .

# Common issue: using 'rofi' instead of 'rofi-wayland'
pacman -Q rofi-wayland       # should be installed
```

### Rofi not opening or wrong theme

```bash
# Test rofi directly
rofi -show drun -log /tmp/rofi.log
cat /tmp/rofi.log

# If using X11 rofi by mistake
pacman -Q rofi               # if this exists, remove it
sudo pacman -Rns rofi
paru -S rofi-wayland

# Theme not applying
rofi -show drun -theme ~/.config/rofi/theme.rasi
```

### Cursor invisible in Hyprland

Add to `~/.config/hypr/hyprland.conf`:
```ini
env = WLR_NO_HARDWARE_CURSORS,1
```
The generated config already includes this, but if you edited it out, that's likely the cause.

### Screen tearing in apps

Add to `~/.config/hypr/hyprland.conf`:
```ini
env = __GL_GSYNC_ALLOWED,0
env = __GL_VRR_ALLOWED,0
```

### Screensharing not working (Discord, browser)

Ensure `xdg-desktop-portal-hyprland` is installed and running:
```bash
pacman -Q xdg-desktop-portal-hyprland
systemctl --user status xdg-desktop-portal-hyprland
# Start if not running:
systemctl --user start xdg-desktop-portal-hyprland
# Enable on login:
systemctl --user enable xdg-desktop-portal-hyprland
```

### No audio

```bash
systemctl --user status pipewire wireplumber

# Restart the audio stack
systemctl --user restart pipewire wireplumber pipewire-pulse

# Check devices
pactl list sinks short
```

### Bluetooth not connecting

```bash
sudo systemctl start bluetooth
bluetoothctl
# In the bluetoothctl prompt:
power on
scan on
# Wait for device to appear, then:
pair XX:XX:XX:XX:XX:XX
connect XX:XX:XX:XX:XX:XX
```

### Network not connecting after reboot

```bash
sudo systemctl status NetworkManager
sudo systemctl restart NetworkManager
nmcli device status
nmcli connection up "YourNetworkName"
```

---

## Maintenance

### Updating the system

```bash
sudo pacman -Syu              # system + official packages
paru -Syu                    # includes AUR packages (librewolf, rofi-wayland etc.)
```

The `nvidia.hook` will automatically regenerate initramfs whenever `nvidia-open` or the kernel updates. You don't need to do anything manually after updates.

### Pulling config updates

```bash
cd ~/arch-setup
git pull
bash phase4-dotfiles/dots.sh  # re-deploy (symlinks update instantly, but new files need re-running)
```

### Re-running a phase

Phase scripts are guarded against double-runs. To force re-run:
```bash
rm ~/.arch-setup-phases/phase4.done
bash phase4-dotfiles/dots.sh
```

### Adding new packages

Edit `phase2-packages/pkglist.txt`, then:
```bash
bash phase2-packages/packages.sh
```

Or install directly and add to pkglist for future installs:
```bash
sudo pacman -S some-package
echo "some-package" >> phase2-packages/pkglist.txt
git add phase2-packages/pkglist.txt
git commit -m "add some-package"
```

---

## Known Issues / Notes

- **Secure Boot**: keep it off. NVIDIA open modules are not signed by default.
- **Wayland + Electron apps** (Discord, VS Code, etc.): may need `--ozone-platform=wayland` flag or env var `ELECTRON_OZONE_PLATFORM_HINT=wayland`
- **Steam/Gaming**: install `steam` from multilib + `gamemode` + `mangohud` for performance monitoring
- **LibreWolf auto-updates**: it doesn't. Run `paru -S librewolf-bin` periodically or add it to a cron/timer
- **Laptop mode**: `brightnessctl` and `swayidle` are already installed. Configure `swayidle` in Hyprland config for auto-lock + screen off
