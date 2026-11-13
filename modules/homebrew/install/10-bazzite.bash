#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

module_dir="$HOME/.dotfiles/modules/homebrew"
symlink "$module_dir/bazzite.Brewfile" ~/.Brewfile
symlink "$module_dir/bazzite.Brewfile" ~/.homebrew/Brewfile
