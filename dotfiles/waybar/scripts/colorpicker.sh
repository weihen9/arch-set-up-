#!/usr/bin/env bash
set -euo pipefail
json=false
[[ "${1:-}" == "-j" ]] && json=true

if ! command -v hyprpicker >/dev/null 2>&1; then
  if $json; then
    printf '{"text":"󰈊","tooltip":"hyprpicker not installed"}\n'
  else
    notify-send "Color picker" "hyprpicker is not installed"
  fi
  exit 0
fi

if $json; then
  printf '{"text":"󰈊","tooltip":"Click to pick a color"}\n'
  exit 0
fi

hex="$(hyprpicker -a || true)"
[[ -n "$hex" ]] && notify-send "Color copied" "$hex"
