#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step "Upgrading Backblaze..."

log_substep "Fetching installer disk image..."
brew fetch --cask backblaze --force
dmg="$(brew --cache --cask backblaze)"

log_substep "Mounting installer disk image..."
mountdir="$(mktemp -d)"
hdiutil attach -verbose -nobrowse -readonly -noidme -mountpoint "$mountdir" "$dmg"

log_substep "Performing upgrade..."
sudo "$mountdir/Backblaze Installer.app/Contents/MacOS/bzinstall_mate" --silentUpgrade

log_substep "Cleaning up..."
hdiutil detach -verbose "$mountdir"
rm -rf "$mountdir"

log_done "Backblaze upgrade complete!"
