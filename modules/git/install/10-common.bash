#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

module_dir="$HOME/.dotfiles/modules/git"

log_substep 'Linking Git configuration...'
symlink ../../scripts/maintenance/pre-commit.bash ~/.dotfiles/.git/hooks/pre-commit

# Isolate managed Git configuration from machine-specific settings.
symlink "$module_dir/base.gitconfig" "${XDG_CONFIG_HOME:-$HOME/.config}/git/config"
touch ~/.gitconfig

symlink "$module_dir/ssh.gitconfig" ~/.gitconfigs/ssh.gitconfig
symlink "$module_dir/gitignore" ~/.gitignore
