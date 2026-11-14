#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink settings.json ~/Library/Application\ Support/Code/User/settings.json
symlink keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
