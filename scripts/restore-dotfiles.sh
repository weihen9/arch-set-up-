#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$HOME/.config" "$HOME/wallpaper" "$HOME/.cache/wal"

for d in hypr waybar rofi kitty alacritty wal yazi; do
    if [[ -d "$ROOT_DIR/dotfiles/$d" ]]; then
        mkdir -p "$HOME/.config/$d"
        cp -a "$ROOT_DIR/dotfiles/$d/." "$HOME/.config/$d/"
    fi
done

if [[ -d "$ROOT_DIR/dotfiles/dunst" ]]; then
    mkdir -p "$HOME/.config/dunst"
    cp -a "$ROOT_DIR/dotfiles/dunst/." "$HOME/.config/dunst/"
fi

# Generate default pywal colors if none exist
if [[ ! -f "$HOME/.cache/wal/colors-waybar.css" ]]; then
    mkdir -p "$HOME/.cache/wal"
    cat > "$HOME/.cache/wal/colors-waybar.css" << 'EOF'
/* Default pywal colors - run 'wal -i ~/wallpaper/image.jpg' to generate real ones */
@define-color foreground #ffffff;
@define-color background #1a1a1a;
@define-color color0 #1a1a1a;
@define-color color1 #ff5555;
@define-color color2 #50fa7b;
@define-color color3 #f1fa8c;
@define-color color4 #bd93f9;
@define-color color5 #ff79c6;
@define-color color6 #8be9fd;
@define-color color7 #ffffff;
EOF
fi

# Also create default rofi colors if missing
if [[ ! -f "$HOME/.cache/wal/colors-rofi-dark.rasi" ]]; then
    cat > "$HOME/.cache/wal/colors-rofi-dark.rasi" << 'EOF'
* {
    foreground: #ffffff;
    background: #1a1a1a;
    background-alt: #2a2a2a;
    selected: #bd93f9;
    active: #50fa7b;
    urgent: #ff5555;
}
EOF
fi

[[ -f "$HOME/.config/waybar/themes/pywal.css" ]] && cp "$HOME/.config/waybar/themes/pywal.css" "$HOME/.config/waybar/style.css"
[[ -f "$HOME/.config/rofi/themes/pywal.rasi" ]] && cp "$HOME/.config/rofi/themes/pywal.rasi" "$HOME/.config/rofi/theme.rasi"

chmod +x "$HOME/.config/hypr/scripts/"*.sh
[[ -d "$HOME/.config/waybar/scripts" ]] && chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true

echo "Dotfiles restored."
echo "Add wallpapers to ~/wallpaper, then press SUPER+W."
echo "File manager: SUPER+E -> kitty -e yazi."
