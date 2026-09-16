#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking macOS dotfiles...'

symlink gitconfigs/macos.gitconfig

symlink ssh/macos.sshconfig ~/.ssh/config.d/macos

symlink brew/macos.Brewfile ~/.Brewfile

symlink vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
symlink vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

symlink mouseless/config.yaml ~/Library/Application\ Support/Mouseless/configs/config.yaml
