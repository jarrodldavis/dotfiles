#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/helpers.bash
source ~/.dotfiles/scripts/helpers.bash

log_substep 'Linking Dev Container Homebrew configuration...'

symlink devcontainer.Brewfile ~/.Brewfile
symlink devcontainer.Brewfile ~/.homebrew/Brewfile
