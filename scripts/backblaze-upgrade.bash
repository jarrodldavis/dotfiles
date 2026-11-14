#!/usr/bin/env bash

# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_step "Fetching installer disk image..."
brew fetch --cask backblaze --force
dmg="$(brew --cache --cask backblaze)"

log_step "Mounting installer disk image..."
mountdir="$(mktemp -d)"
hdiutil attach -verbose -nobrowse -readonly -noidme -mountpoint "$mountdir" "$dmg"

log_step "Performing upgrade..."
check_sudo
sudo "$mountdir/Backblaze Installer.app/Contents/MacOS/bzinstall_mate" --silentUpgrade

log_step "Cleaning up..."
hdiutil detach -verbose "$mountdir"
rm -rf "$mountdir"

log_done "Backblaze upgrade complete!"
