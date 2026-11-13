#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking CoreOS Homebrew configuration...'

module_dir="$HOME/.dotfiles/modules/homebrew"
symlink "$module_dir/coreos.Brewfile" ~/.Brewfile
symlink "$module_dir/coreos.Brewfile" ~/.homebrew/Brewfile

# workaround for Homebrew's poor support for symlinked `/home` directories
mkdir -pv "$(brew --prefix)/lib/docker/cli-plugins"
