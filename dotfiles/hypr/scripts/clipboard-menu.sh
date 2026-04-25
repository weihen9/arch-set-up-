#!/usr/bin/env bash
cliphist list | rofi -dmenu -i -p 'Clipboard' -theme ~/.config/rofi/theme.rasi | cliphist decode | wl-copy
