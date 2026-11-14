#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

module_dir="$HOME/.dotfiles/modules/vscode"
symlink "$module_dir/settings.json" ~/.config/Code/User/settings.json
symlink "$module_dir/keybindings.json" ~/.config/Code/User/keybindings.json
