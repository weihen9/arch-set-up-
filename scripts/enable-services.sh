#!/usr/bin/env bash
set -euo pipefail
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
if command -v docker >/dev/null 2>&1; then
  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  echo "Docker enabled; log out/in for docker group permissions."
fi
