#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink "$HOME/.dotfiles/modules/homebrew/brew.env" ~/.homebrew/brew.env
