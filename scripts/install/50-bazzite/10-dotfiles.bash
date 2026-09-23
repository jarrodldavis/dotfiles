#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Bazzite dotfiles...'

symlink gitconfigs/bazzite.gitconfig

symlink ssh/bazzite.sshconfig ~/.ssh/config.d/bazzite

symlink brew/bazzite.Brewfile ~/.Brewfile

symlink vscode/settings.json ~/.config/Code/User/settings.json
symlink vscode/keybindings.json ~/.config/Code/User/keybindings.json

symlink systemd/steam-download-inhibit.py ~/.local/bin/steam-download-inhibit
symlink systemd/steam-download-inhibit.service ~/.config/systemd/user/steam-download-inhibit.service
symlink systemd/steam-update-wake.service ~/.config/systemd/user/steam-update-wake.service

symlink vorta/update-system-inventory.bash ~/.local/bin/update-system-inventory

symlink kde/homebrew-env.sh ~/.config/plasma-workspace/env/homebrew.sh
symlink kde/ssh-auth-env.sh ~/.config/plasma-workspace/env/ssh-auth.sh

symlink nvidia/70-nvidia.conf ~/.config/environment.d/70-nvidia.conf
