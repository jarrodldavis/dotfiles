#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

symlink macos.Brewfile ~/.Brewfile
symlink macos.Brewfile ~/.homebrew/Brewfile
