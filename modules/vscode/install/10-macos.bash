#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

module_dir="$HOME/.dotfiles/modules/vscode"
symlink "$module_dir/settings.json" ~/Library/Application\ Support/Code/User/settings.json
symlink "$module_dir/keybindings.json" ~/Library/Application\ Support/Code/User/keybindings.json
