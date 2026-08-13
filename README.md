# Arch Linux Setup — SOP

Reusable Arch base install, standardized across devices — currently running on
an AMD CPU + NVIDIA RTX 2070 Super desktop, and an AMD-graphics laptop.
Stack: Hyprland (UWSM) · Waybar · Rofi · Kitty · Yazi · Firefox · LibreWolf ·
Dunst + swaync · pywal · awww.

> **"awww" = Hyprland** in this repo. If you meant a different compositor, swap `hyprland` in phase3 and phase4 configs.

---

## Hardware Context

This repo no longer assumes one machine's hardware. Bootloader, GPU vendor,
and CPU microcode are all **detected automatically** at install time —
see Phase 1 below. The table below is just what's currently been tested:

| Device | CPU | GPU | Bootloader |
|--------|-----|-----|------------|
| Desktop | AMD | NVIDIA RTX 2070 Super (Turing, `nvidia-open`) | systemd-boot |
| Laptop | (auto-detected) | AMD (in-kernel `amdgpu`) | (auto-detected) |

---

## Repo Structure

```
arch-setup/
├── README.md                        ← you are here (full SOP)
├── scripts/helpers.sh               ← shared functions: logging, phase guards,
│                                        bootloader detection, microcode detection
├── phase0-base/bootstrap.sh
├── phase1-drivers/
│   ├── detect.sh                    ← RUN THIS — detects GPU vendor, dispatches
│   ├── common.sh                    ← shared: microcode, mkinitcpio, kernel params
│   ├── nvidia.sh
│   ├── amd.sh
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
│       ├── yazi/
│       ├── swaync/
│       ├── pywal-templates/         ← e.g. rofi-pywal-theme.rasi
│       └── hypr-scripts/            ← wallpaper.sh, refreshrate.sh
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
6.  bash phase1-drivers/detect.sh     ← auto-detects GPU, runs nvidia.sh or amd.sh
7.  REBOOT → verify (NVIDIA: nvidia-smi | AMD: lspci -k | grep -A3 VGA)
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
4. Adding Windows to your Arch boot menu is optional. systemd-boot doesn't chain-load other OSes automatically — just use your BIOS boot menu (usually `F12`) to pick Windows, or add a manual entry at `/boot/loader/entries/windows.conf` pointing at the Windows Boot Manager EFI file.

### Disk Setup

Use `archinstall`'s built-in disk management step — it handles wiping, partitioning, and formatting for you. When prompted:

- Select your **Arch SSD** as the target (double-check the drive label so you don't touch the Windows SSD)
- Choose **wipe and partition** for a clean install
- Use **ext4** (simple and solid) or **btrfs** (if you want snapshots)
- Let archinstall handle the EFI, swap, and root partition sizes automatically

---

## Phase 0 — Bootstrap

**What it does**: updates the system, installs core tools, enables multilib, sets up fastest mirrors, installs `yay` AUR helper.

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

> **After every reboot**, your terminal starts in home. Always run `cd ~/arch-setup` before any phase script.

**Then reboot.**

> The reboot ensures your new sudo session, multilib, and mirrorlist are all active before the next phase.

---

## Phase 1 — GPU Drivers

**What it does**: `detect.sh` runs `lspci`, figures out whether the GPU is
NVIDIA or AMD, and hands off to the matching script. You never run
`nvidia.sh` or `amd.sh` directly — always go through `detect.sh` so the
right one runs on the right hardware.

```bash
cd ~/arch-setup
bash phase1-drivers/detect.sh
```

**Bootloader: systemd-boot only.** `scripts/helpers.sh` checks that
systemd-boot is actually installed (via `bootctl`/`/boot/loader/entries/`)
before writing kernel params — it doesn't try to install a bootloader for
you. If systemd-boot isn't detected, it stops and tells you to run
`sudo bootctl install` rather than guessing or falling back to GRUB.

**CPU microcode is auto-detected** — `amd-ucode` or `intel-ucode`,
based on `/proc/cpuinfo`, not hardcoded to one CPU vendor. This also wires
the ucode image into your boot entry's `initrd` lines — systemd-boot
doesn't do this automatically the way GRUB's `grub-mkconfig` does.

### NVIDIA path (`nvidia.sh`)
- Installs `linux-headers`, `nvidia-open`, `nvidia-utils`, `lib32-nvidia-utils`
- Blacklists `nouveau`
- Adds NVIDIA modules to `mkinitcpio` for early KMS loading
- Sets `nvidia-drm.modeset=1 nvidia-drm.fbdev=1` in the systemd-boot entry
- Installs the `nvidia.hook` pacman hook (auto-regenerates initramfs on every driver or kernel update)
- Verifies with `nvidia-smi`

Turing and newer NVIDIA GPUs use `nvidia-open` — NVIDIA's official open-source
kernel module, not Nouveau. Stable, Wayland-compatible, auto-updates with `pacman -Syu`.

### AMD path (`amd.sh`)
- AMD GPUs use the in-kernel `amdgpu` driver — **no DKMS, no blacklisting needed**
- Installs the userspace stack: `mesa`, `lib32-mesa`, `vulkan-radeon`,
  `lib32-vulkan-radeon`, `libva-mesa-driver`, `mesa-vdpau` (+ 32-bit variants)
- Verifies `amdgpu` is the active kernel driver via `lspci -k`

**Why isolated**: If the GPU driver phase fails, nothing downstream works.
Running it alone lets you debug it without touching anything else.

**Then reboot.**

After reboot, verify before continuing:
```bash
nvidia-smi                        # NVIDIA
lspci -k | grep -A3 -Ei 'vga|3d'  # AMD — should show "amdgpu" as Kernel driver in use
```

If not, **stop here and see Troubleshooting** below before running Phase 2.

---

## Phase 2 — Core Packages

**What it does**: installs all system packages from `pkglist.txt` — network, Bluetooth, audio, fonts, utilities, Wayland deps, GPU-agnostic baseline libs. CPU microcode and GPU-vendor packages are handled in Phase 1, not here — this list is deliberately hardware-agnostic so it runs unmodified on any device.

**Requires**: Phase 1 complete and verified (`nvidia-smi` for NVIDIA, or `lspci -k` showing `amdgpu` for AMD).

```bash
cd ~/arch-setup
bash phase2-packages/packages.sh
```

Notable packages and why they're included:

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

**What it does**: installs Hyprland, Waybar, Rofi (Wayland), Kitty, Yazi, Firefox, LibreWolf, Dunst + swaync, pywal.

```bash
cd ~/arch-setup
bash phase3-desktop/desktop.sh
```

### Key decisions

**Rofi**: installs `rofi-wayland` from AUR, NOT the official `rofi` package (which is X11-only). If you have `rofi` already installed, the script removes it first. Using the wrong rofi is the main cause of theming failures on Wayland.

**`unarchiver`**: Yazi needs this for archive support. The command it provides is called `unar` but the package name is `unarchiver` — these are different things. The script installs the correct package name.

**No Thunar**: Yazi is the only file manager in this setup. A GUI file manager alongside it is redundant, so it's intentionally left out — see Phase 2's `pkglist.txt`.

**No hyprpaper**: `awww` (installed in this phase) is the wallpaper daemon. hyprpaper would just be a second, unused wallpaper daemon, so it's not installed.

**No swaylock**: `hyprlock` (also installed in this phase) is the lock screen. swaylock isn't installed to avoid having two lock screens.

**Waybar**: the script kills any running `waybar` process before install to prevent the double-instance bug. A second Waybar instance appears when it's launched both by Hyprland's `exec-once` and by the install script simultaneously.

**LibreWolf**: installed as `librewolf-bin` from AUR (prebuilt binary, faster than building from source).

**Dunst + swaync — both, intentionally**: swaync provides the notification-center UI that the Waybar notification button opens, and its theming ties into the pywal reload in `wallpaper.sh`. Dunst is the lightweight background notification daemon. If you decide down the line you only want one, this is the pair to revisit — right now they're both kept because swaync isn't a drop-in replacement for Dunst's popup behavior.

---

## Phase 4 — Dotfiles

**What it does**:
1. Pulls Waybar configs from [elifouts/Dotfiles](https://github.com/elifouts/Dotfiles) as a base
2. Symlinks all configs from `phase4-dotfiles/configs/` into `~/.config/`
3. Deploys pywal templates to `~/.config/wal/templates/` (custom rofi theme)
4. Deploys `wallpaper.sh` / `refreshrate.sh` to `~/.config/hypr/scripts/`
5. Generates sensible defaults for anything not already in your configs dir
6. Validates Waybar JSON config

```bash
cd ~/arch-setup
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
| swaync | `configs/swaync/` | `~/.config/swaync/` |
| pywal templates | `configs/pywal-templates/` | `~/.config/wal/templates/` |
| Hypr scripts | `configs/hypr-scripts/` | `~/.config/hypr/scripts/` |

All deployed as **symlinks** — so `git pull` in this repo instantly updates your live configs.

> **Note on this pass**: the scripts are now correct and hardware-agnostic, but `configs/hypr-scripts/`, `configs/swaync/`, and the real (not fallback) `configs/hyprland/` and `configs/waybar/` still need your actual live dotfiles copied in from the desktop — I don't have filesystem access to that machine, so I can't pull them for you. Until then, `dots.sh` will fall back to generating minimal defaults, and will explicitly warn about `wallpaper.sh`/`refreshrate.sh` being missing.

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

### GPU-specific Hyprland env vars

`dots.sh` checks `lspci` at generation time and only writes the env vars for
the GPU actually present — no more NVIDIA vars hardcoded onto every machine:

**NVIDIA:**
```ini
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
```
`WLR_NO_HARDWARE_CURSORS,1` specifically prevents the invisible cursor bug that affects most NVIDIA Wayland setups. Do not remove it on NVIDIA machines.

**AMD:**
```ini
env = LIBVA_DRIVER_NAME,radeonsi
```
AMD's Wayland/DRM support doesn't need the NVIDIA-specific workarounds — `radeonsi` is just for hardware video decode.

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
3. systemd-boot loads — boots Arch by default
4. To boot Windows: enter BIOS boot menu at startup (usually `F12`) → select Windows SSD directly
5. Optional: add Windows to your Arch boot menu — systemd-boot has no automatic detection, so add a manual entry to `/boot/loader/entries/windows.conf` pointing at the Windows Boot Manager EFI file, or just use the BIOS boot menu each time.

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

### "No such file or directory" when running a phase script

You're not in the repo directory. After every reboot your terminal starts at home. Fix:
```bash
cd ~/arch-setup
bash phaseX-.../script.sh
```

### Phase 1: "systemd-boot not detected"

This means `archinstall` didn't set up systemd-boot, or your EFI partition
isn't mounted at `/boot`. The scripts deliberately don't install a bootloader
for you (that behavior is what caused a dual-boot recovery incident
previously) — install it manually, then re-run:

```bash
sudo bootctl install
# Then re-run phase 1
rm ~/.arch-setup-phases/phase1.done
cd ~/arch-setup && bash phase1-drivers/detect.sh
```

If `bootctl install` fails, your EFI partition probably isn't mounted. Check with `lsblk` and mount it:
```bash
lsblk                              # find your EFI partition (usually ~512MB, type vfat)
sudo mount /dev/sdXn /boot         # replace sdXn with your actual EFI partition
```

### Phase 3: "pacman failed to install" on Yazi optional deps

The package name is `unarchiver` (not `unar` — that's just the command it provides). Install manually and re-run:
```bash
sudo pacman -S --needed ffmpegthumbnailer jq poppler fd ripgrep fzf zoxide imagemagick unarchiver --noconfirm
rm ~/.arch-setup-phases/phase3.done
cd ~/arch-setup && bash phase3-desktop/desktop.sh
```

### A phase script failed partway — can I re-run it?

Yes. Remove the phase completion flag and re-run. The `--needed` flag means already-installed packages are skipped:
```bash
rm ~/.arch-setup-phases/phaseN.done   # replace N with the phase number
cd ~/arch-setup
bash phaseN-.../script.sh
```

### NVIDIA: black screen after Phase 1 reboot

Boot from your Arch live USB. Chroot back in:
```bash
# Mount your partitions (adjust /dev/sdX to your actual drive)
mount /dev/sdXn /mnt          # root partition
mount /dev/sdXn /mnt/boot     # EFI partition
arch-chroot /mnt

# Check what went wrong
cat /etc/mkinitcpio.conf      # MODULES should contain nvidia nvidia_modeset nvidia_uvm nvidia_drm

# Check kernel params landed in the boot entry:
cat /boot/loader/entries/*.conf | grep options   # options line should contain nvidia-drm.modeset=1

# Regenerate if needed
mkinitcpio -P
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
yay -S rofi-wayland

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
yay -Syu                     # includes AUR packages (librewolf, rofi-wayland etc.)
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
cd ~/arch-setup
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
- **LibreWolf auto-updates**: it doesn't. Run `yay -S librewolf-bin` periodically or add it to a cron/timer
- **Laptop mode**: `brightnessctl` and `swayidle` are already installed. Configure `swayidle` in Hyprland config for auto-lock + screen off
