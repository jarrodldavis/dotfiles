#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink settings.json ~/.config/Code/User/settings.json
symlink keybindings.json ~/.config/Code/User/keybindings.json
