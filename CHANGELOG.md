# Changelog

## v4

- Added integrated USB workflow documentation.
- Added live Arch ISO helper scripts:
  - `scripts/live/00-preflight.sh`
  - `scripts/live/01-run-archinstall-guided.sh`
  - `scripts/live/02-copy-repo-to-new-arch.sh`
- Added `scripts/one-shot-postinstall.sh` for first-boot setup.
- Added `usb/README-USB-WORKFLOW.md`.
- Added `docs/full-install-flow.md`.
- Added `archinstall/ARCHINSTALL-CHECKLIST.md`.
- Added `AUTO_YES=1` support to `install.sh` for non-interactive pacman installs.
- Kept the setup non-destructive for Windows dual boot; partitioning remains manual through `archinstall`.

## v3

- Switched file manager from Thunar to Yazi.
- Added Yazi config and preview/helper packages.
- Added Elifouts Waybar sync scripts.
- Added SwayNC notification backend.
- Added CodeNewRoman Nerd Font support and theme/icon support.

## v2

- Removed ML/AI package group.
- Added GRUB dual-boot tools and documentation.

## v1

- Initial Arch + Hyprland package manifests, scripts, and dotfiles.

## v5 - Latest keybind and README update

- Updated README with repo URL and Arch ISO download instructions.
- Removed random wallpaper keybind from documented workflow.
- Changed terminal keybind to `SUPER + Q`.
- Changed close active window keybind to `SUPER + C`.
- Kept `SUPER + W` for wallpaper menu and `SUPER + SHIFT + W` for theme menu.
- Updated `dotfiles/hypr/hyprland.conf` to match the documented keybinds.
