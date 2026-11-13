#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Dev Container Homebrew configuration...'

module_dir="$HOME/.dotfiles/modules/homebrew"
symlink "$module_dir/devcontainer.Brewfile" ~/.Brewfile
symlink "$module_dir/devcontainer.Brewfile" ~/.homebrew/Brewfile
