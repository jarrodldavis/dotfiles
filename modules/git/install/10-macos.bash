#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink "$HOME/.dotfiles/modules/git/macos.gitconfig" ~/.gitconfigs/macos.gitconfig
