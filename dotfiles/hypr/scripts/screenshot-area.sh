#!/usr/bin/env bash
DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
grim -g "$(slurp)" "$FILE"
swappy -f "$FILE"
notify-send "Screenshot" "$FILE"
