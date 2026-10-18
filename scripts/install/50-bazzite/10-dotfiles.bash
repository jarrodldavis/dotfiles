#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Bazzite dotfiles...'

symlink gitconfigs/bazzite.gitconfig

symlink ssh/bazzite.sshconfig ~/.ssh/config.d/bazzite

symlink brew/bazzite.Brewfile ~/.Brewfile
symlink brew/bazzite.Brewfile ~/.homebrew/Brewfile

symlink vscode/settings.json ~/.config/Code/User/settings.json
symlink vscode/keybindings.json ~/.config/Code/User/keybindings.json

symlink systemd/steam-power-profile-watch.py ~/.local/bin/steam-power-profile-watch
symlink systemd/steam-power-profile-watch.service ~/.config/systemd/user/steam-power-profile-watch.service
symlink systemd/tang.container ~/.config/containers/systemd/tang.container

ensure_dir ~/.local/share/tang

symlink borg/backup-server.bash ~/.local/bin/borg-backup-server

symlink kde/homebrew-env.sh ~/.config/plasma-workspace/env/homebrew.sh
symlink kde/ssh-auth-env.sh ~/.config/plasma-workspace/env/ssh-auth.sh

symlink nvidia/70-nvidia.conf ~/.config/environment.d/70-nvidia.conf
