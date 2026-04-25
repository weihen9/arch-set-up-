# Elifouts Waybar integration

Confirmed source repo:

```text
https://github.com/elifouts/Dotfiles
```

Relevant folder:

```text
.config/waybar
```

The repo's Waybar setup includes:

- `config`
- `style.css`
- `assets/`
- `scripts/`
- `themes/default`
- `themes/experimental`
- `themes/line`
- `themes/zen`

This local repo includes an adapted fallback config, but the full upstream assets/images are synced on the target machine with:

```bash
./scripts/sync-elifouts-waybar.sh
```

Reason: the remote repo contains binary image assets; the most reliable GitHub-ready approach is to clone the source repo during setup, copy the full Waybar folder into `~/.config/waybar`, and then let this repo's Hyprland/awww/rofi scripts control wallpaper and theme switching.

Dependencies covered by this setup:

- `waybar`
- `hyprpicker`
- `python-pywal`
- `blueman`
- `bluez`
- `networkmanager`
- `swaync`
- `otf-codenewroman-nerd`
- `materia-gtk-theme`
- `qogir-icon-theme` from AUR

Wallpaper remains handled by `awww`, not `swww`.
