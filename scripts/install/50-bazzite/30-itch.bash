#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

url="https://broth.itch.zone/install-itch/linux-appimage-amd64/LATEST/unpacked"

log_substep 'Downloading itch-setup...'
download_path="$(mktemp)"
curl -fLo "$download_path" "$url"

log_substep 'Installing itch...'
chmod +x "$download_path"
"$download_path" --silent
