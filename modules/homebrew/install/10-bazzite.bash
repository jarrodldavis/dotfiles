#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink bazzite.Brewfile ~/.Brewfile
symlink bazzite.Brewfile ~/.homebrew/Brewfile
